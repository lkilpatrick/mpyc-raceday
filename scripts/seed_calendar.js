// Seed 2026 race calendar from CSV into Firestore
// Usage: node scripts/seed_calendar.js

const path = require("path");
const fs = require("fs");
const os = require("os");

const admin = require(path.join(__dirname, "..", "functions", "node_modules", "firebase-admin"));

// Load Firebase CLI refresh token
const winPath = path.join(process.env.APPDATA || "", "configstore", "firebase-tools.json");
const nixPath = path.join(os.homedir(), ".config", "configstore", "firebase-tools.json");
const configPath = fs.existsSync(winPath) ? winPath : nixPath;

if (!fs.existsSync(configPath)) {
  console.error("Firebase CLI credentials not found. Run: npx firebase-tools login");
  process.exit(1);
}

const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
const refreshToken = config.tokens?.refresh_token;
if (!refreshToken) {
  console.error("No refresh token. Run: npx firebase-tools login");
  process.exit(1);
}

const credential = admin.credential.refreshToken({
  type: "authorized_user",
  client_id: "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com",
  client_secret: "j9iVZfS8kkCEFUPaAeJV0sAi",
  refresh_token: refreshToken,
});

// --- CSV Parsing ---

function parseCsvLine(line) {
  const fields = [];
  let current = "";
  let inQuotes = false;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (ch === '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] === '"') {
        current += '"';
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (ch === "," && !inQuotes) {
      fields.push(current.trim());
      current = "";
    } else {
      current += ch;
    }
  }
  fields.push(current.trim());
  return fields;
}

const MONTHS = {
  january: 1, february: 2, march: 3, april: 4,
  may: 5, june: 6, july: 7, august: 8,
  september: 9, october: 10, november: 11, december: 12,
};

function parseMpycDate(raw) {
  if (!raw) return null;
  let s = raw.trim();
  if (!s) return null;
  // Remove leading day name
  const commaIdx = s.indexOf(",");
  if (commaIdx > 0) s = s.substring(commaIdx + 1).trim();
  // Normalize
  s = s.replace(/,\s*/g, ", ");
  const match = s.match(/(\w+)\s+(\d{1,2}),?\s*(\d{4})/);
  if (match) {
    const month = MONTHS[match[1].toLowerCase()];
    const day = parseInt(match[2]);
    const year = parseInt(match[3]);
    if (month && day && year) return new Date(year, month - 1, day);
  }
  return null;
}

function parseTime(raw) {
  if (!raw) return null;
  const s = raw.trim();
  if (!s || s === "TBD" || s === "?") return null;
  const match = s.match(/(\d{1,2}):(\d{2})\s*(AM|PM)/i);
  if (match) {
    let hour = parseInt(match[1]);
    const minute = parseInt(match[2]);
    const amPm = match[3].toUpperCase();
    if (amPm === "PM" && hour !== 12) hour += 12;
    if (amPm === "AM" && hour === 12) hour = 0;
    return { hour, minute };
  }
  return null;
}

function deriveSeries(name) {
  const lower = name.toLowerCase();
  if (lower.includes("sunset series")) return "Sunset Series";
  if (lower.includes("phrf spring")) return "PHRF Spring";
  if (lower.includes("phrf fall")) return "PHRF Fall";
  if (lower.includes("one design spring")) return "One Design Spring";
  if (lower.includes("one design summer")) return "One Design Summer";
  if (lower.includes("one design fall")) return "One Design Fall";
  if (lower.includes("mbyra")) return "MBYRA";
  if (lower.includes("commodore")) return "Commodores Regatta";
  if (lower.includes("national")) return "Nationals";
  if (lower.includes("youth") || lower.includes("junior")) return "Youth";
  if (lower.includes("clinic") || lower.includes("training")) return "Training";
  return "Special Events";
}

// --- Main ---

