# MPYC RaceDay

Race Committee management system for **Monterey Peninsula Yacht Club**. Flutter mobile + web application backed by Firebase.

## Features

- **Crew Scheduling** — Season calendar, role assignment, availability tracking, automated reminders
- **Boat Check-In** — Fleet master list, race-day check-in with safety verification, CSV import
- **Race Timing** — Start sequence with countdown/flags, finish recording, PHRF handicap (TOT & TOD), results publishing
- **Course Management** — 14-course library matching MPYC's fixed-mark system, wind-based recommendations, fleet broadcast
- **Weather** — NOAA/OpenWeather integration, WindCompassWidget, threshold alerts, historical logging
- **Checklists** — Pre-race, post-race, and safety checklists with sign-off, photo evidence, compliance dashboard
- **Incidents & Protests** — On-water incident capture, protest form generation (World Sailing layout), hearing workflow, decision documents
- **Maintenance** — Issue reporting with photos, priority tracking, scheduling, cost tracking
- **Racing Rules** — RRS reference database, situation advisor
- **Web Admin** — Dashboard with metrics, 7-tab reports module (fl_chart), system settings, audit log
- **Notifications** — Twilio SMS + FCM push for course selection, incidents, hearings, crew reminders
- **Clubspot Integration** — Automated member sync with pagination, retry, and conflict resolution

## Architecture

```
┌─────────────┐   ┌─────────────┐
│  Flutter     │   │  Flutter    │
│  Mobile App  │   │  Web Admin  │
└──────┬───────┘   └──────┬──────┘
       │                  │
       └────────┬─────────┘
                │
       ┌────────▼────────┐
       │    Firebase      │
       │  ┌────────────┐  │
       │  │ Firestore   │  │
       │  │ Auth        │  │
       │  │ Storage     │  │
       │  │ Functions   │  │
       │  │ Hosting     │  │
       │  └────────────┘  │
       └────────┬─────────┘
                │
       ┌────────▼────────┐
       │  External APIs   │
       │  ┌────────────┐  │
       │  │ Clubspot    │  │
       │  │ NOAA        │  │
       │  │ OpenWeather │  │
       │  │ Twilio      │  │
       │  └────────────┘  │
       └──────────────────┘
```

**State Management:** Riverpod  
**Routing:** GoRouter (separate mobile/web routers)  
**Data Models:** Plain Dart classes (no freezed for new models; legacy Member model uses freezed)

## Project Structure

```
lib/
├── core/              # Theme, errors, retry, offline queue
├── features/
│   ├── admin/         # Dashboard, member mgmt, system settings
│   ├── auth/          # Login, verification, member model
│   ├── boat_checkin/  # Fleet, check-in, CSV import
│   ├── checklists/    # Templates, completion, compliance
│   ├── courses/       # Course config, selection, broadcast
│   ├── crew_assignment/ # Calendar, roles, availability
│   ├── home/          # Mobile home screen, more screen
│   ├── incidents/     # Incidents, protests, hearing workflow
│   ├── maintenance/   # Requests, scheduling, reports
│   ├── racing_rules/  # RRS database, situation advisor
│   ├── reports/       # 7-tab reporting module
│   ├── timing/        # Start sequence, finish recording, results
│   └── weather/       # Dashboard, compass, history
├── mobile/            # Mobile shell, router, bottom nav
├── shared/            # Shared widgets, models, services
└── web/               # Web shell, router, sidebar, scaffold
functions/src/         # Cloud Functions (Node.js)
test/                  # Unit and widget tests
integration_test/      # End-to-end integration tests
```

## Setup

### Prerequisites

- Flutter SDK (stable channel, ≥3.10)
- Node.js 20+
- Firebase CLI (`npm install -g firebase-tools`)
- A Firebase project with Firestore, Auth, Storage, and Functions enabled

### Environment Variables

Create a `.env` file in the project root (mobile) or use `--dart-define` (web):

```
CLUBSPOT_API_KEY=your_clubspot_api_key
MANUAL_SYNC_URL=https://your-cloud-function-url
```

For Cloud Functions, set secrets:

```bash
firebase functions:secrets:set TWILIO_ACCOUNT_SID
firebase functions:secrets:set TWILIO_AUTH_TOKEN
firebase functions:secrets:set TWILIO_FROM_NUMBER
firebase functions:secrets:set CLUBSPOT_API_KEY
```

### Firebase Projects

| Environment | Project ID       |
|-------------|------------------|
| Development | `mpyc-rc-dev`    |
| Production  | `mpyc-raceday`   |

### Running Locally

**Mobile:**
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

**Web:**
```bash
flutter run -d chrome --dart-define=CLUBSPOT_API_KEY=xxx
```

**Cloud Functions (local emulator):**
```bash
cd functions
npm install
firebase emulators:start --only functions,firestore
```

## Testing

**Unit tests:**
```bash
flutter test test/unit/
```

**Widget tests:**
```bash
flutter test test/widget/
```

**Integration tests** (requires Firebase emulators):
```bash
flutter test integration_test/
```

**All tests:**
```bash
flutter test
```

## Deployment

### CI/CD Pipeline (GitHub Actions)

| Trigger        | Actions                                              |
|----------------|------------------------------------------------------|
| Pull Request   | `dart analyze` → `flutter test` → build check        |
| Merge to main  | Test → Build web → Deploy Hosting + Functions + Firestore |
| Release tag    | Build release APK/IPA → prepare for store submission  |

### Manual Deploy

```bash
flutter build web --release
firebase deploy --only hosting,functions,firestore --project mpyc-raceday
```

## Offline Support

- Firestore offline persistence enabled globally (unlimited cache)
- Offline write queue: writes queued locally, synced on reconnect
- Network status banner shown when offline
- Timing and checklists work fully offline
- Weather shows "last known" data when offline

## Contributing

1. Create a feature branch from `main`
2. Write tests for new functionality
3. Run `dart analyze` and `flutter test` before pushing
4. Open a PR — CI will run analyze, test, and build checks
5. Merge after review and CI passes
