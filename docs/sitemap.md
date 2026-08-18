# EventEase Sitemap

## Routes & Screens

```
AuthGate (lib/main.dart)
├── Splash (LoadingView) during Firebase init
├── LoginScreen                  (lib/screens/auth/login_screen.dart)
├── RegisterScreen               (lib/screens/auth/register_screen.dart)
├── BlockedAccountScreen         (lib/screens/auth/blocked_account_screen.dart)
└── HomeShell                    (lib/screens/shell.dart)
    ├── ATTENDEE / ORGANIZER (shared)
    │   ├── Home / Organizer Home  → attendee_dashboard.dart / organizer_dashboard.dart
    │   ├── Discover               → discover_screen.dart
    │   ├── My Events              → my_events_screen.dart
    │   ├── Alerts                 → notifications_screen.dart
    │   └── Profile                → shared/profile_screen.dart
    ├── ATTENDEE only
    │   ├── Event Details           → attendee/event_details_screen.dart
    │   ├── Registration Confirmation → attendee/registration_confirmation_screen.dart
    │   ├── QR Pass                 → attendee/qr_pass_screen.dart
    │   ├── Favorites               → attendee/favorites_screen.dart
    │   ├── Feedback                → attendee/feedback_screen.dart
    │   ├── Notification Detail     → shared/notification_details_screen.dart
    │   ├── Gallery                 → shared/gallery_screen.dart
    │   └── Contact / About         → shared/contact_about_screen.dart
    └── ADMIN only
        ├── Stats / Reports         → admin/stats_screen.dart
        ├── Approvals               → admin/approvals_screen.dart
        ├── Events                  → admin/events_screen.dart
        └── Users                   → admin/users_screen.dart / user_details_screen.dart

ORGANIZER detail flows (secondary routes, pushed on top of HomeShell)
├── Organizer Event Details       → organizer/organizer_event_details_screen.dart
├── Event Form (create/edit)      → organizer/event_form_screen.dart
├── Participants                  → organizer/participants_screen.dart
├── Announcements                 → organizer/announcements_screen.dart
├── Organizer Feedback            → organizer/organizer_feedback_screen.dart
├── Scanner (QR check-in)         → organizer/scanner_screen.dart
└── Gallery Upload                → organizer/gallery_upload_screen.dart
```

## Adaptive Navigation

| Role       | Destinations (primary, max 5)                                  |
|------------|----------------------------------------------------------------|
| Attendee   | Home, Discover, My Events, Alerts, Profile                     |
| Organizer  | Organizer Home, Discover, Manage Events, Alerts, Profile       |
| Admin      | Admin Home, Events, Users, Reports, Profile                    |

- `NavigationBar` below 600 logical px; `NavigationRail` at 600 px+.
- The Alerts icon shows an unread-count badge for attendee/organizer.
- Role changes reset the selected index to 0 to stay within the new destination
  list; no destination is ever out of range.

## Navigation Rules
- Unauthenticated users cannot reach any protected screen (`AuthGate` guard).
- Admin-only destinations are only present in the admin destination list.
- Destructive actions (cancel registration, delete event, deactivate user)
  require a confirmation dialog.
