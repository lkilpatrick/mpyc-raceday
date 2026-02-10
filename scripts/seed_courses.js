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

// Mark abbreviation mapping (same as courses_repository_impl.dart)
const MARK_ABBREV_MAP = {
  X: "X", C: "C", P: "P", M: "MY2", LV: "LV",
  A: "A", B: "B",
  "1": "MY1", "3": "MY3", "4": "MY4",
  W: "W", R: "R", L: "L",
};

const MARK_NAME_MAP = {
  X: "X", C: "C", P: "P", M: "M", LV: "LV",
  A: "A", B: "B",
  "1": "1", "3": "3", "4": "4",
  W: "W", R: "R", L: "L",
};

function parseMarks(seq) {
  const parts = seq.split("-");
  const marks = [];
  let order = 1;
  for (const part of parts) {
    const p = part.trim();
    if (p === "Finish") {
      if (marks.length > 0) {
        marks[marks.length - 1].isFinish = true;
      }
      continue;
    }
    const rChar = p[p.length - 1];
    const rounding = rChar === "s" ? "starboard" : "port";
    const abbrev = p.substring(0, p.length - 1);
    marks.push({
      markId: MARK_ABBREV_MAP[abbrev] || abbrev,
      markName: MARK_NAME_MAP[abbrev] || abbrev,
      order: order++,
      rounding,
      isFinish: false,
    });
  }
  if (marks.length > 0 && !marks.some((m) => m.isFinish)) {
    marks[marks.length - 1].isFinish = true;
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

  // Delete old marks
  const oldMarks = await listDocs(accessToken, "marks");
  if (oldMarks.length > 0) {
    console.log(`Deleting ${oldMarks.length} old marks...`);
    for (const id of oldMarks) {
      await deleteDoc(accessToken, "marks", id);
    }
    console.log("  Old marks deleted.");
  }

  // Delete old mark distances
  const oldDists = await listDocs(accessToken, "mark_distances");
  if (oldDists.length > 0) {
    console.log(`Deleting ${oldDists.length} old mark distances...`);
    for (const id of oldDists) {
      await deleteDoc(accessToken, "mark_distances", id);
    }
    console.log("  Old mark distances deleted.");
  }

  // Seed marks
  console.log(`Seeding ${data.marks.length} marks...`);
  for (const m of data.marks) {
    await writeDoc(accessToken, "marks", m.id, {
      name: m.name,
      type: m.type,
      latitude: m.latitude || null,
      longitude: m.longitude || null,
      description: m.description || null,
    });
  }
  console.log("  Marks done.");

  // Seed mark distances
  console.log(`Seeding ${data.mark_distances.length} mark distances...`);
  for (const d of data.mark_distances) {
    await writeDoc(accessToken, "mark_distances", `${d.from}_${d.to}`, {
      fromMarkId: d.from,
      toMarkId: d.to,
      distanceNm: d.distance,
      headingMagnetic: d.heading,
    });
  }
  console.log("  Mark distances done.");

  // Seed courses
  console.log(`Seeding ${data.courses.length} courses...`);
  for (const c of data.courses) {
    const marks = parseMarks(c.marks);
    const courseName = `Course ${c.num} — ${c.marks}`;
    await writeDoc(accessToken, "courses", `course_${c.num}`, {
      courseNumber: c.num,
      courseName,
      marks,
      distanceNm: c.dist,
      windDirectionBand: c.band,
      windDirMin: c.dirMin,
      windDirMax: c.dirMax,
      finishLocation: c.finish,
      canMultiply: c.x2 || false,
      requiresInflatable: c.inflatable || false,
      inflatableType: c.infType || null,
      isActive: true,
      notes: "",
    });
  }
  console.log("  Courses done.");

  console.log("\n=== Course Data Seeded ===");
  console.log(`  ${data.marks.length} marks`);
  console.log(`  ${data.mark_distances.length} mark distances`);
  console.log(`  ${data.courses.length} courses`);
  console.log("==========================\n");
  process.exit(0);
}

seed().catch((err) => {
  console.error("Failed:", err.message);
  process.exit(1);
});
