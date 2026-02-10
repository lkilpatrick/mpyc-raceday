// Seed boats (fleet) into Firestore
// Usage: node scripts/seed_boats.js

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

  const daysAgo = (n) => new Date(Date.now() - n * 86400000).toISOString();

  const boats = [
    // PHRF A Fleet
    { id: "boat_osprey", sailNumber: "USA 4417", boatName: "Osprey", ownerName: "Tom Bradley", boatClass: "J/105", phrfRating: 84, raceCount: 23, isActive: true, lastRacedAt: daysAgo(7), phone: "831-555-0101", email: "tbradley@mpyc.org" },
    { id: "boat_zephyr", sailNumber: "USA 2891", boatName: "Zephyr", ownerName: "Maria Santos", boatClass: "J/105", phrfRating: 84, raceCount: 19, isActive: true, lastRacedAt: daysAgo(7), phone: "831-555-0102", email: "msantos@mpyc.org" },
    { id: "boat_windswept", sailNumber: "USA 5523", boatName: "Windswept", ownerName: "Karen Patel", boatClass: "Beneteau 36.7", phrfRating: 78, raceCount: 15, isActive: true, lastRacedAt: daysAgo(7), phone: "831-555-0103", email: "kpatel@mpyc.org" },
    { id: "boat_bluehorizon", sailNumber: "USA 3310", boatName: "Blue Horizon", ownerName: "Rick Alvarez", boatClass: "Beneteau 36.7", phrfRating: 78, raceCount: 12, isActive: true, lastRacedAt: daysAgo(14), phone: "831-555-0104", email: "ralvarez@mpyc.org" },
    { id: "boat_marlin", sailNumber: "USA 6654", boatName: "Marlin", ownerName: "Amy Chen", boatClass: "C&C 30", phrfRating: 168, raceCount: 8, isActive: true, lastRacedAt: daysAgo(7), phone: "831-555-0105", email: "achen@mpyc.org" },

    // PHRF B Fleet
    { id: "boat_roguewave", sailNumber: "USA 9012", boatName: "Rogue Wave", ownerName: "Dan Mitchell", boatClass: "Catalina 30", phrfRating: 186, raceCount: 11, isActive: true, lastRacedAt: daysAgo(7), phone: "831-555-0106", email: "dmitchell@mpyc.org" },
    { id: "boat_tempest", sailNumber: "USA 7788", boatName: "Tempest", ownerName: "Greg Novak", boatClass: "Catalina 30", phrfRating: 186, raceCount: 6, isActive: true, lastRacedAt: daysAgo(7), phone: "831-555-0107", email: "gnovak@mpyc.org" },
    { id: "boat_catalyst", sailNumber: "USA 1234", boatName: "Catalyst", ownerName: "Dave Garcia", boatClass: "Hunter 33", phrfRating: 192, raceCount: 14, isActive: true, lastRacedAt: daysAgo(10), phone: "831-555-0108", email: "dgarcia@mpyc.org" },
    { id: "boat_pacificstar", sailNumber: "USA 5678", boatName: "Pacific Star", ownerName: "Jenny Lee", boatClass: "Ericson 32", phrfRating: 198, raceCount: 9, isActive: true, lastRacedAt: daysAgo(10), phone: "831-555-0109", email: "jlee@mpyc.org" },

    // Santana 22 Fleet (One Design)
    { id: "boat_santana_1", sailNumber: "S22-101", boatName: "Salty Dog", ownerName: "Jim Thompson", boatClass: "Santana 22", phrfRating: null, raceCount: 18, isActive: true, lastRacedAt: daysAgo(14), phone: "831-555-0110", email: "jthompson@mpyc.org" },
    { id: "boat_santana_2", sailNumber: "S22-204", boatName: "Sea Breeze", ownerName: "Sarah Martin", boatClass: "Santana 22", phrfRating: null, raceCount: 16, isActive: true, lastRacedAt: daysAgo(14), phone: "831-555-0111", email: "smartin@mpyc.org" },
    { id: "boat_santana_3", sailNumber: "S22-307", boatName: "Wavelength", ownerName: "Bob Wilson", boatClass: "Santana 22", phrfRating: null, raceCount: 20, isActive: true, lastRacedAt: daysAgo(14), phone: "831-555-0112", email: "bwilson@mpyc.org" },

    // Shields Fleet (One Design)
    { id: "boat_shields_1", sailNumber: "SH-42", boatName: "Resolute", ownerName: "Lisa Chen", boatClass: "Shields", phrfRating: null, raceCount: 22, isActive: true, lastRacedAt: daysAgo(14), phone: "831-555-0113", email: "lchen@mpyc.org" },
    { id: "boat_shields_2", sailNumber: "SH-56", boatName: "Defiant", ownerName: "Mike Ross", boatClass: "Shields", phrfRating: null, raceCount: 17, isActive: true, lastRacedAt: daysAgo(21), phone: "831-555-0114", email: "mross@mpyc.org" },

    // Inactive boat
    { id: "boat_retired_1", sailNumber: "USA 1001", boatName: "Old Salt", ownerName: "Frank Adams", boatClass: "Cal 20", phrfRating: 258, raceCount: 45, isActive: false, lastRacedAt: daysAgo(365), phone: "831-555-0120", email: "fadams@mpyc.org" },
  ];

  console.log(`Seeding ${boats.length} boats...`);
  for (const b of boats) {
    await writeDoc(accessToken, "boats", b.id, b);
    console.log(`  ✓ ${b.sailNumber} — ${b.boatName} (${b.boatClass})${b.isActive ? "" : " [INACTIVE]"}`);
  }

  console.log(`\n=== Fleet Seeded ===`);
  console.log(`  ${boats.filter(b => b.isActive).length} active boats`);
  console.log(`  ${boats.filter(b => !b.isActive).length} inactive boats`);
  console.log(`====================\n`);
  process.exit(0);
}

seed().catch((err) => {
  console.error("Failed:", err.message);
  process.exit(1);
});
