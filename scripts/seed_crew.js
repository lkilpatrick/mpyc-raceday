// Seed race events, series, and sample crew assignments into Firestore
// Usage: node scripts/seed_crew.js

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
  if (typeof val === "object" && val.constructor === Object) {
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

async function seed() {
  const accessToken = (await credential.getAccessToken()).access_token;

  // ── RC Crew Members (sample) ──
  const crewMembers = [
    { id: "member_jthompson", firstName: "Jim", lastName: "Thompson", roles: ["rc_chair"], memberTags: ["rc_qualified"], memberNumber: "M-101", email: "jthompson@mpyc.org" },
    { id: "member_smartin", firstName: "Sarah", lastName: "Martin", roles: ["skipper"], memberTags: ["rc_qualified"], memberNumber: "M-102", email: "smartin@mpyc.org" },
    { id: "member_bwilson", firstName: "Bob", lastName: "Wilson", roles: ["skipper"], memberTags: ["rc_qualified"], memberNumber: "M-103", email: "bwilson@mpyc.org" },
    { id: "member_lchen", firstName: "Lisa", lastName: "Chen", roles: ["skipper"], memberTags: ["rc_qualified"], memberNumber: "M-104", email: "lchen@mpyc.org" },
    { id: "member_dgarcia", firstName: "Dave", lastName: "Garcia", roles: ["skipper"], memberTags: ["rc_qualified"], memberNumber: "M-105", email: "dgarcia@mpyc.org" },
    { id: "member_kpatel", firstName: "Karen", lastName: "Patel", roles: ["crew"], memberTags: ["rc_qualified"], memberNumber: "M-106", email: "kpatel@mpyc.org" },
    { id: "member_mross", firstName: "Mike", lastName: "Ross", roles: ["crew"], memberTags: ["rc_qualified"], memberNumber: "M-107", email: "mross@mpyc.org" },
    { id: "member_jlee", firstName: "Jenny", lastName: "Lee", roles: ["crew"], memberTags: ["rc_qualified"], memberNumber: "M-108", email: "jlee@mpyc.org" },
  ];

  console.log(`Seeding ${crewMembers.length} RC crew members...`);
  for (const m of crewMembers) {
    await writeDoc(accessToken, "members", m.id, {
      firstName: m.firstName,
      lastName: m.lastName,
      email: m.email,
      memberNumber: m.memberNumber,
      roles: m.roles,
      memberTags: m.memberTags,
      membershipStatus: "active",
      membershipCategory: "Regular",
      isActive: true,
      mobileNumber: "",
      signalNumber: "",
      boatName: "",
      sailNumber: "",
      boatClass: "",
      phrfRating: 0,
    });
    console.log(`  ✓ ${m.firstName} ${m.lastName}`);
  }

  // ── Season Series ──
  const series = [
    {
      id: "phrf_spring_2026",
      name: "PHRF Spring Series",
      color: 4280391411, // Colors.blue
      startDate: "2026-03-01T00:00:00Z",
      endDate: "2026-05-31T00:00:00Z",
      recurringWeekday: 6, // Saturday
    },
    {
      id: "sunset_2026",
      name: "Sunset Series",
      color: 4294940672, // Colors.orange
      startDate: "2026-04-01T00:00:00Z",
      endDate: "2026-09-30T00:00:00Z",
      recurringWeekday: 3, // Wednesday
    },
  ];

  console.log(`\nSeeding ${series.length} season series...`);
  for (const s of series) {
    await writeDoc(accessToken, "season_series", s.id, {
      name: s.name,
      color: s.color,
      startDate: s.startDate,
      endDate: s.endDate,
      recurringWeekday: s.recurringWeekday,
    });
    console.log(`  ✓ ${s.name}`);
  }

  // ── Race Events with Crew Assignments ──
  // Generate upcoming Saturdays for PHRF Spring and Wednesdays for Sunset
  const events = [];
  const now = new Date();

  // Next 6 Saturdays for PHRF Spring
  let sat = new Date(now);
  sat.setDate(sat.getDate() + ((6 - sat.getDay() + 7) % 7 || 7)); // next Saturday
  const crewRotation = [
    // [PRO, Signal Boat, Mark Boat, Safety Boat]
    ["Jim Thompson", "Sarah Martin", "Bob Wilson", "Lisa Chen"],
    ["Sarah Martin", "Dave Garcia", "Karen Patel", "Mike Ross"],
    ["Bob Wilson", "Jim Thompson", "Jenny Lee", "Dave Garcia"],
    ["Lisa Chen", "Karen Patel", "Mike Ross", "Sarah Martin"],
    ["Dave Garcia", "Jenny Lee", "Jim Thompson", "Bob Wilson"],
    ["Karen Patel", "Mike Ross", "Lisa Chen", "Jenny Lee"],
  ];

  const memberIdMap = {
    "Jim Thompson": "member_jthompson",
    "Sarah Martin": "member_smartin",
    "Bob Wilson": "member_bwilson",
    "Lisa Chen": "member_lchen",
    "Dave Garcia": "member_dgarcia",
    "Karen Patel": "member_kpatel",
    "Mike Ross": "member_mross",
    "Jenny Lee": "member_jlee",
  };

  for (let i = 0; i < 6; i++) {
    const eventDate = new Date(sat);
    eventDate.setDate(eventDate.getDate() + i * 7);
    const dateStr = eventDate.toISOString().split("T")[0];
    const crew = crewRotation[i % crewRotation.length];
    const statuses = ["confirmed", "confirmed", "pending", "pending"];
    // First 2 events are past-ish or very soon, mark first as completed
    const eventStatus = i === 0 ? "completed" : "scheduled";

    events.push({
      id: `phrf_spring_${dateStr}`,
      name: `PHRF Spring ${eventDate.getMonth() + 1}/${eventDate.getDate()}`,
      date: eventDate.toISOString(),
      seriesId: "phrf_spring_2026",
      seriesName: "PHRF Spring Series",
      status: eventStatus,
      startTimeHour: 13,
      startTimeMinute: 0,
      notes: null,
      description: "PHRF Spring Series race day",
      location: "Monterey Bay — MPYC",
      contact: "Race Committee",
      extraInfo: "",
      rcFleet: "PHRF",
      raceCommittee: crew[0],
      crewSlots: [
        { role: "pro", memberId: memberIdMap[crew[0]], memberName: crew[0], status: statuses[0] },
        { role: "signalBoat", memberId: memberIdMap[crew[1]], memberName: crew[1], status: statuses[1] },
        { role: "markBoat", memberId: memberIdMap[crew[2]], memberName: crew[2], status: statuses[2] },
        { role: "safetyBoat", memberId: memberIdMap[crew[3]], memberName: crew[3], status: statuses[3] },
      ],
    });
  }

  // Next 4 Wednesdays for Sunset Series
  let wed = new Date(now);
  wed.setDate(wed.getDate() + ((3 - wed.getDay() + 7) % 7 || 7)); // next Wednesday
  const sunsetRotation = [
    ["Dave Garcia", "Jenny Lee", "Mike Ross", "Karen Patel"],
    ["Jim Thompson", "Lisa Chen", "Bob Wilson", "Sarah Martin"],
    ["Sarah Martin", "Bob Wilson", "Dave Garcia", "Jenny Lee"],
    ["Lisa Chen", "Mike Ross", "Karen Patel", "Jim Thompson"],
  ];

  for (let i = 0; i < 4; i++) {
    const eventDate = new Date(wed);
    eventDate.setDate(eventDate.getDate() + i * 7);
    const dateStr = eventDate.toISOString().split("T")[0];
    const crew = sunsetRotation[i % sunsetRotation.length];

    events.push({
      id: `sunset_${dateStr}`,
      name: `Sunset Series ${eventDate.getMonth() + 1}/${eventDate.getDate()}`,
      date: eventDate.toISOString(),
      seriesId: "sunset_2026",
      seriesName: "Sunset Series",
      status: "scheduled",
      startTimeHour: 18,
      startTimeMinute: 0,
      notes: null,
      description: "Sunset Series Wednesday evening race",
      location: "Monterey Bay — MPYC",
      contact: "Race Committee",
      extraInfo: "",
      rcFleet: "One Design",
      raceCommittee: crew[0],
      crewSlots: [
        { role: "pro", memberId: memberIdMap[crew[0]], memberName: crew[0], status: "confirmed" },
        { role: "signalBoat", memberId: memberIdMap[crew[1]], memberName: crew[1], status: "confirmed" },
        { role: "markBoat", memberId: memberIdMap[crew[2]], memberName: crew[2], status: "pending" },
        { role: "safetyBoat", memberId: memberIdMap[crew[3]], memberName: crew[3], status: "pending" },
      ],
    });
  }

  console.log(`\nSeeding ${events.length} race events...`);
  for (const e of events) {
    await writeDoc(accessToken, "race_events", e.id, e);
    console.log(`  ✓ ${e.name} (${e.status}) — PRO: ${e.crewSlots[0].memberName}`);
  }

  console.log(`\n=== Crew Data Seeded ===`);
  console.log(`  ${crewMembers.length} RC crew members`);
  console.log(`  ${series.length} season series`);
  console.log(`  ${events.length} race events with crew assignments`);
  console.log(`========================\n`);
  process.exit(0);
}

seed().catch((err) => {
  console.error("Failed:", err.message);
  process.exit(1);
});
