# EventEase

Cross-platform mobile event-discovery and management app built with **Flutter**
and **Firebase**. Three roles — Attendee, Organizer, Administrator — share one
codebase: browse and register for approved events, get a scannable QR pass,
check in attendees, manage events, approve submissions, and view statistics.

> Notifications are in-app only (Firestore documents, no FCM). Maps use
> OpenStreetMap; external navigation opens Google Maps via URL.

## Features
- Event discovery with search + filters (keyword, category, date, location, availability)
- Event details with an embedded **OpenStreetMap** marker and **Google Maps directions**
- QR pass generation (`qr_flutter`) and QR check-in (`mobile_scanner`)
- Seat capacity enforced by a Firestore transaction (no client-side trust)
- Registration / cancellation with deterministic IDs (duplicate-safe)
- Favorites, feedback (1–5 stars), in-app notifications
- Organizer: create/edit events, participants, announcements, gallery, QR scan
- Administrator: approve/reject events, manage users & roles, moderate gallery, statistics
- Material 3 theme, adaptive NavigationBar / NavigationRail, offline cache

## Requirements
- Flutter stable (SDK `>=3.11.5` — see `pubspec.yaml`)
- A Firebase project with **Authentication (email/password)**, **Firestore**, and
  **Storage** enabled
- Android: `com.eventease.eventease` package (configured in
  `android/app/build.gradle` and `google-services.json`)

## Installation
```bash
flutter pub get
```

## Firebase configuration
1. Create a Firebase project (or reuse the configured `eventease-555`).
2. Register the Android app as `com.eventease.eventease` (iOS bundle
   `com.eventease.eventease`).
3. Enable **Email/Password** under Authentication → Sign-in method.
4. Run the FlutterFire CLI and merge the result into `lib/firebase_options.dart`:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=eventease-555 \
     --android-package-name=com.eventease.eventease \
     --ios-bundle-id=com.eventease.eventease
   ```
5. Deploy the security rules (do not weaken them):
   ```bash
   firebase deploy --only firestore:rules,storage:rules,firestore:indexes
   ```
6. Create the first administrator: register the account in-app, then in the
   Firestore console set `users/{uid}.role = "admin"`.

## Run
```bash
flutter run
```

## Testing
```bash
flutter analyze        # 0 issues
flutter test           # 48/48 passing (pure-logic + widget tests; no Firebase)
```

## Demo credentials
See [`DEMO_CREDENTIALS.md`](./DEMO_CREDENTIALS.md) and
[`docs/test-data.md`](./docs/test-data.md).

## Release build (requires explicit authorization)
APK creation is intentionally blocked by default. When authorized:
```bash
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```
Smoke test: login → event details → map → register → QR pass.

## Project structure
```
lib/
  core/        constants, theme, errors, validators
  models/      AppUser, Event, Registration, EventFeedback, AppNotification, GalleryItem
  repositories/ event, registration, misc (favorites/feedback/notifications/users), gallery, contact
  services/    AuthService, StorageService, MapLauncherService
  screens/     auth, attendee, organizer, admin, shared  (no direct Firebase imports)
  widgets/     common UI + event_map + location_picker
docs/          SRS documentation (problem definition, design, use-cases, sitemap, ERD, DB design, test data, acceptance evidence)
firestore.rules, storage.rules, firestore.indexes.json
```

## License
Educational student project. See `AGENTS.md` and `PLAN.md` for architecture and
process decisions.
