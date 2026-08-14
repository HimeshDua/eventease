# EventEase Agent Execution Specification

## EXECUTION_DIRECTIVE

Implement the existing EventEase repository to completion. This file is the implementation authority derived from `Cross-platform App Development SRS.pdf`. Do not generate another plan. Do not summarize tasks before implementation.

Execution loop:

1. Read `GLOBAL_CONTRACT`, `DATA_SCHEMA`, `INTERFACE_REGISTRY`, and the next unchecked module whose dependencies are complete.
2. Inspect only that module's files and direct consumers.
3. Implement every unchecked item in the module.
4. Perform the module's acceptance checks that are currently authorized and available.
5. Review the diff for scope, security, error handling, and unfinished markers.
6. Mark only evidenced checklist items complete.
7. Make the specified local commit when the module is verified.
8. Continue immediately to the next dependency-ready module.

Do not pause for routine implementation decisions. If an external prerequisite blocks one module, annotate that module `BLOCKED: <exact prerequisite>` and continue every independent module. Stop only when all remaining modules share the same external blocker or all modules are complete.

Final response format, at most eight bullets: completed modules, changed-file groups, focused checks, local commits, external blockers, deliberately unrun checks, remaining modules, next required manual action.

## GLOBAL_CONTRACT

- Repository root: `C:\Users\User\Programming\eventease`.
- Preserve the initialized Flutter project and existing working code. Do not recreate the project.
- Product authority: SRS functional requirements 1.6.1 through 1.6.20, non-functional requirements 1.7, security rules, interface requirements 1.8, testing requirements 1.8.4, deliverables 1.9, and demonstration steps 8 through 19.
- User-added mandatory enhancement: OpenStreetMap venue selection/display plus external Google Maps directions.
- Explicit exclusions: payments, live streaming, social networking, FCM, Places API, geocoding API, in-app routing, recommendation engine, web admin portal, multilingual support, certificates, waitlists.
- State and navigation: Provider, plain Navigator, AuthGate, MaterialPageRoute, Form, TextFormField.
- UI: native Material 3 only. `useMaterial3: true`; Material Theme Builder exported light/dark `ColorScheme`; system theme mode; Roboto/default Material typography; no FlexColorScheme, Google Fonts, third-party UI kit, raw semantic colors, arbitrary shadows, or duplicate design systems.
- Material tokens: colors through `Theme.of(context).colorScheme`; typography through `textTheme`; 12dp cards, 28dp dialogs/sheets, full-rounded buttons/chips, tonal surfaces, `outlineVariant` dividers, 48dp minimum targets, tooltips/semantics for icon-only controls.
- Adaptive shell: `NavigationBar` below 600 logical pixels; `NavigationRail` at 600 and above; content max width 1040; forms max width 560; no browser validation.
- Firebase boundary: screens must not import `cloud_firestore`, `firebase_auth`, or `firebase_storage`. Screens call Provider-managed repositories/services. Repositories enforce invariants and throw `Exception('Readable message')`; screens catch and use shared snackbar/error views.
- Lists: loading, empty, populated, error. Forms: field-specific validation. Destructive actions: confirmation dialog. Network/backend failures: readable and non-crashing.
- Persistence: Firestore offline cache for non-critical reads; `shared_preferences` only for reminder preference. Registration and attendance require connectivity.
- Image uploads: JPEG quality 80, max width 1600, `image/*`, maximum 10 MB enforced in Storage Rules.
- Embedded map: `flutter_map` and `latlong2`; OSM tile URL `https://tile.openstreetmap.org/{z}/{x}/{y}.png`; visible `OpenStreetMap contributors` attribution; `userAgentPackageName: 'com.eventease.eventease'`; no tile prefetch/bulk download.
- Directions: `url_launcher` opens `https://www.google.com/maps/dir/?api=1&destination=<lat>,<lng>&dir_action=navigate`; no Google Maps SDK or API key.
- Package additions allowed: `shared_preferences`, `flutter_map`, `latlong2`, `url_launcher`. Do not add optional polish packages until every required module passes.
- Never expose passwords or store credentials in Firestore.
- Never weaken rules to unblock UI. Never implement a direct Firebase call in a screen.
- Do not run typechecking, builds, browser validation, browser automation, or a development server unless explicitly requested in the current user message. Focused `flutter test` commands are allowed. APK creation remains pending explicit build permission.
- Never push or create a PR. Local commits are allowed after evidenced checks. No co-author trailer.

## SRS_COVERAGE_INDEX

