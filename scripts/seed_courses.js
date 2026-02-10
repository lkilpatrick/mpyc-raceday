// Seed courses, marks, and mark_distances into Firestore from courses_seed.json
// Usage: node scripts/seed_courses.js

const path = require("path");
const os = require("os");
const fs = require("fs");

const admin = require(path.join(__dirname, "..", "functions", "node_modules", "firebase-admin"));

const PROJECT_ID = "mpyc-raceday";
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

// Load Firebase CLI refresh token
const winPath = path.join(process.env.APPDATA || "", "configstore", "firebase-tools.json");
const nixPath = path.join(os.homedir(), ".config", "configstore", "firebase-tools.json");
const configPath = fs.existsSync(winPath) ? winPath : nixPath;

if (!fs.existsSync(configPath)) {
  console.error("Firebase CLI credentials not found. Run: firebase login");
  process.exit(1);
}

const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
const refreshToken = config.tokens?.refresh_token;
if (!refreshToken) {
  console.error("No refresh token found. Run: firebase login");
  process.exit(1);
}

const credential = admin.credential.refreshToken({
  type: "authorized_user",
  client_id: "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com",
  client_secret: "j9iVZfS8kkCEFUPaAeJV0sAi",
  refresh_token: refreshToken,
});

// Mark name mapping (code → display name)
const MARK_NAME_MAP = {
  X: "X", C: "C", P: "P", M: "M", LV: "LV",
  A: "A", B: "B",
  "1": "1", "3": "3", "4": "4",
  W: "W", R: "R", L: "L",
};

// Wind group definitions (used to look up wind ranges)
const WIND_GROUPS = {
  S_SW: { windRange: [200, 260] },
  W: { windRange: [260, 295] },
  NW: { windRange: [295, 320] },
  N: { windRange: [320, 20] },
  INFLATABLE: { windRange: [0, 360] },
  LONG: { windRange: [295, 320] },
};

function parseSequence(sequence) {
  const marks = [];
  let order = 1;
  for (const entry of sequence) {
    if (entry === "START") {
      marks.push({ markId: "1", markName: "1", order: order++, rounding: "port", isStart: true, isFinish: false });
      continue;
    }
    if (entry === "FINISH") {
      marks.push({ markId: "1", markName: "1", order: order++, rounding: "port", isStart: false, isFinish: true });
      continue;
    }
    if (entry === "FINISH_X") {
      marks.push({ markId: "X", markName: "X", order: order++, rounding: "starboard", isStart: false, isFinish: true });
      continue;
    }
    const match = entry.match(/^(.+?)(p|s)$/);
    if (!match) continue;
    const code = match[1];
    const rounding = match[2] === "s" ? "starboard" : "port";
    marks.push({
      markId: code,
      markName: MARK_NAME_MAP[code] || code,
      order: order++,
      rounding,
      isStart: false,
      isFinish: false,
    });
  }
  return marks;
}

// Convert JS value to Firestore REST API value format
function toFsValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === "string") return { stringValue: val };
  if (typeof val === "boolean") return { booleanValue: val };
  if (typeof val === "number") {
    return Number.isInteger(val) ? { integerValue: String(val) } : { doubleValue: val };
  }
  if (Array.isArray(val)) {
    return { arrayValue: { values: val.map(toFsValue) } };
  }
  if (typeof val === "object") {
    const fields = {};
    for (const [k, v] of Object.entries(val)) {
      fields[k] = toFsValue(v);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

async function writeDoc(accessToken, collection, docId, data) {
  const url = `${BASE_URL}/${collection}/${docId}`;
  const fields = {};
  for (const [k, v] of Object.entries(data)) {
    fields[k] = toFsValue(v);
  }
  const resp = await fetch(url, {
    method: "PATCH",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ fields }),
  });
  if (!resp.ok) {
    const errBody = await resp.text();
    throw new Error(`Firestore write ${collection}/${docId} failed (${resp.status}): ${errBody}`);
  }
}

async function listDocs(accessToken, collection) {
  const url = `${BASE_URL}/${collection}?pageSize=500`;
  const resp = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!resp.ok) return [];
  const body = await resp.json();
  return (body.documents || []).map((doc) => {
    const parts = doc.name.split("/");
    return parts[parts.length - 1];
  });
}

