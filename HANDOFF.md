# EventEase Handoff Summary (for the next agent)

## Who you are working with
- User: Himesh, the team lead and only experienced developer on a 4-person student team.
- He is available for the first 2 days only; teammates handle days 3-4.
- Total timeline: 4 days. Days 1-2 = build the entire app, Day 3 = UI refinement, Day 4 = documents, APK, demo video.
- Working style he expects: make decisions for him, single-shot plans, no time wasted on option debates. Do not ask which library to use; PLAN.md already locked everything.
- Writing style: no em dashes, plain simple wording. Never add a Claude co-author trailer to commits. Never push to GitHub or create PRs unless he explicitly says so in that message; local commits are fine once work is verified.

## The project
- EventEase: a cross-platform event discovery and management mobile app, built from a college SRS PDF ("Cross-platform App Development SRS", EventEase, Aptech/Contest-AZM).
- Three roles: Attendee (browse, search/filter, register, QR pass, favorites, feedback 1-5), Organizer (create/edit events that start as pending, participants, announcements, QR scan check-in, gallery), Admin (approve/reject events, manage users/roles, moderate, stats).
- Mandatory deliverables: working Flutter app, documentation pack (problem definition, design spec, use case/sitemap/ER diagrams, DB design, README, test data, demo credentials), release APK, and a MANDATORY .mp4 demo video following the SRS demonstration checklist steps 8-19.
- Out of scope by SRS: payments, live streaming, social networking. FCM push was deliberately cut; notifications are in-app Firestore docs.

## Locked technical decisions (full detail in PLAN.md, do not re-decide)
- Flutter stable + Firebase (Auth email/password, Firestore, Storage). App id com.eventease.eventease.
- State: Provider. Routing: plain Navigator + AuthGate. Forms: plain Form/TextFormField.
- UI: Material 3 styled by flex_color_scheme (FlexScheme.redM3, light + dark), google_fonts Inter. Brand seed 0xFFD32F2F red. No third-party component kit.
- Persistence: Firestore offline cache + shared_preferences for small flags. No Hive/SQLite.
- QR: qr_flutter (uuid v4 pass string) + mobile_scanner. Images: image_picker + Firebase Storage + cached_network_image. Dates: intl.
- Day-3-only polish libs: flutter_animate, shimmer, gap.
- Roles: attendee (default), organizer (admin upgrades after organizerRequested flag), admin (first one bootstrapped by editing Firestore manually).
- Event statuses: pending/approved/rejected/cancelled/completed. Registration: registered/cancelled/attended.
- Seat control: registeredCount int on the event doc, changed only inside the registration/cancel Firestore transactions.
- Duplicate prevention for favorites and feedback: deterministic doc ids "userId_eventId".
- Search/filter: client-side on the streamed approved list.
- Architecture rule: screens never import cloud_firestore; all data access via repositories which throw Exception('readable message'); screens catch and show a snackbar. Every list handles loading/empty/error. Destructive actions use a shared confirm dialog.

## Current state of the repo (C:\Users\User\Programming\eventease)
- Flutter project created, packages installed, one local git commit on main, nothing pushed, flutter analyze clean.
- Already built as a base (Himesh may keep or discard it): core/constants.dart, core/theme.dart (plain M3 red, NOT yet flex_color_scheme), 5 models, AuthService with friendlyError, EventRepository (+ client-side filter), RegistrationRepository (register/cancel/checkInByQr transactions done), misc_repositories.dart (favorites, feedback, notifications with fan-out, users), common widgets (LoadingView/EmptyView/ErrorView/showSnack/confirm/EventCard), working Login/Register screens, AuthGate + role-based HomeShell with labeled stub screens, firestore.rules, TEAM_TASKS.md.
- NOT done: firebase_options.dart is a throwing placeholder (needs `flutterfire configure` + a real Firebase project), no real feature screens beyond auth, no seed data, gallery_repository/contact_repository/storage_service from PLAN.md not yet created, theme not yet switched to flex_color_scheme, flex_color_scheme/google_fonts/shared_preferences/gap/shimmer/flutter_animate not yet installed.
- Important: at one point he said "do not build anything". Build only when he clearly asks; when unsure whether to write code or just plan/answer, plan/answer.

## Key files
- PLAN.md: the single-shot 4-day plan, phases with exit gates, scope-cut order, data model, rules requirements. Treat it as the spec.
- TEAM_TASKS.md: per-teammate assignments (A: attendee screens, B: organizer+admin, C: profile/docs/seed/APK/video).
- firestore.rules: role enforcement (no self-role-change, organizers cannot self-approve, per-user data access).

## Immediate manual steps pending (only Himesh can do)
1. Create the Firebase project, enable Auth/Firestore/Storage, run `flutterfire configure`, paste firestore.rules into the console.
2. Register the first account and flip its role to admin in the Firestore console.
