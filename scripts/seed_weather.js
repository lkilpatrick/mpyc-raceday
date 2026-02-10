// Fetch NOAA weather and write to Firestore weather/mpyc_station
// Usage: node scripts/seed_weather.js

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

function toFsValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === "string") return { stringValue: val };
  if (typeof val === "boolean") return { booleanValue: val };
  if (typeof val === "number") {
    return Number.isInteger(val) ? { integerValue: String(val) } : { doubleValue: val };
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
    throw new Error(`Firestore write failed (${resp.status}): ${errBody}`);
  }
}

const NOAA_BASE = "https://api.weather.gov";
const NOAA_HEADERS = {
  "User-Agent": "MPYCRaceDay/1.0 (contact@mpyc.org)",
  "Accept": "application/geo+json",
};

async function fetchNoaa() {
  const LAT = 36.6002;
  const LON = -121.8947;

  console.log("Fetching NOAA observation stations...");
  const pointResp = await fetch(`${NOAA_BASE}/points/${LAT},${LON}`, { headers: NOAA_HEADERS });
  if (!pointResp.ok) throw new Error(`NOAA points error ${pointResp.status}`);
  const pointData = await pointResp.json();
  const stationsUrl = pointData?.properties?.observationStations;

  const stationsResp = await fetch(stationsUrl, { headers: NOAA_HEADERS });
  if (!stationsResp.ok) throw new Error(`NOAA stations error ${stationsResp.status}`);
  const stationsData = await stationsResp.json();
  const stationId = stationsData?.features?.[0]?.properties?.stationIdentifier;
  const stationName = stationsData?.features?.[0]?.properties?.name || "NOAA Station";
  console.log(`  Station: ${stationId} (${stationName})`);

  console.log("Fetching latest observation...");
  const obsResp = await fetch(`${NOAA_BASE}/stations/${stationId}/observations/latest`, { headers: NOAA_HEADERS });
  if (!obsResp.ok) throw new Error(`NOAA observation error ${obsResp.status}`);
  const obsData = await obsResp.json();
  const obs = obsData?.properties;

  const MS_TO_KTS = 1.94384;
  const windSpeedMs = obs.windSpeed?.value ?? 0;
  const windGustMs = obs.windGust?.value ?? null;
  const dirDeg = obs.windDirection?.value ?? 0;
  const tempC = obs.temperature?.value ?? null;
  const humidity = obs.relativeHumidity?.value ?? null;
  const pressurePa = obs.barometricPressure?.value ?? null;

  const speedKts = Math.round(windSpeedMs * MS_TO_KTS * 100) / 100;
  const speedMph = Math.round(speedKts / 0.868976 * 100) / 100;
  const gustKts = windGustMs !== null ? Math.round(windGustMs * MS_TO_KTS * 100) / 100 : null;
  const gustMph = gustKts !== null ? Math.round(gustKts / 0.868976 * 100) / 100 : null;
  const tempF = tempC !== null ? Math.round((tempC * 9 / 5 + 32) * 10) / 10 : null;
  const pressureInHg = pressurePa !== null ? Math.round(pressurePa / 100 * 0.02953 * 100) / 100 : null;

  const now = new Date().toISOString();
  const observedAt = obs.timestamp || now;

  return {
    dirDeg: Math.round(dirDeg),
    speedMph,
    speedKts,
    gustMph,
    gustKts,
    tempF,
    humidity: humidity !== null ? Math.round(humidity) : null,
    pressureInHg,
    observedAt,
    fetchedAt: now,
    source: "noaa",
    station: {
      name: stationName,
      lat: LAT,
      lon: LON,
    },
    error: null,
  };
}

async function main() {
  const accessToken = (await credential.getAccessToken()).access_token;
  const weather = await fetchNoaa();

  console.log(`\n  Wind: ${weather.speedKts} kts from ${weather.dirDeg}°`);
  console.log(`  Gust: ${weather.gustKts ?? "none"} kts`);
  console.log(`  Temp: ${weather.tempF}°F`);
  console.log(`  Humidity: ${weather.humidity}%`);
  console.log(`  Pressure: ${weather.pressureInHg}" Hg`);

  await writeDoc(accessToken, "weather", "mpyc_station", weather);
  console.log("\n✓ Weather data written to weather/mpyc_station");
  process.exit(0);
}

main().catch((err) => {
  console.error("Failed:", err.message);
  process.exit(1);
});