async function deleteDoc(accessToken, collection, docId) {
  const url = `${BASE_URL}/${collection}/${docId}`;
  const resp = await fetch(url, {
    method: "DELETE",
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!resp.ok) {
    const errBody = await resp.text();
    console.warn(`  ⚠ Failed to delete ${collection}/${docId}: ${errBody}`);
  }
}

async function seed() {
  const accessToken = (await credential.getAccessToken()).access_token;
  const seedPath = path.join(__dirname, "..", "assets", "courses_seed.json");
  const data = JSON.parse(fs.readFileSync(seedPath, "utf8"));

  // Delete old collections
  for (const col of ["marks", "mark_distances", "courses", "wind_groups", "fleets"]) {
    const oldDocs = await listDocs(accessToken, col);
    if (oldDocs.length > 0) {
      console.log(`Deleting ${oldDocs.length} old ${col}...`);
      for (const id of oldDocs) {
        await deleteDoc(accessToken, col, id);
      }
    }
  }

  // Seed marks
  console.log(`Seeding ${data.marks.length} marks...`);
  for (const m of data.marks) {
    await writeDoc(accessToken, "marks", m.id, {
      name: m.name,
      code: m.code || m.id,
      type: m.type,
      latitude: m.latitude || null,
      longitude: m.longitude || null,
      description: m.description || null,
    });
  }
  console.log("  Marks done.");

  // Seed mark distances from distanceMatrix
  let distCount = 0;
  if (data.distanceMatrix) {
    console.log("Seeding mark distances from matrix...");
    for (const [from, targets] of Object.entries(data.distanceMatrix)) {
      for (const [to, vals] of Object.entries(targets)) {
        await writeDoc(accessToken, "mark_distances", `${from}_${to}`, {
          fromMarkId: from,
          toMarkId: to,
          distanceNm: vals.dist,
          headingMagnetic: vals.bearing,
        });
        distCount++;
      }
    }
    console.log(`  ${distCount} mark distances done.`);
  }

  // Seed wind groups
  if (data.windGroups) {
    console.log(`Seeding ${data.windGroups.length} wind groups...`);
    for (const wg of data.windGroups) {
      await writeDoc(accessToken, "wind_groups", wg.id, {
        label: wg.label,
        windRange: wg.windRange,
        color: wg.color,
        bgColor: wg.bgColor,
      });
    }
    console.log("  Wind groups done.");
  }

  // Seed fleets
  if (data.fleets) {
    console.log(`Seeding ${data.fleets.length} fleets...`);
    for (const f of data.fleets) {
      await writeDoc(accessToken, "fleets", f.id, {
        name: f.name,
        type: f.type,
        description: f.description || "",
      });
    }
    console.log("  Fleets done.");
  }

  // Seed courses
  console.log(`Seeding ${data.courses.length} courses...`);
  for (const c of data.courses) {
    const courseNum = String(c.number);
    const marks = parseSequence(c.sequence);
    const courseName = `Course ${courseNum}`;
    const wg = WIND_GROUPS[c.windGroup] || { windRange: [0, 360] };
    const requiresInflatable = c.sequence.some((s) =>
      s.startsWith("LV") || s.startsWith("W") || s.startsWith("R") || s.startsWith("L")
    );

    await writeDoc(accessToken, "courses", `course_${courseNum}`, {
      courseNumber: courseNum,
      courseName,
      marks,
      distanceNm: c.distanceNm,
      windDirectionBand: c.windGroup,
      windDirMin: wg.windRange[0],
      windDirMax: wg.windRange[1],
      finishLocation: c.finishAt || "committee_boat",
      canMultiply: c.canMultiply || false,
      requiresInflatable,
      isActive: true,
      notes: c.notes || "",
    });
  }
  console.log("  Courses done.");

  console.log("\n=== Course Data Seeded ===");
  console.log(`  ${data.marks.length} marks`);
  console.log(`  ${distCount} mark distances`);
  console.log(`  ${data.courses.length} courses`);
  console.log(`  ${(data.windGroups || []).length} wind groups`);
  console.log(`  ${(data.fleets || []).length} fleets`);
  console.log("==========================\n");
  process.exit(0);
}

seed().catch((err) => {
  console.error("Failed:", err.message);
  process.exit(1);
});