| SRS source | Implementation modules |
|---|---|
| Page 3: scope, roles, constraints | M01-M08, M26 |
| Page 4: auth, dashboards, discovery, filters, details, registration | M09-M14 |
| Page 5: My Events, favorites, notifications, QR, event editing, cancellation, feedback | M15-M20 |
| Page 6: gallery, profile, admin management, statistics, Contact/About | M18, M21-M25 |
| Page 7: errors and layered architecture | M03-M08, M26 |
| Pages 8-9: role use cases and sitemap | M10, M12-M25 |
| Pages 10-12: entities and relationships | M04-M08 |
| Pages 12-13: NFRs, offline, maintainability, security | M03, M06-M08, M26-M27 |
| Pages 13-14: required screens and minimum tests | M09-M27 |
| Pages 14-16: deliverables, demo sequence, final video | M28-M30 |
| Page 15 optional map, promoted to mandatory by user | M05, M13, M19 |

No SRS requirement may be removed as a scope cut. Simplify presentation before behavior.

## DATA_SCHEMA

### `users/{uid}`

`name`, `email`, `phone`, `role`, `active`, `organizerRequested`, `profileImageUrl?`, `remindersEnabled`, `createdAt`.

- `role`: attendee, organizer, admin.
- Signup writes attendee only.
- Password remains in Firebase Auth only.

### `events/{eventId}`

`organizerId`, `title`, `description`, `category`, `startTime`, `endTime`, `location`, `latitude`, `longitude`, `maxParticipants`, `registeredCount`, `status`, `imageUrl`, `rules`, `contactInfo`, `cancellationRequested`, `cancellationReason?`, `changeReviewPending`, `createdAt`, `updatedAt`.

- Status: pending, approved, rejected, cancelled, completed.
- Runtime completion is `status == completed || endTime <= now`.
- New event: pending, count 0, valid coordinates.
- Critical edit fields: startTime, endTime, location, latitude, longitude. Editing an approved event sets pending and `changeReviewPending: true`.

### `registrations/{userId_eventId}`

`eventId`, `userId`, `status`, `qrCode`, `registeredAt`, `checkedInAt?`.

### `attendance/{userId_eventId}`

`registrationId`, `eventId`, `userId`, `attended`, `checkedInAt`.

### `favorites/{userId_eventId}`

`userId`, `eventId`, `createdAt`.

### `feedback/{userId_eventId}`

`eventId`, `userId`, `rating`, `comment`, `submittedAt`.

### `notifications/{autoId|deterministicId}`

`userId`, `eventId?`, `type`, `title`, `message`, `isRead`, `createdAt`.

Types: registration, reminder, eventChanged, cancelled, announcement, feedbackRequest, approval, rejection, roleApproved.

### `gallery/{mediaId}`

`eventId`, `uploadedBy`, `imageUrl`, `caption?`, `uploadedAt`.

### `contactMessages/{messageId}`

`userId`, `name`, `email`, `subject`, `message`, `submittedAt`.

## INTERFACE_REGISTRY

Implement these signatures once. Consumers must not invent alternatives.

```text
AuthService
  Stream<AppUser?> get userStream
  AppUser? get currentUser
  register({name,email,phone,password,wantsOrganizer}) -> Future<void>
  login(email,password) -> Future<void>
  logout() -> Future<void>
  resetPassword(email) -> Future<void>
  changePassword(newPassword) -> Future<void>

EventRepository
  newId() -> String
  approvedUpcoming() -> Stream<List<Event>>
  byOrganizer(organizerId) -> Stream<List<Event>>
  all() -> Stream<List<Event>>
  watch(eventId) -> Stream<Event>
  create(eventId,event) -> Future<void>
  updateOwned(eventId,changes) -> Future<void>
  setStatus(eventId,status,{changeReviewPending=false}) -> Future<void>
  requestCancellation(eventId,reason) -> Future<void>
  approveCancellation(eventId) -> Future<void>
  adminDelete(eventId) -> Future<void>
  filter(events,{query,category,date,location,onlyAvailable}) -> List<Event>

RegistrationRepository
  register(eventId,userId) -> Future<Registration>
  cancel(registration) -> Future<void>
  checkInByQr(qrCode,eventId) -> Future<Registration>
  byUser(userId) -> Stream<List<Registration>>
  byEvent(eventId) -> Stream<List<Registration>>
  allRegistrations() -> Stream<List<Registration>>

FavoriteRepository
  add(userId,eventId) -> Future<void>
  remove(userId,eventId) -> Future<void>
  eventIds(userId) -> Stream<Set<String>>

FeedbackRepository
  submit(feedback) -> Future<void>
  byEvent(eventId) -> Stream<List<EventFeedback>>
  all() -> Stream<List<EventFeedback>>
  hasSubmitted(userId,eventId) -> Future<bool>

NotificationRepository
  byUser(userId) -> Stream<List<AppNotification>>
  unreadCount(userId) -> Stream<int>
  send({userId,eventId,type,title,message}) -> Future<void>
  sendOnce({docId,userId,eventId,type,title,message}) -> Future<void>
  sendToEventRegistrants({eventId,type,title,message}) -> Future<void>
  markRead(notificationId) -> Future<void>

UserRepository
  all() -> Stream<List<AppUser>>
  updateProfile(userId,{name,phone,profileImageUrl}) -> Future<void>
  requestOrganizerAccess(userId) -> Future<void>
  setRole(userId,role) -> Future<void>
  setActive(userId,active) -> Future<void>

StorageService
  uploadImage(file,path) -> Future<String>
  deleteByUrl(url) -> Future<void>

GalleryRepository
  byEvent(eventId) -> Stream<List<GalleryItem>>
  upload(item) -> Future<void>
  delete(item) -> Future<void>

ContactRepository
  submit({userId,name,email,subject,message}) -> Future<void>

MapLauncherService
  googleDirectionsUri(latitude,longitude) -> Uri
  openGoogleDirections(latitude,longitude) -> Future<void>
```

