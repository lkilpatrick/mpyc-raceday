# MPYC RaceSheet

<p align="center">
  <img src="assets/images/burgee.png" alt="MPYC Burgee" width="140" />
</p>

<h3 align="center">The complete digital race management platform for<br/><strong>Monterey Peninsula Yacht Club</strong></h3>

<p align="center">
  <em>From the starting horn to the final score — every aspect of race day, in the palm of your hand.</em>
</p>

---

## What Is MPYC Race Day?

MPYC Race Day is a **purpose-built, real-time race management system** that transforms how our club runs sailboat racing. It replaces clipboards, paper sign-ins, VHF confusion, and post-race spreadsheets with a single, beautiful platform that connects everyone — from the Race Committee on the water to skippers at the helm, crew on the rail, and spectators on the dock.

**One app. Every role. Every race.**

- **Race Committee** gets a digital command center — course selection with live wind data, automated start sequences with horn detection, one-tap finish recording, and instant score publishing to Clubspot.
- **Skippers** get GPS-tracked race mode, remote check-in with souls on board, a synced countdown timer, one-tap protest filing with automatic weather and GPS capture, and a virtual protest flag.
- **Crew** get a role-specific dashboard, safety and MOB procedures, synced race timer, and post-race sign-off.
- **Onshore spectators** get a live leaderboard with corrected times updating in real time, a notice board, weather hub, and access to GPS race replays.

The **web dashboard** gives RC Chairs, Club Board members, and Admins full control over the season — calendar management, crew assignments, course configuration, fleet management, incident review, maintenance tracking, weather analytics, and Clubspot integration.

### By the Numbers

| | |
|---|---|
| **57** courses across 6 wind groups | **13** race marks mapped and diagrammed |
| **4** fleet classes (Santana 22, Shields, PHRF A, PHRF B) | **5** user roles with granular access |
| **4** mobile modes (RC, Skipper, Crew, Onshore) | **11+** weather stations (NOAA, CO-OPS, WU, Ambient) |
| **Real-time** Firestore sync across all devices | **1-minute** weather updates from NOAA |

---

## Mobile App — 4 Modes, 1 App

The mobile app adapts its entire interface based on your role. Switch modes anytime from the mode bar at the top of every screen.

### Race Committee Mode

Everything the RC needs to run a race from the committee boat.

- **Guided Race Flow (Stepper)** — A 6-step guided workflow: Setup → Check-In → Start → Running → Scoring → Review. Each step has a dedicated UI with status tracking and state machine transitions.
- **Multi-Fleet Course Selection & Broadcast** — Assign separate courses to up to 4 fleets. Choose from 57 courses filtered by live wind direction. One tap broadcasts all fleet course assignments via push notification. Per-fleet course dropdowns with fleet renaming and VHF channel broadcast.
- **Start Sequence & Horn Detection** — Automated countdown with flag state tracking. Microphone-based horn detection to sync timing automatically. "Advance to Next Signal" button to skip the timer forward to the next signal point (4:00 prep, 1:00 prep down, 0:00 start).
- **Shorten Course & Abandon Race** — Solid, high-contrast teal and red buttons on the start sequence screen. Sends fleet-wide broadcasts automatically.
- **Finish Line Recording** — Big, tactile "FINISH" button. Each tap locks in a boat's crossing time with sail number entry. Supports OCS, DNS, DNF, DSQ, and RET letter scores with undo.
- **Live Race Map** — Real-time boat positions on a map during the race with boat count badge and abandon/scoring actions.
- **Race Check-In Management** — See which boats have checked in (including remote GPS check-ins from skippers), souls on board counts, and boats still missing.
- **Scoring & Results** — View corrected times (PHRF), publish results, and push scores to Clubspot.
- **Race History** — Browse finalized and abandoned race sessions with review and export status.
- **Fleet Broadcast** — Send course changes, postponements, or general recalls to the fleet instantly.
- **Incident Management** — Review and manage on-water incidents and protests filed by skippers and crew.
- **Live Weather** — Wind speed, direction, gusts, temperature, humidity, and barometric pressure from multiple stations.

### Skipper Mode

Streamlined race-day workflow for the person in charge of the boat.

