# EventEase Demo Credentials

These accounts are used for the demonstration recorded for SRS steps 8–19. They are
non-personal and are the only credentials required to run the demo video.

| Role      | Email                   | Password | Display name     |
| --------- | ----------------------- | -------- | ---------------- |
| Attendee  | attendee@eventease.demo | `Test123!` | Alex Attendee   |
| Organizer | organizer@eventease.demo | `Test123!` | Olivia Organizer |
| Admin     | admin@eventease.demo    | `Test123!` | Adam Admin      |

## Setup (one-time, performed before recording)

The application cannot bootstrap the first administrator through the UI. The
first account is therefore promoted manually once, inside the Firebase console.

1. Register the **Attendee** and **Organizer** accounts through the EventEase
   app registration screen (they are created as `attendee` by default; the
   organizer account sets the **Request organizer access** switch so its
   `organizerRequested` flag is `true`).
2. Register the **Admin** account through the app registration screen.
3. In the Firebase console, open **Firestore Database** → `users` collection,
   open the Admin account document, and set:
   - `role` = `admin`
   - `organizerRequested` = `false`
4. Approve the Organizer's request from the Admin → Users screen (this sets
   `role` = `organizer`, `organizerRequested` = `false`) so the organizer can
   create events during the demo.

> Do **not** commit real project service-account keys, API keys, or passwords to
> the repository. `lib/firebase_options.dart` contains only the public Firebase
> SDK configuration (API key, project ID) which is safe to ship.