## MODULE_GRAPH

`M00 -> M01 -> M02 -> M03 -> M04 -> M05 -> M06 -> M07 -> M08 -> M09 -> M10 -> M11 -> M12 -> M13 -> M14 -> M15 -> M16 -> M17 -> M18 -> M19 -> M20 -> M21 -> M22 -> M23 -> M24 -> M25 -> M26 -> M27 -> M28 -> M29 -> M30`

Modules may be implemented ahead only when all declared dependencies are complete.

---

## M00 REPOSITORY_BASELINE

**depends_on:** none

**files:** read-only repository tree, `pubspec.yaml`, current `lib/`, `test/`, `firestore.rules`, `PLAN.md`.

- [ ] Preserve the existing auth screens, AuthGate, models, repository code, shared widgets, and shell unless a later module explicitly replaces them.
- [ ] Record current dirty files before edits; do not overwrite unrelated user changes.
- [ ] Confirm `firebase_options.dart` is a placeholder and treat Firebase runtime checks as blocked until M02 manual configuration is supplied.
- [ ] Create no code in this module.

**acceptance:** current surface and dirty state are known; no mutation.

## M01 DEPENDENCIES_AND_THEME

**depends_on:** M00

**files:** `pubspec.yaml`; create `lib/core/material_theme.dart`; modify `lib/core/theme.dart`, `lib/main.dart`.

- [ ] Add only `shared_preferences`, `flutter_map`, `latlong2`, `url_launcher`.
- [ ] Put the Material Theme Builder exported light/dark schemes for seed `0xFFD32F2F` in `material_theme.dart`.
- [ ] Build `ThemeData(useMaterial3: true)` for both brightnesses using exported roles; system theme mode.
- [ ] Centralize component themes for cards, inputs, buttons, navigation, dialogs, chips, snackbars, and progress indicators.
- [ ] Use default Material typography. Remove no package unless it is actually present and unused.

**acceptance:** source inspection finds both schemes, `useMaterial3: true`, and no final `ColorScheme.fromSeed` fallback.

**commit:** `M01 configure strict Material 3 foundation`

## M02 FIREBASE_BOOTSTRAP_GATE

**depends_on:** M00

**files:** generated `lib/firebase_options.dart`; Firebase project configuration.

- [ ] If real configuration exists, preserve it.
- [ ] If placeholder remains, annotate this module blocked with exact manual commands: create Firebase project, enable email/password Auth, Firestore, Storage, run `flutterfire configure` for `com.eventease.eventease`.
- [ ] Do not fabricate Firebase values or block independent source implementation.
- [ ] Do not deploy rules before M08.

**acceptance:** real config exists or one precise external blocker is recorded.

## M03 APP_BOOTSTRAP_AND_SHARED_UI

**depends_on:** M01

**files:** `lib/main.dart`; create `lib/screens/shared/splash_screen.dart`; modify `lib/widgets/common.dart`.

- [ ] Show branded Material 3 splash during Firebase initialization; route success to AuthGate; route failure to readable retry UI.
- [ ] Keep `LoadingView`, `EmptyView`, `ErrorView`, `showSnack`, `confirm`, date formatter, and EventCard reusable.
- [ ] EventCard displays image, title, date/time, location, category, available seats, and semantic tap target.
- [ ] Replace hardcoded semantic greys/reds in shared widgets with theme roles.

