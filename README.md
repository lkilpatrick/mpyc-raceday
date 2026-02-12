# MPYC Race Day

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
- **Crew** get a role-specific dashboard, boat-level crew chat, safety and MOB procedures, synced race timer, and post-race sign-off.
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

- **Course Selection & Broadcast** — Choose from 57 courses filtered by live wind direction. One tap broadcasts the course to the entire fleet via SMS and push notification.
- **Start Sequence & Horn Detection** — Automated 5-minute countdown with flag state tracking (Warning, Prep, Individual Recall). Listens for the horn to sync timing.
- **Finish Line Recording** — Big, tactile "FINISH" button. Each tap locks in a boat's crossing time with sail number entry. Supports OCS, DNS, DNF, DSQ, and RET letter scores.
- **Race Check-In Management** — See which boats have checked in (including remote GPS check-ins from skippers), souls on board counts, and boats still missing.
- **Scoring & Results** — View corrected times (PHRF), publish results, and push scores to Clubspot.
- **Fleet Broadcast** — Send course changes, postponements, or general recalls to the fleet instantly.
- **Incident Management** — Review and manage on-water incidents and protests filed by skippers.
- **Live Weather** — Wind speed, direction, gusts, temperature, humidity, and barometric pressure from multiple stations.

### Skipper Mode

Tactical tools for the person in charge of the boat.

- **Remote Race Check-In** — Check in to the race via GPS from anywhere on the water. Sends your position and souls on board count to the Race Committee digitally.
- **Race Mode (GPS Tracking)** — Hit "Start Race" and the app records your GPS track at high accuracy throughout the race. Hit "Finish" and the track is uploaded to your boat's profile, tagged with the event, course, and date — building a permanent record of every race.
- **Synced Countdown Timer** — Countdown timer synced with the RC's start sequence so you always know exactly where you are in the start.
- **Situation Advisor & Protest Filing** — Step-by-step dispute resolution walks you through the encounter type, details, and applicable Racing Rules of Sailing. When you're ready, tap "File Protest" — the app automatically captures your GPS position, current weather conditions, the event and course, timestamps everything, and creates the incident record. No paperwork.
- **Virtual Protest Flag** — Digitally hoist a protest flag, notifying the RC and the protested boat immediately.
- **Live Weather** — Real-time wind data to inform tactical decisions on the course.
- **Course Information** — View today's active course with mark sequence, distances, and diagram.

### Crew Mode

Communication and safety tools for everyone on the boat.

- **Crew Dashboard** — See your assigned role (Bow, Pit, Trimmer, etc.), your boat, and your skipper. The synced race timer and current leg keep everyone in sync with the boat's progress.
- **Crew Chat** — A dedicated messaging channel for your boat's crew. Coordinate dock-out times, post-race plans, or debrief after racing. Messages are organized by boat (sail number).
- **Safety & Emergency Info** — One-tap access to MOB (Man Overboard) quick-action procedure, Coast Guard and Harbor contacts, VHF channel reference, your emergency contact, and a pre-race safety equipment checklist.
- **Post-Race Sign-Off** — Confirm you are safely off the vessel and done for the day. Gives the club a digital record that all crew are accounted for.

### Onshore / Spectator Mode

Follow the racing from the dock, the clubhouse, or anywhere.

- **Live Leaderboard** — Real-time scoring updates as the RC records finishes. Shows elapsed time, corrected time (PHRF), and position — updating live as boats cross the line.
- **Race Status** — See if racing is in Setup, Active, or Complete, which course is set, and how many boats are on the water.
- **Notice Board** — Digital hub for club notices, daily schedules, social events, and announcements.
- **Weather Hub** — Full weather station feed from the club's location — wind, temperature, humidity, pressure.
- **Race Replay** — Access recorded GPS tracks from the day's racing for armchair coaching, performance review, and social sharing.

### Shared Features (All Modes)

- **Home Screen** — Current weather with wind arrow, your boat info with photo upload, today's race status, upcoming races, last 2 race results, and maintenance alerts.
- **Racing Rules Reference** — Complete Racing Rules of Sailing database with search, quick reference chips, browse by Part/Section, bookmarks, recent lookups, and adjustable text size.
- **Situation Advisor** — Step-by-step guide through crossing, overtaking, mark rounding, start line, tacking/gybing, and obstruction encounters with applicable rules and explanations.
- **Checklists** — Pre-race checklists with progress tracking and completion history.
- **Maintenance Reporting** — Report issues with photos, priority levels, and status tracking.
- **Profile** — View your roles, member number, membership status, emergency contact, notification preferences, and Clubspot member portal link.

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
- **GoRouter** — declarative routing with shell routes and mode-aware navigation
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
│   │   └── presentation/       #   Mode switcher, RC timing, crew dashboard,
│   │       └── mobile/         #   crew chat, crew safety, spectator, leaderboard,
│   │                           #   skipper check-in screens
│   ├── auth/                   # Login, verification, roles, member model, profile
│   ├── boat_checkin/           # Fleet management, event check-ins (RC + skipper)
│   ├── checklists/             # Templates, active completion, history, compliance
│   ├── courses/                # 57 courses, 13 marks, diagrams, wind groups, selection
│   ├── crew_assignment/        # Calendar, availability, event detail, CSV export
│   ├── home/                   # Home screen (weather, boat, races), more screen
│   ├── incidents/              # Incident reporting, protest workflow, form generator
│   ├── maintenance/            # Request management, scheduling, photo attachments
│   ├── race_mode/              # GPS track recording, upload, boat profile tagging
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

- **Live Spectator Map** — Real-time 2D map with boat icons moving on the course using GPS tracks
- **Horn Detection** — Microphone-based automatic horn detection to sync race starts
- **US Sailing / PHRF Certificate Sync** — Pull handicap ratings and certifications automatically
- **Race Replay Viewer** — Animated playback of GPS tracks on the course diagram
- **Crew Weight Tracker** — Class compliance weight tracking for one-design fleets

---

## License

Private — Monterey Peninsula Yacht Club. Not for redistribution.
