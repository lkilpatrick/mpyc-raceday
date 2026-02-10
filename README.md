# MPYC Race Day

Race management platform for **Monterey Peninsula Yacht Club** — a cross-platform Flutter application with a Firebase backend that powers both a mobile crew/skipper app and a web admin dashboard.

<p align="center">
  <img src="assets/images/burgee.png" alt="MPYC Burgee" width="120" />
</p>

---

## Overview

MPYC Race Day streamlines every aspect of club sailboat racing: course selection based on live wind data, crew scheduling, boat check-ins, race timing, incident reporting, maintenance tracking, and fleet communications — all in real time.

| Platform | Target Users | Key Features |
|----------|-------------|--------------|
| **Mobile** (Android / iOS) | Skippers, Crew | Course info, weather, check-in, incident & maintenance reporting, racing rules |
| **Web** | RC Chair, Club Board, Admins | Dashboard, season calendar, crew management, course config, fleet broadcasts, reports |

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│                  Flutter App                     │
│  ┌──────────┐  ┌──────────┐  ┌───────────────┐  │
│  │  Mobile   │  │   Web    │  │  Shared Layer │  │
│  │  Screens  │  │  Pages   │  │  Models/Repos │  │
│  └──────────┘  └──────────┘  └───────────────┘  │
│         Riverpod State Management                │
│         GoRouter Navigation                      │
└──────────────────┬──────────────────────────────┘
                   │
        ┌──────────▼──────────┐
        │   Firebase Backend   │
        │  ┌────────────────┐  │
        │  │   Firestore    │  │  Collections: members, race_events,
        │  │                │  │  courses, marks, weather, incidents,
        │  │                │  │  maintenance_requests, fleets, ...
        │  ├────────────────┤  │
        │  │  Cloud Funcs   │  │  NOAA weather fetch (1 min),
        │  │                │  │  Clubspot member sync, SMS/email
        │  ├────────────────┤  │
        │  │  Auth / FCM    │  │  Email+password auth, push notifications
        │  └────────────────┘  │
        └─────────────────────┘
```

### Tech Stack

- **Flutter 3.10+** — Dart, Material 3, single codebase for mobile + web
- **Firebase** — Firestore, Auth, Cloud Functions, Hosting, Storage, FCM
- **Riverpod** — reactive state management
- **GoRouter** — declarative routing with shell routes
- **NOAA Weather API** — live wind/temp/pressure via Cloud Function (no API key needed)
- **Clubspot API** — member sync, score push, billing data

---

## Features

### Mobile App
- **Home** — next race countdown, quick actions, live wind summary
- **Course Tab** — active course display, course library filtered by live wind direction, manual wind override slider
- **Weather** — real-time NOAA wind compass, temperature, humidity, pressure, history
- **Report** — file protest incidents and maintenance issues with photos
- **More** — schedule, checklists, racing rules reference with situation advisor, profile

### Web Dashboard
- **Dashboard** — metric cards (next race, maintenance, season progress, member count), live wind widget, upcoming events, activity feed, attention-needed alerts
- **Season Calendar** — full race calendar with CSV import, series management
- **Race Events** — event CRUD, crew assignment, course selection
- **Crew Management** — availability tracking, role-based assignment
- **Course Configuration** — 57 courses across 6 wind groups with color coding, race mark management, interactive map, course diagrams
- **Checklists** — template builder, completion tracking, compliance dashboard
- **Maintenance** — request management, scheduling, priority tracking
- **Incidents & Protests** — incident review, protest workflow
- **Fleet Broadcasts** — SMS/email notifications to fleets
- **Weather Logs** — per-event weather history, analytics
- **Reports** — season summaries, participation stats
- **Members** — Clubspot-synced member directory
- **System Settings** — app configuration

### Courses Module
- **57 courses** across 6 wind groups: Southerly/SW, Westerly, NW, Northerly, Inflatable, Long
- **13 race marks** — permanent (MY buoys), government (R2, R4), harbor (A, X), temporary/inflatable (W, R, L, LV)
- **4 fleets** — Santana 22, Shields, PHRF A, PHRF B
- Wind group color coding throughout UI (red, blue, green, amber, purple, teal)
- START/FINISH sequence format with implicit start line at Mark 1
- Course diagrams with north-up orientation, mark-type icons, leg arrows

### Role-Based Access
| Role | Access |
|------|--------|
| `web_admin` | Full access — inherits all roles |
| `club_board` | Reports, member oversight, web dashboard |
| `rc_chair` | Race operations, checklists, incidents, web dashboard |
| `skipper` | Mobile race features, maintenance reporting |
| `crew` | Basic mobile access |

---

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.10
- Node.js ≥ 18 (for Cloud Functions and seed scripts)
- Firebase CLI (`npm install -g firebase-tools`)
- A Firebase project with Firestore, Auth, and Functions enabled

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
flutter build apk --debug

# Build for web deployment
flutter build web
```

