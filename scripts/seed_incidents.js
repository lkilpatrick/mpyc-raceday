// Seed sample race incidents into Firestore
// Usage: node scripts/seed_incidents.js

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

// ISO 8601 date string pattern
const ISO_DATE_RE = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/;

function toFsValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === "string") {
    // Detect ISO date strings and write as Firestore timestamps
    if (ISO_DATE_RE.test(val)) {
      return { timestampValue: val };
    }
    return { stringValue: val };
  }
  if (typeof val === "boolean") return { booleanValue: val };
  if (typeof val === "number") {
    return Number.isInteger(val) ? { integerValue: String(val) } : { doubleValue: val };
  }
  if (Array.isArray(val)) {
    if (val.length === 0) return { arrayValue: {} };
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

  const now = new Date();
  const daysAgo = (n) => new Date(now.getTime() - n * 86400000).toISOString();
  const hoursAgo = (n) => new Date(now.getTime() - n * 3600000).toISOString();

  const incidents = [
    // 1. Resolved protest — port/starboard at windward mark
    {
      id: "incident_001",
      eventId: "phrf_spring_2026-02-14",
      raceNumber: 1,
      reportedAt: daysAgo(7),
      reportedBy: "Jim Thompson",
      incidentTime: daysAgo(7),
      description: "At the windward mark rounding, S/V Zephyr on port tack failed to keep clear of S/V Osprey on starboard tack. Contact was made at the shrouds. Osprey had to take avoiding action, losing approximately 2 boat lengths. No damage to either vessel.",
      locationOnCourse: "windwardMark",
      involvedBoats: [
        { boatId: "boat_osprey", sailNumber: "USA 4417", boatName: "Osprey", skipperName: "Tom Bradley", role: "protesting" },
        { boatId: "boat_zephyr", sailNumber: "USA 2891", boatName: "Zephyr", skipperName: "Maria Santos", role: "protested" },
      ],
      rulesAlleged: [
        "10 – On Opposite Tacks",
        "14 – Avoiding Contact",
      ],
      status: "resolved",
      hearing: {
        scheduledAt: daysAgo(5),
        location: "MPYC Clubhouse, Race Committee Room",
        juryMembers: ["Jim Thompson", "Sarah Martin", "Bob Wilson"],
        findingOfFact: "The jury finds that S/V Zephyr was on port tack approaching the windward mark. S/V Osprey was on starboard tack with right of way. Zephyr failed to keep clear and contact occurred. Osprey took reasonable avoiding action.",
        rulesBroken: ["10", "14"],
        penalty: "DSQ Race 1",
        decisionNotes: "Zephyr is disqualified from Race 1 of the PHRF Spring Series on Feb 14, 2026. The protest is upheld.",
      },
      resolution: "Protest upheld. Zephyr DSQ from Race 1. No damage claim filed.",
      penaltyApplied: "DSQ",
      witnesses: ["Dave Garcia"],
      attachments: [],
      comments: [
        { id: "c1", authorId: "member_jthompson", authorName: "Jim Thompson", text: "Both parties heard. Zephyr acknowledged being on port tack.", createdAt: daysAgo(5) },
        { id: "c2", authorId: "member_smartin", authorName: "Sarah Martin", text: "Decision unanimous. Penalty applied to scoring.", createdAt: daysAgo(5) },
      ],
    },

    // 2. Protest filed, hearing scheduled — mark room dispute
    {
      id: "incident_002",
      eventId: "phrf_spring_2026-02-14",
      raceNumber: 2,
      reportedAt: daysAgo(6),
      reportedBy: "Karen Patel",
      incidentTime: daysAgo(7),
      description: "At the leeward gate, S/V Windswept claims S/V Blue Horizon did not give mark room when both boats were overlapped entering the zone. Windswept was forced wide of the mark and had to re-round, losing 4 positions.",
      locationOnCourse: "leewardMark",
      involvedBoats: [
        { boatId: "boat_windswept", sailNumber: "USA 5523", boatName: "Windswept", skipperName: "Karen Patel", role: "protesting" },
        { boatId: "boat_bluehorizon", sailNumber: "USA 3310", boatName: "Blue Horizon", skipperName: "Rick Alvarez", role: "protested" },
        { boatId: "boat_osprey", sailNumber: "USA 4417", boatName: "Osprey", skipperName: "Tom Bradley", role: "witness" },
      ],
      rulesAlleged: [
        "18.2(b) – Giving Mark-Room",
        "18.2(c) – Mark-Room at a Gate",
      ],
      status: "hearingScheduled",
      hearing: {
        scheduledAt: new Date(now.getTime() + 3 * 86400000).toISOString(), // 3 days from now
        location: "MPYC Clubhouse, Race Committee Room",
        juryMembers: ["Jim Thompson", "Lisa Chen", "Dave Garcia"],
        findingOfFact: "",
        rulesBroken: [],
        penalty: "",
        decisionNotes: "",
      },
      resolution: "",
      penaltyApplied: "",
      witnesses: ["Tom Bradley"],
      attachments: [],
      comments: [
        { id: "c3", authorId: "member_kpatel", authorName: "Karen Patel", text: "We were clearly overlapped at 3 boat lengths from the mark. I hailed for room.", createdAt: daysAgo(6) },
        { id: "c4", authorId: "member_jthompson", authorName: "Jim Thompson", text: "Hearing scheduled for this week. Both parties notified.", createdAt: daysAgo(4) },
      ],
    },

    // 3. Recently reported — safety incident on the water
    {
      id: "incident_003",
      eventId: "phrf_spring_2026-02-21",
      raceNumber: 1,
      reportedAt: daysAgo(1),
      reportedBy: "Bob Wilson",
      incidentTime: daysAgo(1),
      description: "S/V Tempest lost steering control near the start line due to a broken tiller extension. Boat veered into the path of S/V Marlin, which had to bear away sharply to avoid collision. No contact made. Tempest retired from the race and was towed in by the safety boat.",
      locationOnCourse: "startLine",
      involvedBoats: [
        { boatId: "boat_tempest", sailNumber: "USA 7788", boatName: "Tempest", skipperName: "Greg Novak", role: "protested" },
        { boatId: "boat_marlin", sailNumber: "USA 6654", boatName: "Marlin", skipperName: "Amy Chen", role: "protesting" },
      ],
      rulesAlleged: [
        "2 – Fair Sailing",
        "14 – Avoiding Contact",
      ],
      status: "reported",
      hearing: null,
      resolution: "",
      penaltyApplied: "",
      witnesses: ["Bob Wilson", "Mike Ross"],
      attachments: [],
      comments: [
        { id: "c5", authorId: "member_bwilson", authorName: "Bob Wilson", text: "Observed from safety boat. Tempest crew handled situation well, no injuries. Equipment failure appears to be the cause.", createdAt: daysAgo(1) },
      ],
    },

    // 4. Protest filed — overlap dispute at start
    {
      id: "incident_004",
      eventId: "phrf_spring_2026-02-21",
      raceNumber: 2,
      reportedAt: hoursAgo(36),
      reportedBy: "Maria Santos",
      incidentTime: daysAgo(1),
      description: "In the final 30 seconds before the start, S/V Zephyr was luffing to protect her position. S/V Rogue Wave, to leeward, claims Zephyr sailed above her proper course before the start signal, forcing Rogue Wave below the start line. Rogue Wave had to restart, losing approximately 45 seconds.",
      locationOnCourse: "startLine",
      involvedBoats: [
        { boatId: "boat_roguewave", sailNumber: "USA 9012", boatName: "Rogue Wave", skipperName: "Dan Mitchell", role: "protesting" },
        { boatId: "boat_zephyr", sailNumber: "USA 2891", boatName: "Zephyr", skipperName: "Maria Santos", role: "protested" },
      ],
      rulesAlleged: [
        "11 – On the Same Tack, Overlapped",
        "15 – Acquiring Right of Way",
        "17 – On the Same Tack; Proper Course",
      ],
      status: "protestFiled",
      hearing: null,
      resolution: "",
      penaltyApplied: "",
      witnesses: [],
      attachments: [],
      comments: [
        { id: "c6", authorId: "seed-script", authorName: "Maria Santos", text: "I was sailing my proper course. Rogue Wave established the overlap late and from behind.", createdAt: hoursAgo(35) },
        { id: "c7", authorId: "seed-script", authorName: "Dan Mitchell", text: "Overlap was established well before the zone. Zephyr luffed aggressively above close-hauled.", createdAt: hoursAgo(30) },
      ],
    },

    // 5. Withdrawn protest
    {
      id: "incident_005",
      eventId: "sunset_2026-02-11",
      raceNumber: 1,
      reportedAt: daysAgo(10),
      reportedBy: "Dave Garcia",
      incidentTime: daysAgo(10),
      description: "S/V Catalyst claims S/V Pacific Star failed to respond to a hail for water at the reaching mark. After reviewing video evidence, the protesting party acknowledged they were not overlapped at the zone entry.",
      locationOnCourse: "reachingMark",
      involvedBoats: [
        { boatId: "boat_catalyst", sailNumber: "USA 1234", boatName: "Catalyst", skipperName: "Dave Garcia", role: "protesting" },
        { boatId: "boat_pacificstar", sailNumber: "USA 5678", boatName: "Pacific Star", skipperName: "Jenny Lee", role: "protested" },
      ],
      rulesAlleged: [
        "18.2(b) – Giving Mark-Room",
      ],
      status: "withdrawn",
      hearing: null,
      resolution: "Protest withdrawn by protesting party after reviewing video evidence.",
      penaltyApplied: "",
      witnesses: [],
      attachments: [],
      comments: [
        { id: "c8", authorId: "member_dgarcia", authorName: "Dave Garcia", text: "After reviewing the GoPro footage, I can see we were not overlapped at 3 lengths. Withdrawing the protest.", createdAt: daysAgo(9) },
        { id: "c9", authorId: "member_jthompson", authorName: "Jim Thompson", text: "Protest withdrawn. No further action required.", createdAt: daysAgo(9) },
      ],
    },
  ];

  console.log(`Seeding ${incidents.length} incidents...`);
  for (const inc of incidents) {
    await writeDoc(accessToken, "incidents", inc.id, inc);
    const boats = inc.involvedBoats.map((b) => b.sailNumber).join(" vs ");
    console.log(`  ✓ ${inc.id} — ${boats} [${inc.status}]`);
  }

  console.log(`\n=== Incidents Seeded ===`);
  console.log(`  ${incidents.length} incidents across multiple statuses:`);
  console.log(`    - 1 resolved (with hearing decision)`);
  console.log(`    - 1 hearing scheduled`);
  console.log(`    - 1 reported (safety incident)`);
  console.log(`    - 1 protest filed (pending hearing)`);
  console.log(`    - 1 withdrawn`);
  console.log(`========================\n`);
  process.exit(0);
}

seed().catch((err) => {
  console.error("Failed:", err.message);
  process.exit(1);
});