**acceptance:** initialization has loading/success/error branches; shared widgets contain no direct Firebase access.

**commit:** `M03 add resilient bootstrap and shared UI`

## M04 DOMAIN_MODELS

**depends_on:** M00

**files:** `lib/core/constants.dart`; modify five existing models; create `lib/models/gallery_item.dart`.

- [ ] Implement the complete `DATA_SCHEMA` with backward-compatible parsing.
- [ ] Add event derived values: `availableSeats`, `isFull`, `hasStarted`, `hasEnded`, `isCompleted`.
- [ ] Add fixed categories: Technology, Education, Sports, Music, Business, Workshop, Conference, Community.
- [ ] Add map constants: Karachi default center 24.8607/67.0011, picker zoom 12, venue zoom 15, tile URL, package user-agent.
- [ ] Preserve Firestore Timestamp conversions and server timestamps.

**acceptance:** inspect every constructor call found by `rg "AppUser\(|Event\(|Registration\(|EventFeedback\(" lib test`; all required fields resolve.

**commit:** `M04 finalize EventEase domain schema`

## M05 AUTHENTICATION_AND_PROFILE_DATA

**depends_on:** M04

**files:** `lib/services/auth_service.dart`; split or modify user portion of `lib/repositories/misc_repositories.dart`.

- [ ] Make `userStream` continuously observe the signed-in user document so role/active changes update without relogin.
- [ ] Signup writes attendee role, active true, organizer request flag, reminder preference true.
- [ ] Implement all AuthService/UserRepository registry methods.
- [ ] Convert Firebase Auth errors for invalid credential, duplicate email, weak password, invalid email, network failure, and recent-login requirement.
- [ ] Prevent profile APIs from accepting role/active changes.

**acceptance:** trace register, login, logout, reset, change password, profile update, organizer request, promotion, deactivation.

**commit:** `M05 complete authentication and profile data flows`

## M06 EVENT_REGISTRATION_REPOSITORIES

**depends_on:** M04

**files:** `lib/repositories/event_repository.dart`, `lib/repositories/registration_repository.dart`.

- [ ] Implement EventRepository registry including location filter and ended-event exclusion from discovery.
- [ ] `create` enforces pending/count zero/owner fields.
- [ ] `updateOwned` rejects started/cancelled events; critical edit of approved event sets pending and `changeReviewPending: true`.
- [ ] Organizer cancellation writes request/reason only. Admin approval writes cancelled.
- [ ] Registration ID is deterministic. Register transaction reads event and registration, enforces auth/open/approved/future/capacity/no active duplicate, creates or reactivates with fresh UUID, increments once.
- [ ] Cancellation transaction requires registered/future and decrements once without negative count.
- [ ] Check-in transaction validates QR/event/status, updates registration, and creates deterministic attendance.
- [ ] Declare the guarded `adminDelete` entry point; complete its media cleanup after `StorageService` is available in M07.

**acceptance:** inspect transaction read-before-write ordering and state transitions for duplicate register, full, past, cancel twice, re-register, wrong-event QR, duplicate scan.

**commit:** `M06 enforce event and registration invariants`

## M07 ENGAGEMENT_STORAGE_MAP_REPOSITORIES

**depends_on:** M04

**files:** refactor `lib/repositories/misc_repositories.dart` only if useful; create `gallery_repository.dart`, `contact_repository.dart`, `storage_service.dart`, `map_launcher_service.dart`; modify `lib/main.dart`.

- [ ] Implement every remaining registry interface.
- [ ] Deterministic favorites and feedback IDs.
- [ ] `sendOnce` skips existing deterministic notification.
- [ ] Registration/cancellation/announcement fan-out uses batch writes in safe Firestore batch sizes.
- [ ] Storage uploads compressed images to `profiles/{uid}/avatar.jpg`, `events/{ownerId}/{eventId}/cover.jpg`, `gallery/{eventId}/{uuid}.jpg`.
- [ ] Complete `EventRepository.adminDelete`: reject events with registrations; for a zero-registration event delete gallery Storage objects, gallery documents, the cover object, then the event document. Treat a missing Storage object as already deleted; surface every other failure readably.
- [ ] Directions URI uses `Uri` query parameters and launches externally; failure is readable.
- [ ] Register every repository/service with Provider in dependency order.

**acceptance:** focused pure test for directions URI; focused test for EventRepository filter if current test setup supports it; inspect provider resolution and deterministic IDs.

**commit:** `M07 add engagement storage and map services`