### Deploy

```bash
# Deploy web app to Firebase Hosting
firebase deploy --only hosting

# Deploy Cloud Functions
firebase deploy --only functions

# Deploy Firestore rules
firebase deploy --only firestore:rules
```

---

## Project Structure

```
lib/
├── core/                   # Theme, error handling, constants, offline queue
├── features/
│   ├── admin/              # Dashboard, member management, system settings
│   ├── auth/               # Login, roles, member model
│   ├── boat_checkin/       # Fleet management, event check-ins
│   ├── checklists/         # Templates, completion, compliance
│   ├── courses/            # Course config, marks, diagrams, providers
│   ├── crew_assignment/    # Calendar, availability, event management
│   ├── home/               # Home screen, more screen
│   ├── incidents/          # Incident reporting and management
│   ├── maintenance/        # Maintenance requests, scheduling
│   ├── racing_rules/       # Rules reference, situation advisor
│   ├── reporting/          # Combined protest + maintenance reporting
│   ├── reports/            # Season reports and analytics
│   ├── timing/             # Race timing
│   └── weather/            # NOAA weather, live providers, widgets
├── mobile/                 # Mobile shell, router, bottom nav
├── shared/                 # Shared models, services, widgets
├── web/                    # Web shell, router, sidebar, scaffold
├── firebase_options.dart
└── main.dart

functions/src/              # Cloud Functions (NOAA fetch, Clubspot sync, notifications)
scripts/                    # Seed scripts (courses, admin, calendar)
assets/
├── courses_seed.json       # Course data: marks, distances, wind groups, fleets, 57 courses
├── racing_rules.json       # Racing rules reference data
└── images/                 # Burgee, club photos
```

---

## Cloud Functions

| Function | Trigger | Description |
|----------|---------|-------------|
| `scheduledWeatherFetch` | Every 1 min | Fetches NOAA KMRY station data → writes to `weather/mpyc_station` |
| `syncClubspotMembers` | Daily / manual | Syncs member data from Clubspot API → `members` collection |
| `sendVerificationCode` | HTTPS callable | Sends email verification code for mobile login |

---

## Data Flow

### Weather
```
NOAA API (api.weather.gov) → Cloud Function (1 min) → Firestore doc → Flutter StreamProvider → UI
```

### Courses
```
courses_seed.json → seed script / web "Seed Data" button → Firestore → StreamProvider → Course Tab / Config Page
```

### Notifications
```
App action → Firestore trigger → Cloud Function → SMS (sms collection) / Email (mail collection) / FCM Push
```

---

## Scripts

| Script | Usage | Description |
|--------|-------|-------------|
| `scripts/seed_courses.js` | `node scripts/seed_courses.js` | Seeds marks, distances, wind groups, fleets, and courses |
| `scripts/seed_admin.js` | `node scripts/seed_admin.js` | Creates initial admin user |
| `scripts/seed_calendar.js` | `node scripts/seed_calendar.js` | Imports race calendar from CSV |

---

## License

Private — Monterey Peninsula Yacht Club. Not for redistribution.
