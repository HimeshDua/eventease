# EventEase Design Specification

## 2.1 Product Perspective

EventEase is a standalone mobile application (Flutter, single codebase) with a
Firebase backend. It is not an extension of an existing system and owns no
on-premises services.

## 2.2 Technology Stack
- **Framework:** Flutter (Material 3, `useMaterial3: true`).
- **State management:** Provider.
- **Navigation:** plain `Navigator` + an `AuthGate` route guard.
- **Authentication:** Firebase Authentication (email/password).
- **Database:** Cloud Firestore.
- **Storage:** Firebase Storage.
- **Maps:** `flutter_map` + `latlong2` reading OSM tiles
  (`https://tile.openstreetmap.org/{z}/{x}/{y}.png`) with attribution; no
  Google Maps SDK. External navigation is launched with `url_launcher` to
  `https://www.google.com/maps/dir/?api=1&destination=<lat>,<lng>&dir_action=navigate`.
- **QR:** `qr_flutter` (pass rendering) + `mobile_scanner` (scan check-in).
- **Images:** `image_picker` + Firebase Storage + `cached_network_image`.
- **Dates/IDs:** `intl`, `uuid`.
- **Local flags:** `shared_preferences` (reminder preference only).

**Excluded:** Google Fonts, FlexColorScheme, third-party UI kits, Riverpod,
Bloc, GetX, Redux, GoRouter, Supabase, REST/Node/Laravel backends.

## 2.3 Architecture

Layered, with strict boundaries (see `AGENTS.md §8`):

```
UI / Screens          (no direct Firebase imports)
  → Presentation/Provider state
  → Repositories      (Firestore invariants; throw Exception('readable'))
  → Services          (Auth, Storage, Map launcher)
  → Firebase          (Auth / Firestore / Storage)
```

- **Services own Firebase API access.** `AuthService`, `StorageService`,
  `MapLauncherService`.
- **Repositories own data invariants** and throw `StateError` / `Exception`
  with human-readable messages. Screens catch and surface `friendlyError(e)`.
- **Screens never import `cloud_firestore`/`firebase_auth`/`firebase_storage`**;
  verified by `rg "cloud_firestore|firebase_auth|firebase_storage" lib/screens`.

`lib/main.dart` registers every provider once in dependency order inside a
`MultiProvider`.

## 2.4 Security Model
- **Authentication** is owned by Firebase Auth; passwords never leave Auth and
  are never stored in Firestore.
- **Authorization** is enforced in **Firebase Security Rules** (do not trust the
  client). Firestore rules gate reads/writes by role, document ownership, and
  event-owned-by-organizer. Storage rules gate upload/download by identity and
  event ownership, enforcing `image/*`, < 10 MB.
- **Roles** come from the `users/{uid}.role` field. A user cannot promote
  themselves; role/active changes are admin-only in the rules.
- **QR codes are passes, not credentials.** Scanning validates the registration
  against backend data inside a Firestore transaction (plan read-before-write),
  preventing duplicate check-in and wrong-event check-in.

## 2.5 Event Lifecycle
Organizer creates event → **pending**, count 0, valid coordinates → Administrator
reviews → **approved** → attendees discover/register → event occurs → **completed**
(or `endTime <= now`) → gallery/feedback available. Edits that change
start/end/location/coordinates on an approved event return it to **pending** with
`changeReviewPending: true`; the organizer cannot self-approve. Organizers can
only request cancellation; an admin approves it to set **cancelled** and notify
registrants.

## 2.6 Registration & Seat Control
- Registration ID is deterministic: `users Eventease{userId}_{eventId}`.
- A transaction reads the event + registration + user, enforces
  approved/open/future/capacity/no-active-duplicate, then creates or reactivates
  the pass and increments `registeredCount` exactly once.
- Cancellation (transaction) requires `registered` + future start and decrements
  exactly once, never below zero.
- Capacity is never trusted to the client; the counter delta is constrained by
  rules to exactly ±1.

## 2.7 Notifications
In-app only, one Firestore document per recipient. Deterministic IDs
(`sendOnce`) prevent duplicate reminders/feedback requests. Fan-out to
registrants uses batched writes in safe (≤450) batch sizes. Types:
`registration`, `reminder`, `eventChanged`, `cancelled`, `announcement`,
`feedbackRequest`, `approval`, `rejection`, `roleApproved`.

## 2.8 UI System
Material 3 with a red brand seed (`0xFFD32F2F`). Colors come from
`Theme.of(context).colorScheme`; typography from the default Material
`textTheme`. Adaptive shell: `NavigationBar` under 600 logical px, `NavigationRail`
above; content max width 1040, forms max 560. Cards 12 dp, dialogs/sheets 28 dp,
full-rounded buttons/chips, tonal surfaces, `outlineVariant` dividers, 48 dp
minimum touch targets, tooltips/semantics for icon-only controls. Image uploads
are JPEG q80, max width 1600, enforced to 10 MB in Storage rules.

## 2.9 Error / Loading / Empty States
Every data screen handles loading, empty, error. Destructive actions require a
confirmation dialog. Failures show readable snackbars via `friendlyError`; raw
Firebase exceptions/stack traces are never surfaced to users.