## M08 FIRESTORE_AND_STORAGE_SECURITY

**depends_on:** M05, M06, M07

**files:** replace `firestore.rules`; create `storage.rules`.

- [ ] User create is self/attendee/active; self update cannot alter role/active; admin manages roles and active status.
- [ ] Event create is owner organizer/admin, pending, zero count, valid latitude/longitude. Organizer edits only owned event and cannot approve. Admin system-wide.
- [ ] Registration ID, userId, and authenticated UID must match. Owner cancels only own active registration; owning organizer/admin checks in.
- [ ] Counter delta is exactly plus/minus one and tied as closely as Firestore Rules permit to the authenticated registration write.
- [ ] Favorites/feedback deterministic ownership. Feedback requires ended event, attended registration, rating 1-5.
- [ ] Notification recipient reads/marks own; self, event owner, or admin creates according to type.
- [ ] Gallery create requires ended owned event; owner/admin deletes. Contact create is self; admin reads.
- [ ] Storage paths enforce identity/event ownership, `image/*`, and size below 10 MB.
- [ ] Add Firebase indexes required by actual compound queries to `firestore.indexes.json` only when source queries require them.

**acceptance:** map every repository operation to one allow rule. Deployment/live probes remain blocked until M02 and explicit external authorization.

**commit:** `M08 enforce backend authorization boundaries`

## M09 AUTHENTICATION_SCREENS

**depends_on:** M03, M05

**files:** `lib/screens/auth/login_screen.dart`, `register_screen.dart`; create `blocked_account_screen.dart`.

- [ ] Login form, password visibility, forgot-password dialog, readable invalid credential state.
- [ ] Registration fields name/email/phone/password/confirm; organizer request switch; validations.
- [ ] AuthGate: splash/waiting, login, inactive blocked screen with logout, active role shell.
- [ ] Protected screens have no path that bypasses AuthGate.

**acceptance:** source trace covers SRS 1.6.1 and invalid-form/error states.

**commit:** `M09 complete authentication screens`

## M10 ROLE_ADAPTIVE_SHELL

**depends_on:** M03, M05

**files:** replace `lib/screens/shell.dart`; remove `lib/screens/stubs.dart` only after all destination classes exist.

- [ ] Under 600px use NavigationBar; 600px+ use NavigationRail.
- [ ] Attendee destinations: Home, Discover, My Events, Alerts, Profile.
- [ ] Organizer destinations: Organizer Home, Discover, My Events, Alerts, Profile.
- [ ] Admin destinations: Admin Home, Events, Users, Reports, Profile.
- [ ] Preserve selected index safely when live role changes alter destination list.
- [ ] Alerts icon displays unread badge for attendee/organizer.

**acceptance:** destination lists exactly match role; no more than five primary destinations; all route classes are real.

**commit:** `M10 implement adaptive role navigation`

## M11 ATTENDEE_HOME_DASHBOARD

**depends_on:** M06, M07

**files:** create `lib/screens/attendee/attendee_dashboard.dart`.

- [ ] Personalized greeting and next registered event.
- [ ] Sections for upcoming approved events, registered events, favorites, unread notifications.
- [ ] Quick actions to Discover, My Events, Favorites, Notifications.
- [ ] No recommendation algorithm; use chronological upcoming events.

**acceptance:** all four SRS attendee dashboard information groups are present with loading/empty/error states.

**commit:** `M11 add attendee home dashboard`

## M12 DISCOVERY_AND_FILTERS

**depends_on:** M06

**files:** create `lib/screens/attendee/discover_screen.dart`.

- [ ] SearchBar keyword filter; category FilterChips; date picker; location field; availability chip; Clear action.
- [ ] Approved upcoming event stream only.
- [ ] EventCard results and empty state that distinguishes no events from no filter matches.
- [ ] Tap opens M13 details.

**acceptance:** every SRS 1.6.3/1.6.4 filter maps to EventRepository.filter and Clear resets all state.

**commit:** `M12 implement event discovery and filtering`

## M13 EVENT_DETAILS_MAP_REGISTRATION

**depends_on:** M06, M07, M12

**files:** create `lib/screens/attendee/event_details_screen.dart`, `registration_confirmation_screen.dart`, `lib/widgets/event_map.dart`.

- [ ] Show banner, title, description, rules, date/time, address, organizer/contact, capacity/seats, status.
- [ ] OSM map with one marker, correct center, visible attribution, no prefetch.
- [ ] Directions action launches Google Maps URL externally.
- [ ] Favorite toggle reflects repository stream.
- [ ] Registration state drives Register button. Success writes confirmation notification and opens confirmation screen with QR action.
- [ ] Gallery preview appears only for completed events.