async function seed() {
  const csvPath = path.join(__dirname, "..", "assets", "racecalendar",
    "2026_MPYC_MasterRaceCalendar - MPYC 2026 Race Calendar.csv");

  if (!fs.existsSync(csvPath)) {
    console.error("CSV not found:", csvPath);
    process.exit(1);
  }

  const text = fs.readFileSync(csvPath, "utf8");
  const lines = text.split("\n").map(l => l.trim()).filter(l => l.length > 0);

  // Find header row
  let headerIdx = 0;
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].includes("Title") && lines[i].includes("Start Date")) {
      headerIdx = i;
      break;
    }
  }

  const headers = parseCsvLine(lines[headerIdx]);
  const rows = [];
  for (let i = headerIdx + 1; i < lines.length; i++) {
    const parts = parseCsvLine(lines[i]);
    if (parts.every(p => !p)) continue;
    const row = {};
    for (let j = 0; j < headers.length && j < parts.length; j++) {
      row[headers[j]] = parts[j];
    }
    rows.push(row);
  }

  console.log(`Parsed ${rows.length} rows from CSV.`);

  // Write to Firestore via REST API
  const accessToken = (await credential.getAccessToken()).access_token;
  const baseUrl = "https://firestore.googleapis.com/v1/projects/mpyc-raceday/databases/(default)/documents";

  let created = 0;
  let skipped = 0;

  for (const row of rows) {
    const name = (row["Title"] || "").trim();
    const dateRaw = (row["Start Date"] || "").trim();
    const timeRaw = (row["Start Time"] || "").trim();
    const description = (row["Description"] || "").trim();
    const location = (row["Location"] || "").trim();
    const contact = (row["Contact"] || "").trim();
    const extraInfo = (row["Extra Info"] || "").trim();
    const rcFleet = (row["RC Fleet"] || "").trim();
    const raceCommittee = (row["Race Committee"] || "").trim();

    if (!name || !dateRaw) { skipped++; continue; }
    if (name.toLowerCase().startsWith("revision")) { skipped++; continue; }
    if (/^[A-Z]+$/.test(name)) { skipped++; continue; } // Month headers

    const date = parseMpycDate(dateRaw);
    if (!date) {
      console.log(`  Skipping "${name}" — invalid date: ${dateRaw}`);
      skipped++;
      continue;
    }

    const time = parseTime(timeRaw);
    const seriesName = deriveSeries(name);
    const seriesId = seriesName.toLowerCase().replace(/ /g, "_");
    const docId = `import_${date.getTime()}_${created}`;

    const fields = {
      name: { stringValue: name },
      date: { timestampValue: date.toISOString() },
      seriesId: { stringValue: seriesId },
      seriesName: { stringValue: seriesName },
      status: { stringValue: "scheduled" },
      startTimeHour: time ? { integerValue: String(time.hour) } : { nullValue: null },
      startTimeMinute: time ? { integerValue: String(time.minute) } : { nullValue: null },
      notes: { nullValue: null },
      description: { stringValue: description },
      location: { stringValue: location },
      contact: { stringValue: contact },
      extraInfo: { stringValue: extraInfo },
      rcFleet: { stringValue: rcFleet },
      raceCommittee: { stringValue: raceCommittee },
      crewSlots: {
        arrayValue: {
          values: [
            { mapValue: { fields: { role: { stringValue: "pro" }, status: { stringValue: "pending" } } } },
            { mapValue: { fields: { role: { stringValue: "signalBoat" }, status: { stringValue: "pending" } } } },
            { mapValue: { fields: { role: { stringValue: "markBoat" }, status: { stringValue: "pending" } } } },
            { mapValue: { fields: { role: { stringValue: "safetyBoat" }, status: { stringValue: "pending" } } } },
          ],
        },
      },
    };

    const url = `${baseUrl}/race_events/${docId}`;
    const resp = await fetch(url, {
      method: "PATCH",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ fields }),
    });

    if (!resp.ok) {
      const err = await resp.text();
      console.error(`  FAILED "${name}": ${err}`);
    } else {
      created++;
      process.stdout.write(`\r  Created ${created} events...`);
    }
  }

  console.log(`\n\n=== Calendar Seed Complete ===`);
  console.log(`Created: ${created}`);
  console.log(`Skipped: ${skipped}`);
  console.log(`=============================\n`);
  process.exit(0);
}

seed().catch(err => {
  console.error("Failed:", err.message);
  process.exit(1);
});
