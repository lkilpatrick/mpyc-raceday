// Seed maintenance_requests and scheduled_maintenance into Firestore
// Usage: node scripts/seed_maintenance.js

const path = require("path");
const os = require("os");
const fs = require("fs");

const admin = require(path.join(__dirname, "..", "functions", "node_modules", "firebase-admin"));

const PROJECT_ID = "mpyc-raceday";
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

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

const ISO_DATE_RE = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/;

function toFsValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === "string") {
    if (ISO_DATE_RE.test(val)) return { timestampValue: val };
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
    for (const [k, v] of Object.entries(val)) fields[k] = toFsValue(v);
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

async function writeDoc(accessToken, collection, docId, data) {
  const url = `${BASE_URL}/${collection}/${docId}`;
  const fields = {};
  for (const [k, v] of Object.entries(data)) fields[k] = toFsValue(v);
  const resp = await fetch(url, {
    method: "PATCH",
    headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
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
  const daysFromNow = (n) => new Date(now.getTime() + n * 86400000).toISOString();

  // ── Maintenance Requests ──
  const requests = [
    {
      id: "maint_001",
      title: "Raw water pump impeller replacement",
      description: "Duncan's Watch engine raw water pump is making grinding noise. Impeller likely worn. Needs replacement before next race day.",
      priority: "high",
      reportedBy: "Jim Thompson",
      reportedAt: daysAgo(5),
      assignedTo: "Bob Wilson",
      status: "inProgress",
      photos: [],
      completedAt: null,
      completionNotes: null,
      boatName: "Duncan's Watch",
      category: "engine",
      estimatedCost: 85.0,
      comments: [
        { id: "mc1", authorId: "member_jthompson", authorName: "Jim Thompson", text: "Noticed grinding noise during post-race checkout. Raw water flow was weak.", photoUrl: null, createdAt: daysAgo(5) },
        { id: "mc2", authorId: "member_bwilson", authorName: "Bob Wilson", text: "Ordered Jabsco impeller kit. Should arrive Wednesday.", photoUrl: null, createdAt: daysAgo(3) },
      ],
    },
    {
      id: "maint_002",
      title: "VHF antenna connection loose",
      description: "Signal boat VHF radio intermittent on transmit. Antenna connector at masthead appears loose. Needs re-termination.",
      priority: "medium",
      reportedBy: "Sarah Martin",
      reportedAt: daysAgo(10),
      assignedTo: null,
      status: "reported",
      photos: [],
      completedAt: null,
      completionNotes: null,
      boatName: "Signal Boat",
      category: "electronics",
      estimatedCost: 45.0,
      comments: [
        { id: "mc3", authorId: "member_smartin", authorName: "Sarah Martin", text: "Radio works fine on receive but transmit is cutting in and out. Other boats report weak signal from us.", photoUrl: null, createdAt: daysAgo(10) },
      ],
    },
    {
      id: "maint_003",
      title: "Gelcoat crack on port bow",
      description: "Mark boat has a 6-inch gelcoat crack on the port bow above the waterline. Likely from dock contact. Cosmetic but should be repaired before it spreads.",
      priority: "low",
      reportedBy: "Dave Garcia",
      reportedAt: daysAgo(21),
      assignedTo: null,
      status: "deferred",
      photos: [],
      completedAt: null,
      completionNotes: null,
      boatName: "Mark Boat",
      category: "hull",
      estimatedCost: 150.0,
      comments: [
        { id: "mc4", authorId: "member_dgarcia", authorName: "Dave Garcia", text: "Crack is above waterline, no structural concern. Recommend repair during spring haul-out.", photoUrl: null, createdAt: daysAgo(21) },
        { id: "mc5", authorId: "member_jthompson", authorName: "Jim Thompson", text: "Agreed — deferring to spring haul-out. Added to haul-out punch list.", photoUrl: null, createdAt: daysAgo(18) },
      ],
    },
    {
      id: "maint_004",
      title: "Fire extinguisher expired — Safety Boat",
      description: "Safety boat fire extinguisher inspection tag shows expired Dec 2025. Needs immediate replacement per USCG requirements.",
      priority: "critical",
      reportedBy: "Lisa Chen",
      reportedAt: daysAgo(3),
      assignedTo: "Lisa Chen",
      status: "completed",
      photos: [],
      completedAt: daysAgo(1),
      completionNotes: "Replaced with new Kidde 5-BC marine extinguisher. Old unit disposed at fire station. New inspection tag valid through Dec 2027.",
      boatName: "Safety Boat",
      category: "safety",
      estimatedCost: 35.0,
      comments: [
        { id: "mc6", authorId: "member_lchen", authorName: "Lisa Chen", text: "Found during pre-race checkout. Boat cannot operate without current extinguisher.", photoUrl: null, createdAt: daysAgo(3) },
        { id: "mc7", authorId: "member_lchen", authorName: "Lisa Chen", text: "Purchased replacement at West Marine. Installed and verified.", photoUrl: null, createdAt: daysAgo(1) },
      ],
    },
    {
      id: "maint_005",
      title: "Bilge pump float switch stuck",
      description: "Duncan's Watch bilge pump auto-float switch is stuck in the off position. Manual switch works fine. Float switch needs cleaning or replacement.",
      priority: "medium",
      reportedBy: "Bob Wilson",
      reportedAt: daysAgo(8),
      assignedTo: "Mike Ross",
      status: "awaitingParts",
      photos: [],
      completedAt: null,
      completionNotes: null,
      boatName: "Duncan's Watch",
      category: "electrical",
      estimatedCost: 28.0,
      comments: [
        { id: "mc8", authorId: "member_bwilson", authorName: "Bob Wilson", text: "Float switch appears to be fouled with debris. Tried cleaning but it's still intermittent.", photoUrl: null, createdAt: daysAgo(8) },
        { id: "mc9", authorId: "member_mross", authorName: "Mike Ross", text: "Ordered Rule-A-Matic float switch. ETA Friday.", photoUrl: null, createdAt: daysAgo(6) },
      ],
    },
    {
      id: "maint_006",
      title: "Tow line chafed — needs replacement",
      description: "Safety boat 50ft tow line has significant chafe at the fairlead. Core strands visible. Must be replaced before next use.",
      priority: "high",
      reportedBy: "Karen Patel",
      reportedAt: daysAgo(2),
      assignedTo: null,
      status: "acknowledged",
      photos: [],
      completedAt: null,
      completionNotes: null,
      boatName: "Safety Boat",
      category: "safety",
      estimatedCost: 65.0,
      comments: [
        { id: "mc10", authorId: "member_kpatel", authorName: "Karen Patel", text: "Found during post-race inspection. Line is unsafe for towing — core strands exposed over 8 inches.", photoUrl: null, createdAt: daysAgo(2) },
      ],
    },
  ];

  console.log(`Seeding ${requests.length} maintenance requests...`);
  for (const r of requests) {
    await writeDoc(accessToken, "maintenance_requests", r.id, r);
    console.log(`  ✓ ${r.title} [${r.status}] — ${r.boatName}`);
  }

  // ── Scheduled Maintenance ──
  const scheduled = [
    { id: "sched_001", boatName: "Duncan's Watch", title: "Engine oil change", description: "Change engine oil and filter. Use 15W-40 marine diesel oil.", intervalDays: 100, lastCompletedAt: daysAgo(85), nextDueAt: daysFromNow(15) },
    { id: "sched_002", boatName: "Duncan's Watch", title: "Zinc anode inspection", description: "Inspect and replace shaft and rudder zinc anodes as needed.", intervalDays: 180, lastCompletedAt: daysAgo(150), nextDueAt: daysFromNow(30) },
    { id: "sched_003", boatName: "Signal Boat", title: "Engine oil change", description: "Change engine oil and filter.", intervalDays: 100, lastCompletedAt: daysAgo(45), nextDueAt: daysFromNow(55) },
    { id: "sched_004", boatName: "Signal Boat", title: "Impeller replacement", description: "Replace raw water pump impeller. Inspect pump housing for scoring.", intervalDays: 365, lastCompletedAt: daysAgo(300), nextDueAt: daysFromNow(65) },
    { id: "sched_005", boatName: "Mark Boat", title: "Engine oil change", description: "Change engine oil and filter.", intervalDays: 100, lastCompletedAt: daysAgo(110), nextDueAt: daysAgo(10) }, // overdue!
    { id: "sched_006", boatName: "Mark Boat", title: "Trailer bearing repack", description: "Repack trailer wheel bearings with marine grease.", intervalDays: 365, lastCompletedAt: daysAgo(200), nextDueAt: daysFromNow(165) },
    { id: "sched_007", boatName: "Safety Boat", title: "Engine oil change", description: "Change engine oil and filter.", intervalDays: 50, lastCompletedAt: daysAgo(40), nextDueAt: daysFromNow(10) },
    { id: "sched_008", boatName: "Safety Boat", title: "Annual safety inspection", description: "Complete annual USCG safety inspection checklist.", intervalDays: 365, lastCompletedAt: daysAgo(330), nextDueAt: daysFromNow(35) },
  ];

  console.log(`\nSeeding ${scheduled.length} scheduled maintenance items...`);
  for (const s of scheduled) {
    await writeDoc(accessToken, "scheduled_maintenance", s.id, s);
    const overdue = s.nextDueAt && new Date(s.nextDueAt) < now;
    console.log(`  ✓ ${s.boatName} — ${s.title} (every ${s.intervalDays}d)${overdue ? " ⚠ OVERDUE" : ""}`);
  }

  console.log(`\n=== Maintenance Data Seeded ===`);
  console.log(`  ${requests.length} maintenance requests`);
  console.log(`  ${scheduled.length} scheduled maintenance items`);
  console.log(`===============================\n`);
  process.exit(0);
}

seed().catch((err) => {
  console.error("Failed:", err.message);
  process.exit(1);
});