**acceptance:** happy path and full/duplicate/past/unapproved/network failure paths are explicit and readable.

**commit:** `M13 implement event details map and registration`

## M14 MY_EVENTS_AND_QR

**depends_on:** M06, M13

**files:** create `my_events_screen.dart`, `qr_pass_screen.dart`.

- [ ] Tabs: Upcoming, Completed, Cancelled. Join registration stream to event stream without direct Firestore.
- [ ] Open details from every row.
- [ ] QR shown for registered/attended records with event title/date and semantic description.
- [ ] Cancellation confirms and closes after event start.
- [ ] Generate one upcoming reminder within 24 hours when preference enabled.
- [ ] Generate one feedback request for attended completed events.

**acceptance:** classification, QR, cancel count restoration, and deterministic notification IDs are traceable.

**commit:** `M14 implement My Events QR and reminders`

## M15 FAVORITES_NOTIFICATIONS_FEEDBACK

**depends_on:** M07, M13, M14

**files:** create `favorites_screen.dart`, `feedback_screen.dart`, `lib/screens/shared/notifications_screen.dart`, `notification_details_screen.dart`.

- [ ] Favorites list, remove action, details navigation.
- [ ] Notification history newest first, unread styling, badge count; tapping opens notification details and marks the item read.
- [ ] Feedback only for completed attended event; 1-5 stars, optional comment, deterministic one submission.

**acceptance:** duplicate favorites/feedback impossible; empty/error/loading states complete.

**commit:** `M15 complete attendee engagement screens`

## M16 PROFILE_PREFERENCES_CONTACT

**depends_on:** M05, M07

**files:** create `lib/screens/shared/profile_screen.dart`, `contact_about_screen.dart`.

- [ ] Display/edit name, email read-only, phone, avatar, role.
- [ ] Avatar upload through StorageService; initials fallback.
- [ ] Change password with recent-login error handling.
- [ ] Reminder preference persists to user profile and shared_preferences cache.
- [ ] Organizer request action and pending state.
- [ ] Contact form name/email/subject/message; About content explains project purpose and displays contributor information from configuration.

**acceptance:** SRS 1.6.15 and 1.6.19 are fully represented.

**commit:** `M16 implement profile preferences and contact`

## M17 ORGANIZER_DASHBOARD_EVENT_FORM

**depends_on:** M06, M07

**files:** create `lib/screens/organizer/organizer_dashboard.dart`, `event_form_screen.dart`, `lib/widgets/location_picker.dart`.

- [ ] Dashboard lists only owned events with pending/approved/rejected/cancelled/completed status and participant counts.
- [ ] Structured form contains every SRS field and cover image.
- [ ] Generate event ID before cover upload. Picker uses OSM manual pin plus required address; no geocoding.
- [ ] Validate future start, end after start, positive capacity, non-zero coordinates.
- [ ] New event pending. Edit only owned/not-started. Critical approved edit returns event to pending review.

**acceptance:** create/edit ownership, status, image path, map coordinates, and critical-change behavior are explicit.

**commit:** `M17 implement organizer dashboard and event form`

## M18 ORGANIZER_PARTICIPANTS_ANNOUNCEMENTS_FEEDBACK

**depends_on:** M17

**files:** create `participants_screen.dart`, `announcements_screen.dart`, `organizer_feedback_screen.dart`.

- [ ] Participant list joins user identity to registrations; counts registered/attended/cancelled.
- [ ] Announcement form sends to non-cancelled registrants.
- [ ] Feedback list and average rating for owned event only.
- [ ] Cancellation request requires reason and enters admin review; organizer cannot directly cancel approved event.

**acceptance:** all reads/writes are scoped to owned event and readable failures.

**commit:** `M18 implement organizer participant communication`

## M19 QR_SCANNER_AND_GALLERY

**depends_on:** M07, M17

**files:** create `scanner_screen.dart`, `gallery_upload_screen.dart`, `lib/screens/shared/gallery_screen.dart`.

- [ ] MobileScanner permission/loading/error states.
- [ ] Scan lock prevents duplicate callbacks; valid/wrong-event/cancelled/already-attended/invalid overlays; reset after acknowledgement.
- [ ] Gallery upload only owned completed event; compressed image and optional caption.
- [ ] Shared gallery grid supports completed-event browsing.

**acceptance:** scanner calls only RegistrationRepository; gallery calls only Gallery/Storage services.

**commit:** `M19 implement attendance scanner and gallery`

