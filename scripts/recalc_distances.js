// Recalculate mark distances and headings from the new buoy coordinates
// and update courses_seed.json

const fs = require("fs");
const path = require("path");

const seedPath = path.join(__dirname, "..", "assets", "courses_seed.json");
const data = JSON.parse(fs.readFileSync(seedPath, "utf8"));

// Only marks with coordinates
const fixedMarks = data.marks.filter((m) => m.latitude && m.longitude);

function toRad(deg) { return deg * Math.PI / 180; }
function toDeg(rad) { return rad * 180 / Math.PI; }

// Haversine distance in nautical miles
function distNm(lat1, lon1, lat2, lon2) {
  const R = 3440.065; // Earth radius in NM
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
}

// Initial bearing in degrees (magnetic ≈ true for this area, ~13° E variation)
function bearing(lat1, lon1, lat2, lon2) {
  const dLon = toRad(lon2 - lon1);
  const y = Math.sin(dLon) * Math.cos(toRad(lat2));
  const x = Math.cos(toRad(lat1)) * Math.sin(toRad(lat2)) -
    Math.sin(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.cos(dLon);
  let brg = toDeg(Math.atan2(y, x));
  return (brg + 360) % 360;
}

const distances = [];

for (const from of fixedMarks) {
  for (const to of fixedMarks) {
    if (from.id === to.id) continue;
    const d = distNm(from.latitude, from.longitude, to.latitude, to.longitude);
    const h = bearing(from.latitude, from.longitude, to.latitude, to.longitude);
    distances.push({
      from: from.id,
      to: to.id,
      distance: Math.round(d * 100) / 100,
      heading: Math.round(h),
    });
  }
}

// Replace mark_distances in seed data
data.mark_distances = distances;

fs.writeFileSync(seedPath, JSON.stringify(data, null, 2) + "\n");
console.log(`Recalculated ${distances.length} mark distances from ${fixedMarks.length} marks.`);

// Print a summary table
console.log("\nMark distances:");
for (const d of distances) {
  console.log(`  ${d.from.padEnd(4)} → ${d.to.padEnd(4)}  ${String(d.distance).padStart(5)} NM  ${String(d.heading).padStart(3)}°`);
}