- **Persistent Weather Header** — Wind direction (° + compass), speed (kts), gust, temperature, and data freshness visible on every skipper screen. Taps through to full weather detail.
- **Smart Home Screen** — Active race status card with contextual actions (Check In / View Race / View Results), quick-action buttons (Protest, Results, Rules), and recent results preview.
- **Check-In with GPS Auto-Start** — Check in to the active race session. GPS tracking starts automatically upon check-in and writes your initial position to the live positions feed.
- **Race Mode (RC-Synced Timer)** — Timer starts automatically when RC marks the race as running — no manual sync needed. Shows elapsed time from the official start timestamp, not device time. Stats: speed, max speed, distance (NM), track points.
- **GPS Tracking** — High-accuracy position stream (5m distance filter) publishing to `live_positions` every 5 seconds during the race, 15 seconds pre-start. Wakelock keeps the screen on.
- **Finish Zone Detection** — When within the configurable finish zone radius, the Finish Race button becomes prominent. Finish stops tracking and updates check-in status. Track upload to `race_tracks` with full metadata.
- **DNF / Withdraw** — One-tap retire with confirmation. Marks DNF, stops tracking immediately.
- **Auto-Stop on Abandon** — If RC abandons the race, tracking stops automatically.
- **Incident / Protest Filing** — Type selector (Protest / Incident / Note), auto-captures GPS position, weather snapshot, current race event, and time. Location on course picker, other boat sail numbers, description. Sends to RC for review.
- **Results Review** — Browse recent race results with expandable finish tables. Your boat highlighted with "(You)" label. Shows position, elapsed time, and letter score.
- **Racing Rules Reference** — Quick reference: Part 2 basics, mark-room, starting, penalties, protests, and MPYC club notes.

### Crew Mode

Ultra-minimal, distraction-free interface for everyone on the boat who isn't the skipper.

- **Crew Profile** — Set your name, select your boat, and choose your position from 15 options: Tactician, Navigator, Main trimmer, Jib/Genoa trimmer, Spinnaker trimmer, Spinnaker hoist/douse, Pit, Mast, Bow, Helm (non-skipper), Rail/ballast, Floater, Grinder, Watch/lookout, or Spectator (on boat). Saved to `crew_profiles` and attached to incident reports.
- **Persistent Weather Header** — Same compact weather bar as Skipper mode — wind arrow, speed, gust, direction, temp, freshness — visible on every crew screen.
- **Huge Race Timer** — Dominant 80pt monospace timer bound to the official RC start time. Shows correct elapsed time even if the app is opened mid-race. States: "No active race", pre-start status (Setting up / Check-in open / Start pending), live count-up with green "RACING" badge, "Race Abandoned" (red), "Race Complete" (green).
- **Incident / Protest Filing** — Same form as Skipper but tagged with crew role, position, and boat. Auto-captures GPS, weather, race event, and time. Submissions clearly marked as coming from crew.
- **Racing Rules Reference** — Full rules quick reference accessible from the bottom nav.
- **Locked-Down Navigation** — Only 3 tabs: Home, Rules, More. No chat, no map, no leaderboard, no check-in, no scoring, no checklists, no maintenance.

### Onshore / Spectator Mode

Follow the racing from the dock, the clubhouse, or anywhere — no login required for read-only data.