## M20 ADMIN_DASHBOARD_APPROVALS

**depends_on:** M06, M07, M17

**files:** create `lib/screens/admin/admin_dashboard.dart`, `approvals_screen.dart`.

- [ ] Dashboard summary of users/events/pending/cancellation requests/registrations.
- [ ] Approve/reject pending event with confirmation and organizer notification.
- [ ] Approval of `changeReviewPending` sends event-change notification to registrants and clears flag.
- [ ] Approve cancellation sets cancelled and notifies registrants; reject request clears request fields.

**acceptance:** organizer cannot self-approve; each admin decision has notification behavior.

**commit:** `M20 implement admin dashboard and approvals`

## M21 ADMIN_EVENT_MANAGEMENT

**depends_on:** M20

**files:** create `lib/screens/admin/events_screen.dart`; reuse organizer event form in admin mode.

- [ ] View/search/filter all events and open registrations/basic stats.
- [ ] Edit event in admin mode.
- [ ] Cancel with reason and notification fan-out.
- [ ] Permanently remove only zero-registration event; confirmation states media deletion consequence.
- [ ] Moderate gallery images with confirmation.

**acceptance:** remove guard preserves event history; admin scope is explicit.

**commit:** `M21 implement admin event moderation`

## M22 ADMIN_USER_MANAGEMENT

**depends_on:** M05, M20

**files:** create `lib/screens/admin/users_screen.dart`.

- [ ] View/search by name/email.
- [ ] Activate/deactivate with confirmation; prevent current admin self-deactivation.
- [ ] Approve organizer request by role change and roleApproved notification.
- [ ] Role assignment dropdown; passwords never displayed.

**acceptance:** role/active changes propagate live through AuthService.userStream.

**commit:** `M22 implement admin user and role management`

## M23 REPORTS_AND_STATISTICS

**depends_on:** M06, M07, M20

**files:** create `lib/screens/admin/stats_screen.dart`.

- [ ] Material 3 cards/lists: total events, total registrations, total attendees, total users, popular top three events, event-wise attendance, average rating.
- [ ] Compute from repository streams; zero-safe averages; no advanced chart library.
- [ ] Loading/error/empty states for aggregate inputs.

**acceptance:** formulas are documented in code and reconcile with M28 seed counts.

**commit:** `M23 implement reports and statistics`

## M24 SHELL_INTEGRATION

**depends_on:** M09-M23

**files:** `lib/screens/shell.dart`, `lib/main.dart`; delete `lib/screens/stubs.dart`.

- [ ] Wire all role destinations and secondary routes.
- [ ] Register all providers/services exactly once.
- [ ] Remove all stub imports/classes and dead navigation.
- [ ] Ensure role change rebuild does not produce invalid selected index.

**acceptance:** `rg "Stub|stubs.dart" lib` returns no matches; `rg "cloud_firestore|firebase_auth|firebase_storage" lib/screens` returns no imports.

**commit:** `M24 integrate complete role application shell`

## M25 NOTIFICATION_EVENT_MATRIX

**depends_on:** M13-M22

**files:** repository call sites across implemented modules only.

- [ ] Registration -> confirmation to attendee.
- [ ] Within 24h -> deterministic reminder to attendee when enabled.
- [ ] Approved critical change -> eventChanged to active registrants.
- [ ] Approved cancellation -> cancelled to active/attended registrants.
- [ ] Organizer announcement -> announcement to active/attended registrants.
- [ ] Attended completed event -> deterministic feedbackRequest.
- [ ] Approve/reject -> decision to organizer.
- [ ] Organizer promotion -> roleApproved to user.

**acceptance:** each type has exactly one writer path and appears in notification history.

**commit:** `M25 complete notification lifecycle matrix`

## M26 NON_FUNCTIONAL_AND_MATERIAL3_AUDIT

**depends_on:** M24, M25

**files:** all changed Dart source; no new feature files.

- [ ] Performance: avoid nested unbounded streams, duplicate reads, unnecessary rebuilds; cache non-critical Firestore reads normally.
- [ ] Reliability: every Future action guards mounted context; errors are readable; no crash-only path.
- [ ] Offline behavior: cached non-critical lists remain readable where Firestore cache permits; registration and check-in fail safely with a clear connectivity-required message.
- [ ] Accessibility: semantic labels/tooltips, focus order, 48dp targets, readable contrast, text scale 1.3.
- [ ] Material 3: token colors/type, tonal surfaces, correct component variants, no raw semantic colors/shadows, responsive NavigationBar/Rail, width constraints.
- [ ] Image optimization and map attribution remain intact.
- [ ] Maintainability: focused files, no direct Firebase screens, no duplicated repository logic, no unfinished markers/print statements.

