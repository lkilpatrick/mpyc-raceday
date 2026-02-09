// Seed checklist templates into Firestore
// Usage: node scripts/seed_checklists.js

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

function addOrder(items) {
  return items.map((item, i) => ({ ...item, order: i + 1 }));
}

async function seed() {
  const accessToken = (await credential.getAccessToken()).access_token;

  // ── Shared base items (all power boats) ──
  const baseSafetyItems = [
    {id: "s1", title: "VHF radio check", description: "Test transmit/receive on Ch 16 and race channel", category: "Safety Equipment", isCritical: true, requiresPhoto: false, requiresNote: false},
    {id: "s2", title: "First aid kit", description: "Verify kit is stocked and accessible", category: "Safety Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "s3", title: "Fire extinguisher", description: "Check gauge is in green zone, pin intact", category: "Safety Equipment", isCritical: true, requiresPhoto: false, requiresNote: false},
    {id: "s4", title: "Flares — check expiry", description: "Verify flares are within expiration date", category: "Safety Equipment", isCritical: false, requiresPhoto: false, requiresNote: true},
    {id: "s5", title: "Life jackets — count and condition", description: "Count PFDs, inspect for damage", category: "Safety Equipment", isCritical: true, requiresPhoto: false, requiresNote: true},
    {id: "s6", title: "Throwable PFD", description: "Verify throwable device is accessible", category: "Safety Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "s7", title: "Sound signal device", description: "Test horn/whistle", category: "Safety Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "s8", title: "Navigation lights test", description: "Test all nav lights (red, green, white stern, masthead)", category: "Safety Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},
  ];

  const baseVesselItems = [
    {id: "v1", title: "Fuel level", description: "Check fuel gauge/dipstick, note level", category: "Vessel Systems", isCritical: false, requiresPhoto: true, requiresNote: true},
    {id: "v2", title: "Engine oil level", description: "Check dipstick, top off if below min line", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: true},
    {id: "v3", title: "Engine coolant level", description: "Check coolant reservoir, verify level between min/max", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "v4", title: "Engine start and run check", description: "Start engine, let idle 2 min, check gauges (oil pressure, temp, voltage)", category: "Vessel Systems", isCritical: true, requiresPhoto: false, requiresNote: false},
    {id: "v5", title: "Raw water flow / tell-tale", description: "Verify cooling water discharge from exhaust", category: "Vessel Systems", isCritical: true, requiresPhoto: false, requiresNote: false},
    {id: "v6", title: "Steering check", description: "Turn wheel/tiller full lock to lock, check for binding", category: "Vessel Systems", isCritical: true, requiresPhoto: false, requiresNote: false},
    {id: "v7", title: "Throttle and shift check", description: "Verify smooth forward/neutral/reverse shifting at dock", category: "Vessel Systems", isCritical: true, requiresPhoto: false, requiresNote: false},
    {id: "v8", title: "Bilge pump test", description: "Test bilge pump operation (auto and manual switch)", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "v9", title: "Battery voltage check", description: "Check battery voltage (should be 12.6V+ at rest, 13.5V+ charging)", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: true},
    {id: "v10", title: "Electrical panel check", description: "Verify all circuits functioning, no tripped breakers", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "v11", title: "Through-hulls — verify position", description: "Check all through-hull fittings are open/closed as needed", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "v12", title: "Anchor and rode", description: "Check anchor, shackle pin wired, rode flaked and ready", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "v13", title: "Mooring lines", description: "Inspect dock lines for chafe and wear", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "v14", title: "Prop check (visual)", description: "Look over the side — no lines/debris on prop", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: false},
  ];

  const baseCommsItems = [
    {id: "c1", title: "VHF Ch 16 test call", description: "Radio check on Ch 16 with another station", category: "Communications", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "c2", title: "Race committee channel test", description: "Radio check on race channel (Ch 72 or club-specific)", category: "Communications", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "c3", title: "Cell phone backup charged", description: "Verify backup phone is charged and in waterproof case", category: "Communications", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "c4", title: "Contact list aboard", description: "PRO, harbormaster, Coast Guard, club office contacts available", category: "Communications", isCritical: false, requiresPhoto: false, requiresNote: false},
  ];

  const baseNavItems = [
    {id: "n1", title: "GPS/chartplotter operational", description: "Power on, verify GPS fix and chart display", category: "Navigation", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "n2", title: "Compass check", description: "Verify compass is functional and reads correctly", category: "Navigation", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "n3", title: "Depth sounder", description: "Verify depth sounder reading", category: "Navigation", isCritical: false, requiresPhoto: false, requiresNote: false},
  ];

  // ── Signal Boat (RC / Committee Boat) specific items ──
  const signalBoatRaceItems = [
    {id: "r1", title: "Signal flags — full set inventory", description: "Verify all required flags: AP, N, 1st Sub, class flags, P, I, Z, Black, S, L, M, Y, X", category: "Race Equipment", isCritical: true, requiresPhoto: false, requiresNote: false},
    {id: "r2", title: "Starting horn / sound signal", description: "Test starting horn — verify audible at 200m+", category: "Race Equipment", isCritical: true, requiresPhoto: false, requiresNote: false},
    {id: "r3", title: "Course board/display", description: "Verify course board is clean, dry-erase markers available", category: "Race Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "r4", title: "Binoculars", description: "Clean lenses, verify working — need 2 pairs minimum", category: "Race Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "r5", title: "Stopwatches/timing equipment", description: "Test timing equipment, fresh batteries, sync all clocks", category: "Race Equipment", isCritical: true, requiresPhoto: false, requiresNote: false},
    {id: "r6", title: "Finish line transit poles", description: "Check finish line transit poles/sighting equipment", category: "Race Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "r7", title: "Race instructions copies aboard", description: "Current Sailing Instructions copies available for crew", category: "Race Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "r8", title: "Protest flags (red) available", description: "Verify spare protest flags available for competitors", category: "Race Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "r9", title: "Wind indicator / Windex", description: "Verify wind indicator at masthead is functional", category: "Race Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "r10", title: "Scoring sheets / clipboard", description: "Blank scoring sheets, pencils, clipboard ready", category: "Race Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},
  ];

  // ── Mark Boat specific items ──
  const markBoatItems = [
    {id: "mb1", title: "Race marks aboard — count", description: "Verify all required marks are aboard (windward, leeward, gate, offset)", category: "Mark Setting", isCritical: true, requiresPhoto: false, requiresNote: true},
    {id: "mb2", title: "Mark anchors and rode", description: "Check all mark anchors, shackles, and rode — no tangles", category: "Mark Setting", isCritical: true, requiresPhoto: false, requiresNote: false},
    {id: "mb3", title: "Mark lights (if applicable)", description: "Test mark lights for dusk racing", category: "Mark Setting", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "mb4", title: "Inflatable marks — check inflation", description: "Verify inflatable marks are fully inflated, no leaks", category: "Mark Setting", isCritical: false, requiresPhoto: true, requiresNote: false},
    {id: "mb5", title: "Spare marks and anchors", description: "Verify spare mark and anchor aboard", category: "Mark Setting", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "mb6", title: "Mark retrieval gaff/hook", description: "Gaff or hook for mark retrieval is aboard", category: "Mark Setting", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "mb7", title: "GPS waypoints loaded", description: "Verify course mark GPS waypoints are loaded in chartplotter", category: "Mark Setting", isCritical: false, requiresPhoto: false, requiresNote: false},
  ];

  // ── Safety Boat specific items ──
  const safetyBoatItems = [
    {id: "sb1", title: "Tow line — 50ft minimum", description: "Verify tow line is aboard, no chafe, proper length", category: "Rescue Equipment", isCritical: true, requiresPhoto: false, requiresNote: false},
    {id: "sb2", title: "Rescue knife", description: "Sharp rescue knife accessible to helmsman", category: "Rescue Equipment", isCritical: true, requiresPhoto: false, requiresNote: false},
    {id: "sb3", title: "Throw bag", description: "Throw bag accessible and line flaked", category: "Rescue Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "sb4", title: "Swim ladder / boarding aid", description: "Verify swim ladder deploys properly for MOB recovery", category: "Rescue Equipment", isCritical: true, requiresPhoto: false, requiresNote: false},
    {id: "sb5", title: "Thermal blankets", description: "Thermal/emergency blankets aboard for hypothermia", category: "Rescue Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "sb6", title: "Paddle / oar", description: "Emergency paddle aboard", category: "Rescue Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "sb7", title: "Bolt cutters (for rigging)", description: "Bolt cutters aboard for rigging emergencies", category: "Rescue Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "sb8", title: "Extra PFDs for rescued sailors", description: "Minimum 4 extra PFDs for rescued crew", category: "Rescue Equipment", isCritical: false, requiresPhoto: false, requiresNote: true},
    {id: "sb9", title: "Pump for swamped dinghies", description: "Manual or electric pump for bailing swamped boats", category: "Rescue Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},
  ];

  // ── Post-race items (shared) ──
  const postRaceSecureItems = [
    {id: "sv1", title: "Engine off / fuel valve closed", description: "Shut down engine, close fuel valve if equipped", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "sv2", title: "Lines secured — bow, stern, spring", description: "Secure all dock lines with proper cleating", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "sv3", title: "Fenders positioned", description: "Position fenders for overnight/weather", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "sv4", title: "Bilge check — pump if needed", description: "Check bilge, pump if water present, note amount", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "sv5", title: "Electrical panel — non-essential circuits off", description: "Turn off all non-essential electrical circuits, leave bilge pump on", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "sv6", title: "Battery switch position", description: "Set battery switch to correct position (off or charge)", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "sv7", title: "Cabin/console locked", description: "Lock cabin, console, and hatches", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "sv8", title: "Canvas/covers on", description: "Install canvas covers, snap all fasteners", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "sv9", title: "Wash down hull and deck", description: "Rinse salt water from hull, deck, and hardware", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false},
  ];

  const postRaceStowageItems = [
    {id: "es1", title: "Signal flags folded and stowed", description: "Fold and stow all signal flags in dry bag", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "es2", title: "Timing equipment secured", description: "Store timing equipment in dry, locked storage", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "es3", title: "Binoculars in case", description: "Return binoculars to padded case", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "es4", title: "Race documents collected", description: "Collect and file all race documents, scoring sheets", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "es5", title: "Course board cleared", description: "Clear and stow course board", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "es6", title: "Electronics powered down", description: "GPS, radio, instruments powered down", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false},
  ];

  const postRaceReportItems = [
    {id: "rh1", title: "Race results recorded/submitted", description: "Ensure race results are recorded and submitted to scoring", category: "Reporting & Handoff", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "rh2", title: "Incidents documented", description: "Document any incidents, protests, or injuries", category: "Reporting & Handoff", isCritical: false, requiresPhoto: false, requiresNote: true},
    {id: "rh3", title: "Maintenance issues reported", description: "Report any maintenance issues found during use", category: "Reporting & Handoff", isCritical: false, requiresPhoto: false, requiresNote: true},
    {id: "rh4", title: "Fuel level noted", description: "Record current fuel level for next crew", category: "Reporting & Handoff", isCritical: false, requiresPhoto: false, requiresNote: true},
    {id: "rh5", title: "Engine hours noted", description: "Record engine hour meter reading", category: "Reporting & Handoff", isCritical: false, requiresPhoto: false, requiresNote: true},
    {id: "rh6", title: "Next crew notified of issues", description: "Communicate any issues to next event's crew", category: "Reporting & Handoff", isCritical: false, requiresPhoto: false, requiresNote: true},
  ];

  // ── Safety inspection checklist ──
  const safetyInspectionItems = [
    {id: "si1", title: "Hull integrity — below waterline", description: "Inspect hull for cracks, blisters, osmosis, damage below waterline", category: "Hull & Structure", isCritical: true, requiresPhoto: true, requiresNote: true},
    {id: "si2", title: "Hull integrity — above waterline", description: "Inspect topsides for cracks, gelcoat damage, impact marks", category: "Hull & Structure", isCritical: false, requiresPhoto: true, requiresNote: true},
    {id: "si3", title: "Transom condition", description: "Check transom for soft spots, delamination near engine mount", category: "Hull & Structure", isCritical: true, requiresPhoto: true, requiresNote: false},
    {id: "si4", title: "Deck hardware secure", description: "Check all cleats, chocks, stanchions, rails for looseness", category: "Hull & Structure", isCritical: false, requiresPhoto: false, requiresNote: true},
    {id: "si5", title: "Non-skid deck condition", description: "Inspect non-skid surfaces for wear", category: "Hull & Structure", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "si6", title: "Fire extinguisher — current inspection", description: "Verify inspection tag is current, gauge in green", category: "USCG Requirements", isCritical: true, requiresPhoto: true, requiresNote: true},
    {id: "si7", title: "PFDs — USCG approved, correct count", description: "Verify correct number of USCG-approved PFDs for vessel capacity", category: "USCG Requirements", isCritical: true, requiresPhoto: false, requiresNote: true},
    {id: "si8", title: "Visual distress signals current", description: "Verify flares/signals are not expired", category: "USCG Requirements", isCritical: true, requiresPhoto: false, requiresNote: true},
    {id: "si9", title: "Sound producing device", description: "Horn or whistle functional", category: "USCG Requirements", isCritical: true, requiresPhoto: false, requiresNote: false},
    {id: "si10", title: "Navigation lights functional", description: "Test all required navigation lights", category: "USCG Requirements", isCritical: true, requiresPhoto: false, requiresNote: false},
    {id: "si11", title: "Registration/documentation current", description: "Verify vessel registration or documentation is current and aboard", category: "USCG Requirements", isCritical: true, requiresPhoto: true, requiresNote: true},
    {id: "si12", title: "Engine mounts secure", description: "Check engine mount bolts for tightness", category: "Engine & Mechanical", isCritical: true, requiresPhoto: false, requiresNote: false},
    {id: "si13", title: "Fuel system — no leaks", description: "Inspect fuel lines, connections, tank for leaks or corrosion", category: "Engine & Mechanical", isCritical: true, requiresPhoto: true, requiresNote: true},
    {id: "si14", title: "Exhaust system", description: "Inspect exhaust hose, clamps, and riser for leaks or deterioration", category: "Engine & Mechanical", isCritical: true, requiresPhoto: false, requiresNote: true},
    {id: "si15", title: "Battery secured and terminals clean", description: "Verify battery is secured, terminals clean and tight, no corrosion", category: "Electrical", isCritical: false, requiresPhoto: false, requiresNote: false},
    {id: "si16", title: "Wiring — no chafe or exposed conductors", description: "Inspect visible wiring for chafe, corrosion, loose connections", category: "Electrical", isCritical: false, requiresPhoto: true, requiresNote: true},
    {id: "si17", title: "Bilge pump operational", description: "Test bilge pump — auto float switch and manual", category: "Electrical", isCritical: true, requiresPhoto: false, requiresNote: false},
    {id: "si18", title: "Through-hulls — condition and operation", description: "Inspect all through-hulls, exercise seacocks, check for weeping", category: "Hull & Structure", isCritical: true, requiresPhoto: false, requiresNote: true},
    {id: "si19", title: "Steering system", description: "Inspect steering cables/hydraulics for wear, leaks, play", category: "Engine & Mechanical", isCritical: true, requiresPhoto: false, requiresNote: true},
    {id: "si20", title: "Propeller condition", description: "Inspect prop for dings, bent blades, fishing line wrap", category: "Engine & Mechanical", isCritical: false, requiresPhoto: true, requiresNote: true},
  ];

  const uid = "seed-script";

  // ── Duncan's Watch (Signal/Committee Boat) ──
  const dwPreItems = addOrder([...baseSafetyItems, ...signalBoatRaceItems, ...baseVesselItems, ...baseCommsItems, ...baseNavItems]);
  const dwPostItems = addOrder([...postRaceSecureItems, ...postRaceStowageItems, ...postRaceReportItems]);

  const templates = [
    { id: "pre_race_duncans_watch", name: "Duncan's Watch — Pre-Race Checkout", type: "preRace", items: dwPreItems },
    { id: "post_race_duncans_watch", name: "Duncan's Watch — Post-Race Securing", type: "postRace", items: dwPostItems },

    // Signal Boat
    { id: "pre_race_signal_boat", name: "Signal Boat — Pre-Race Checkout", type: "preRace",
      items: addOrder([...baseSafetyItems, ...signalBoatRaceItems, ...baseVesselItems, ...baseCommsItems, ...baseNavItems]) },
    { id: "post_race_signal_boat", name: "Signal Boat — Post-Race Securing", type: "postRace",
      items: addOrder([...postRaceSecureItems, ...postRaceStowageItems, ...postRaceReportItems]) },

    // Mark Boat
    { id: "pre_race_mark_boat", name: "Mark Boat — Pre-Race Checkout", type: "preRace",
      items: addOrder([...baseSafetyItems, ...markBoatItems, ...baseVesselItems, ...baseCommsItems, ...baseNavItems]) },
    { id: "post_race_mark_boat", name: "Mark Boat — Post-Race Securing", type: "postRace",
      items: addOrder([
        ...postRaceSecureItems,
        {id: "mb_es1", title: "Marks retrieved and stowed", description: "All race marks retrieved, dried, and stowed", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: true},
        {id: "mb_es2", title: "Mark anchors and rode coiled", description: "Coil and stow all mark anchor rode — no tangles", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false},
        {id: "mb_es3", title: "Inflatable marks deflated/stowed", description: "Deflate and stow inflatable marks if applicable", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false},
        ...postRaceReportItems,
      ]) },

    // Safety Boat
    { id: "pre_race_safety_boat", name: "Safety Boat — Pre-Race Checkout", type: "preRace",
      items: addOrder([...baseSafetyItems, ...safetyBoatItems, ...baseVesselItems, ...baseCommsItems, ...baseNavItems]) },
    { id: "post_race_safety_boat", name: "Safety Boat — Post-Race Securing", type: "postRace",
      items: addOrder([
        ...postRaceSecureItems,
        {id: "sb_es1", title: "Tow line inspected and coiled", description: "Inspect tow line for chafe, coil and stow", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false},
        {id: "sb_es2", title: "Rescue equipment stowed", description: "Stow throw bag, knife, blankets, extra PFDs", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false},
        ...postRaceReportItems,
      ]) },

    // Annual Safety Inspection
    { id: "safety_inspection", name: "Annual Safety Inspection", type: "safety",
      items: addOrder(safetyInspectionItems) },
  ];

  console.log(`Seeding ${templates.length} checklist templates...`);
  for (const t of templates) {
    await writeDoc(accessToken, "checklists", t.id, {
      name: t.name,
      type: t.type,
      items: t.items,
      version: 1,
      lastModifiedBy: uid,
      isActive: true,
    });
    console.log(`  ✓ ${t.name} (${t.items.length} items)`);
  }

  console.log(`\n=== Checklist Templates Seeded ===`);
  console.log(`  ${templates.length} templates`);
  console.log(`=================================\n`);
  process.exit(0);
}

seed().catch((err) => {
  console.error("Failed:", err.message);
  process.exit(1);
});