- **Live Weather Card** — Wind speed/direction with compass arrow, gust, temperature, humidity, station name, and freshness indicator ("2m ago" / orange "Stale" badge). Taps through to full weather detail.
- **Next Event Card** — Upcoming race from `race_events` with name, date ("Today" highlight), status badge mapped to all race session states (setup → finalized/abandoned), course info, and a live race elapsed clock when running.
- **Live Leaderboard Card** — Streams `finish_records` ordered by position. Shows top 8 finishes with position, sail number, boat name, elapsed time, and trophy icons for podium. "LIVE" badge when race is active. Falls back to "No active race" / "Race In Progress" / "No results" empty states.
- **Live Race Map Card** — Real-time boat positions from `live_positions` on a Flutter Map. Stale detection (>60s = grey marker + age label), speed display, RC vs boat color coding. Course marks from `marks` collection. Live boat count badge.
- **Mode-Aware Race Banner** — When a race is active, a green "RACE IN PROGRESS" banner appears with a "Watch Live" button (instead of the RC's red Timing/Check-In banner).
- **Weather Hub** — Full weather station feed from the club's location — wind, temperature, humidity, pressure.

### Shared Features (All Modes)

- **Mode Switcher** — Tap the mode indicator bar at the top of any screen to switch between RC, Skipper, Crew, and Onshore modes. Mode persists to Firestore. Each mode has fully isolated bottom nav routes to prevent shell/standalone route conflicts.
- **Racing Rules Reference** — Complete Racing Rules of Sailing database with search, quick reference chips, browse by Part/Section, bookmarks, recent lookups, and adjustable text size.
- **Situation Advisor** — Step-by-step guide through crossing, overtaking, mark rounding, start line, tacking/gybing, and obstruction encounters with applicable rules and explanations.
- **Profile** — View your roles, member number, membership status, emergency contact, notification preferences, and Clubspot member portal link.
- **Home Screen** (RC/Onshore) — Current weather with wind arrow, your boat info with photo upload, today's race status, upcoming races, last 2 race results, and maintenance alerts.

---

## Web Dashboard

The command center for race management, accessible to RC Chairs, Club Board, and Admins.

### Admin Dashboard
- **At-a-Glance Metrics** — Next race countdown, open maintenance requests, season progress, active member count.
- **Live Wind Widget** — Embedded real-time wind display from NOAA station data.
- **Upcoming Events** — Next 5 race events with status and crew fill indicators.
- **Activity Feed** — Recent actions across the platform (check-ins, incidents, maintenance, crew changes).
- **Attention Needed** — Critical maintenance items, events needing crew, and unresolved incidents.

### Season Calendar & Events
- **Full Race Calendar** — Visual calendar with all race events, color-coded by series.
- **CSV Import** — Bulk import race schedules from spreadsheet.
- **Series Management** — Create and manage race series (Spring, Summer, Fall, etc.).
- **Event Detail** — Per-event management: crew assignment, course selection, check-in status, weather history, timing, and results.

### Crew Management
- **Crew Assignment** — Drag-and-drop crew assignment to race committee roles.
- **Availability Tracking** — Members can indicate availability for upcoming events.
- **Role-Based Assignment** — Assign specific RC roles (PRO, Timer, Pin Boat, etc.).
- **CSV Download** — Export crew rosters.

### Course Configuration
- **57 Courses** across 6 wind groups with color coding (S/SW red, W blue, NW green, N amber, Inflatable purple, Long teal).
- **Course Builder (List-Reorder UI)** — Build courses mark-by-mark inside the Edit Course modal. Add marks from a catalog, reorder via Move Up/Down buttons, set Port (red) / Starboard (green) rounding per leg, choose finish type (Committee Boat or Club Mark). Two-column layout with live preview panel.
- **Live Course Diagram** — Read-only map preview updates in real time as marks are added, removed, or reordered. Polyline with labeled mark pins, Start (S) and Finish (F) indicators.
- **Auto Distance Calculation** — Total distance in nautical miles computed automatically via haversine great-circle formula. Updates on every sequence change. "Auto" badge on the distance field.
- **Structured Course Data** — Courses stored as ordered `CourseLeg[]` with `markId`, `rounding`, and `order`. Legacy description string (`START - Xp - 1s - FINISH`) auto-generated on save for backward compatibility.
- **Interactive Course Diagrams** — North-up orientation, mark-type icons (permanent, government, harbor, inflatable), leg arrows, START/FINISH rectangles.
- **13 Race Marks** — Full mark management with codes, types, and coordinates.
- **Distance Matrix** — 56 mark-to-mark distances for course length calculation.
- **Wind-Based Recommendations** — Courses automatically recommended based on current wind direction.
- **Seed Data** — One-click seeding of all course data from JSON.

### Fleet & Boat Management
- **Master Fleet List** — All registered boats with sail number, name, owner, class, PHRF rating.
- **Class Filtering** — Filter by Santana 22, Shields, PHRF A, PHRF B, RC Fleet.
- **RC Fleet Flag** — Mark boats as Race Committee fleet vessels.
- **CSV Import** — Bulk import fleet data.
- **Boat Profiles** — Individual boat records with race history and GPS tracks.

### Checklists
- **Template Builder** — Create checklist templates with sections and items.
- **Completion Tracking** — Real-time progress as crew complete checklists on mobile.
- **Compliance Dashboard** — See which checklists are complete, in progress, or overdue.
- **History** — Full audit trail of all checklist completions.

### Incidents & Protests
- **Incident Review** — All reported incidents with status workflow (Reported → Protest Filed → Hearing Scheduled → Hearing Complete → Resolved).
- **Smart Create Dialog** — Event picker, course picker with dynamic mark-based locations, boat picker from fleet, weather auto-populate.
- **Protest Form Generator** — US Sailing Hearing Request Form generation with pre-filled data from the situation advisor.
- **Weather Snapshot** — Automatic capture of wind, temperature, humidity, and pressure at time of incident.
- **GPS Location** — Incidents filed from mobile include the skipper's GPS position.

### Maintenance
- **Request Management** — Track maintenance requests with priority (Critical, High, Medium, Low) and status (Open, In Progress, Complete).
- **Photo Attachments** — Visual documentation of issues.
- **Scheduled Maintenance** — Recurring maintenance task management.
- **Critical Alerts** — Critical items surface on the dashboard and mobile home screen.

### Fleet Broadcasts & Notifications
- **SMS Notifications** — Course selection, fleet broadcasts, and urgent notices via SMS.
- **Email Notifications** — Crew assignments, reminders, maintenance updates, incident notifications, weekly summaries.
- **Push Notifications (FCM)** — Real-time push to all mobile devices.
- **Targeted Broadcasts** — Send to specific fleets, all racers, or the entire club.

### Weather System
- **Multi-Source Weather** — Data from 11+ stations: NOAA (KMRY, KOAR), CO-OPS (Monterey Harbor), Weather Underground (8 PWS), AmbientWeather (club station).
- **1-Minute Updates** — Cloud Function fetches fresh data every 60 seconds.
- **Per-Event Weather Logs** — Historical weather data tied to each race event.
- **Station Map** — All weather stations plotted on an interactive map.
- **Fallback Logic** — If the primary station goes stale, the system automatically falls back to the best available source.

### Reports & Analytics
- **Season Summaries** — Participation stats, race counts, series standings.
- **Member Activity** — Track engagement across the season.
- **Weather Analytics** — Wind patterns and conditions across race days.

### Member Management
- **Clubspot Sync** — Daily automatic sync of member data from Clubspot API (names, contact info, membership status, tags).
- **Role Assignment** — Assign web_admin, club_board, rc_chair, skipper, or crew roles.
- **Member Portal** — Direct link to each member's Clubspot portal.
- **Score Push** — Push finish times to Clubspot for official scoring.

---

## Role-Based Access

| Role | Mobile | Web | Description |
|------|--------|-----|-------------|
| **web_admin** | All modes | Full access | System administrator — inherits all roles |
| **club_board** | All modes | Dashboard, Reports, Members | Club governance and oversight |
| **rc_chair** | RC + Skipper modes | Dashboard, Calendar, Crew, Courses, Checklists, Incidents, Fleet, Broadcasts | Race operations lead |
| **skipper** | Skipper + Crew modes | — | Boat captain — race features, maintenance reporting |
| **crew** | Crew + Onshore modes | — | Crew member — basic mobile access |

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                       Flutter App                             │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────────┐  │
│  │   Mobile     │  │    Web      │  │    Shared Layer      │  │
│  │  4 Modes     │  │  Dashboard  │  │  Models / Repos /    │  │
│  │  Adaptive UI │  │  11+ Pages  │  │  Providers / Services│  │
│  └─────────────┘  └─────────────┘  └──────────────────────┘  │
│         Riverpod 3.x State Management                         │
│         GoRouter Navigation (mobile shell + web shell)        │
└────────────────────────┬─────────────────────────────────────┘
                         │
              ┌──────────▼──────────┐
              │   Firebase Backend   │
              │  ┌────────────────┐  │
              │  │   Firestore    │  │  25+ collections: members, race_events,
              │  │                │  │  courses, marks, weather, incidents,
              │  │                │  │  race_tracks, crew_chats, boat_checkins,
              │  │                │  │  maintenance_requests, fleets, notices...
              │  ├────────────────┤  │
              │  │ Cloud Functions│  │  Weather fetch (11 stations, 1 min),
              │  │                │  │  Clubspot sync, SMS/email/push
              │  ├────────────────┤  │
              │  │   Storage      │  │  Boat photos, attachments
              │  ├────────────────┤  │
              │  │  Auth / FCM    │  │  Verification code login, push
              │  └────────────────┘  │
              └─────────────────────┘
```

### Tech Stack

- **Flutter 3.x** — Dart, Material 3, single codebase for Android, iOS, and Web
- **Firebase** — Firestore, Auth, Cloud Functions, Hosting, Storage, FCM
- **Riverpod 3.x** — reactive state management with StreamProviders
- **GoRouter** — declarative routing with mode-specific shell routes (RC, Skipper, Crew, Onshore each with unique tab paths)
- **Geolocator** — high-accuracy GPS tracking for race mode and check-ins
- **NOAA / CO-OPS / Weather Underground / AmbientWeather** — multi-source weather via Cloud Functions
- **Clubspot API** — member sync, score push, member portal sessions, billing data
- **Wakelock Plus** — keeps screen on during race timing and GPS tracking

---

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.10
- Node.js ≥ 18 (for Cloud Functions and seed scripts)
- Firebase CLI (`npm install -g firebase-tools`)
- A Firebase project with Firestore, Auth, Functions, Storage, and Hosting enabled

### Setup

```bash
# Clone
git clone https://github.com/lkilpatrick/mpyc-raceday.git
cd mpyc-raceday

# Install Flutter dependencies
flutter pub get

# Install Cloud Functions dependencies
cd functions && npm install && cd ..

# Firebase login and project selection
firebase login
firebase use mpyc-raceday
```

### Environment

Create a `.env` file in the project root (optional, for Clubspot API):
```
CLUBSPOT_API_KEY=your_key_here
```

Optional weather station API keys (set in Firestore `weather/config` doc):
- `wuApiKey` — Weather Underground API key (enables 8 additional PWS stations)
- `ambientAppKey` + `ambientApiKey` — AmbientWeather REST API keys (enables club station direct feed)

### Seed Data

Populate Firestore with race marks, courses, wind groups, and fleets:
```bash
node scripts/seed_courses.js
```

### Run

```bash
# Mobile (Android emulator or device)
flutter run

# Web
flutter run -d chrome

# Build Android APK
flutter build apk

# Build for web deployment
flutter build web --no-tree-shake-icons
```

### Deploy

```bash
# Deploy web app to Firebase Hosting
firebase deploy --only hosting

# Deploy Cloud Functions
firebase deploy --only functions

# Deploy Firestore rules and indexes
firebase deploy --only firestore
```

---

## Project Structure

```
lib/
├── core/                       # Theme, error handling, constants
├── features/
│   ├── admin/                  # Web dashboard, member management, system settings
│   ├── app_mode/               # Mobile mode system (RC, Skipper, Crew, Onshore)
│   │   ├── data/               #   AppMode enum, provider, Firestore persistence
│   │   └── presentation/       #   Mode switcher, RC timing, spectator (4 live cards),
│   │       └── mobile/         #   leaderboard, mode nav config
│   ├── skipper/                # Skipper mode: home, check-in, race, results, incidents
│   │   └── presentation/       #   WeatherHeader widget, 5 screens
│   ├── crew/                   # Crew mode: home (timer), profile, incidents
│   │   └── presentation/       #   3 screens, ultra-minimal nav
│   ├── rc_race/                # Guided RC race flow: 6-step stepper + history
│   │   ├── data/               #   RaceSession model with status state machine
│   │   └── presentation/       #   Setup, Check-in, Start, Running, Scoring, Review steps
│   ├── auth/                   # Login, verification, roles, member model, profile
│   ├── boat_checkin/           # Fleet management, event check-ins (RC + skipper)
│   ├── checklists/             # Templates, active completion, history, compliance
│   ├── courses/                # 57 courses, 13 marks, diagrams, wind groups, selection
│   ├── crew_assignment/        # Calendar, availability, event detail, CSV export
│   ├── home/                   # Home screen (weather, boat, races), more screen
│   ├── incidents/              # Incident reporting, protest workflow, form generator
│   ├── maintenance/            # Request management, scheduling, photo attachments
│   ├── race_mode/              # Legacy GPS track recording (used by skipper race screen)
│   ├── racing_rules/           # RRS database, search, situation advisor, protest filing
│   ├── reporting/              # Combined protest + maintenance mobile reporting
│   ├── reports/                # Season reports and analytics (web)
│   ├── timing/                 # Start sequence, finish recording, results, scoring
│   └── weather/                # Multi-source weather, live providers, history, map
├── mobile/                     # Mobile shell (mode-aware), router, bottom nav
├── shared/                     # Shared models, services, widgets, web utils
├── web/                        # Web shell, router, sidebar, scaffold
├── firebase_options.dart
└── main.dart

functions/src/                  # Cloud Functions
scripts/                        # Seed scripts (courses, admin, calendar)
assets/
├── courses_seed.json           # 57 courses, 13 marks, 56 distances, 6 wind groups, 4 fleets
├── racing_rules.json           # Complete Racing Rules of Sailing reference
└── images/                     # Burgee, club assets
```

---

## Cloud Functions

| Function | Trigger | Description |
|----------|---------|-------------|
| `scheduledWeatherFetch` | Every 1 min | Fetches from NOAA, CO-OPS, Weather Underground, and AmbientWeather → writes to `weather/stations/observations/*` and `weather/mpyc_station` |
| `syncClubspotMembers` | Daily / manual | Syncs member data from Clubspot API → `members` collection (preserves roles and local fields) |
| `sendVerificationCode` | HTTPS callable | Multi-field lookup (signal #, membership #, email) → sends verification code for mobile login |
| `pushScoresToClubspot` | HTTPS callable | Pushes finish times to Clubspot Scores API |

---

## Data Flow

### Weather (Multi-Source)
```
NOAA / CO-OPS / WU / Ambient → Cloud Function (1 min) → Firestore → StreamProvider → UI
                                                        ↓
                                              Fallback: if primary stale >90s,
                                              copies best available to mpyc_station
```

### Race Mode GPS Tracking
```
Phone GPS (high accuracy, 5m filter) → TrackPoint list → "Finish" → Upload to Firestore race_tracks
                                                                      ↓
                                                          Tagged with: event, course, date,
                                                          boat name, sail #, class, stats
```

### Protest Filing (from Situation Advisor)
```
Encounter type → Sub-questions → Applicable rules → "File Protest"
                                                      ↓
                                          Auto-captures: GPS position, weather snapshot,
                                          today's event + course, timestamp
                                                      ↓
                                          Creates incident in Firestore with status: protestFiled
```

### Notifications
```
App action → Firestore trigger → Cloud Function → SMS (sms collection) / Email (mail collection) / FCM Push
```

### Clubspot Integration
```
Clubspot API ←→ Cloud Functions ←→ Firestore
  Members (daily sync) →  members collection
  Scores (race results) ← finish_records → POST /v1/scores
  Member Portal         ← POST /v1/member-portal/sessions
```

---

## Scripts

| Script | Usage | Description |
|--------|-------|-------------|
| `scripts/seed_courses.js` | `node scripts/seed_courses.js` | Seeds marks, distances, wind groups, fleets, and 57 courses |
| `scripts/seed_admin.js` | `node scripts/seed_admin.js` | Creates initial admin user |
| `scripts/seed_calendar.js` | `node scripts/seed_calendar.js` | Imports race calendar from CSV |

---

## What's Next

- **Background GPS Tracking** — Foreground service for continuous position publishing even when the app is backgrounded
- **Offline Position Queue** — Queue GPS updates locally when offline and flush when reconnected
- **Finish Line Geofence** — Line-segment finish detection (two coordinates) instead of radius-based zone
- **Course Builder v2** — Drag-and-drop reorder, rounding arrows on map preview, duplicate leg action, keyboard shortcuts
- **US Sailing / PHRF Certificate Sync** — Pull handicap ratings and certifications automatically
- **Race Replay Viewer** — Animated playback of GPS tracks on the course diagram
- **Crew Weight Tracker** — Class compliance weight tracking for one-design fleets
- **Photo Attachments on Incidents** — Allow photo upload with protest/incident submissions

---

## License

Private — Monterey Peninsula Yacht Club. Not for redistribution.