**acceptance:** source audit records no unresolved critical item. Do not perform browser or visual runtime validation.

**commit:** `M26 complete nonfunctional and Material 3 audit`

## M27 FOCUSED_TEST_SUITE

**depends_on:** M26

**files:** replace placeholder `test/widget_test.dart`; add only focused tests supported without broad new infrastructure.

- [ ] Authentication form validation widget tests for invalid inputs.
- [ ] Event filter tests for query/category/date/location/availability/clear behavior.
- [ ] Event derived-state/model tests for seats/start/end/completion.
- [ ] Google directions URI test.
- [ ] Pure notification ID/type mapping tests if extracted to stable helpers.
- [ ] Do not add fake Firebase infrastructure solely to raise test count. Record transaction/rules flows for manual M29 checks.

**acceptance:** run only the focused `flutter test <specific test files>` commands; report exact pass/fail results. No typecheck/build.

**commit:** `M27 add focused regression coverage`

## M28 DEMO_DATA_SPECIFICATION

**depends_on:** M24

**files:** create `docs/test-data.md`, `DEMO_CREDENTIALS.md`; no production seeder unless explicitly requested.

- [ ] Three non-personal demo accounts: attendee, organizer, admin.
- [ ] At least 12 events across all eight categories with approved/pending/rejected/cancelled/full/completed states and valid coordinates.
- [ ] Active/cancelled/attended registrations, QR, favorites, feedback, every notification type, announcement, gallery images, organizer request.
- [ ] Exact expected statistics for M23 reconciliation.
- [ ] Create data through UI; only first admin role is manual console edit.

**acceptance:** recording sequence can run without mutating dates/roles mid-video.

**commit:** `M28 document deterministic demonstration data`

## M29 SRS_ACCEPTANCE_MATRIX

**depends_on:** M24-M28, M02 runtime availability

**files:** create `docs/test-results.md`.

- [ ] Authentication: valid login, invalid login, registration, logout, reset/change password, inactive account.
- [ ] Events: create, edit, critical reapproval, approve, reject, cancellation request/decision, search, every filter, details, map/directions.
- [ ] Registration: success, duplicate, capacity, cancellation, re-registration, past/unapproved rejection.
- [ ] QR: generation, valid scan, wrong event, invalid pass, cancelled pass, duplicate check-in.
- [ ] Feedback: valid submit, duplicate prevention, organizer display, admin average.
- [ ] Notifications: registration, reminder, change, cancellation, announcement, feedback request, approval/rejection, role promotion.
- [ ] Roles: attendee, organizer ownership, admin privileges, direct forbidden operations.
- [ ] Errors: no network for critical write, empty data, invalid forms, backend denial.
- [ ] SRS steps 8-19 in exact order.

**acceptance:** every line has PASS, FAIL, or BLOCKED with observed evidence. Never convert unrun behavior to PASS.

**commit:** `M29 record SRS acceptance evidence`

## M30 DELIVERABLES_AND_RELEASE_GATE

**depends_on:** M29

**files:** `README.md`; `docs/problem-definition.md`, `design-specification.md`, `use-case.md`, `sitemap.md`, `erd.md`, `database-design.md`; submission artifacts.

- [ ] Documentation reflects actual architecture, screens, Material 3 system, Firebase rules, OSM map, Google directions, assumptions, test evidence, and the Firestore/Storage backup-export and restore strategy. Academic documents contain no source code.
- [ ] README contains installation, Firebase configuration, assumptions, run instructions, and build instructions without executing a build.
- [ ] APK command remains blocked until explicit current-message build authorization. After authorization: produce release APK, install on target Android device, smoke test login/details/map/register/QR.
- [ ] Record mandatory MP4 in order: 8 splash/login; 9 attendee; 10 browse/search; 11 details/map; 12 register; 13 My Events/QR; 14 organizer create/map pin; 15 admin approve; 16 participants/check-in; 17 feedback; 18 notifications/gallery; 19 stats/user/event management.
- [ ] Package source, docs, test data, demo credentials, APK, and MP4 with backup copies.

**acceptance:** every SRS 1.9 deliverable exists; APK and MP4 evidence is honest and explicit.

**commit:** `M30 finalize EventEase submission artifacts`

## TERMINAL_CONDITION

Implementation is complete only when M00-M30 are checked and M29 contains no unresolved FAIL for a mandatory requirement. A BLOCKED item is not complete. Do not claim the application, APK, or video is complete without direct evidence.
