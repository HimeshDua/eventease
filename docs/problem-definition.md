# EventEase Problem Definition

## 1.1 Purpose

Manual event management for communities, organizers, and attendees is fragmented:
events are spread across flyers, social posts, and email threads; attendance is
recorded by hand; and there is no single source of truth for who registered,
who attended, or whether an event is still on.

**EventEase** is a cross-platform mobile application that gives each role a
single, trusted place to discover events, register with a scannable QR pass,
check attendance, and receive in-app notifications — backed by Firebase
Authentication, Cloud Firestore, and Firebase Storage.

## 1.2 Scope

The product has exactly three roles: **Attendee**, **Organizer**, and
**Administrator**.

### In scope
- Event discovery, search, and category/location/date/availability filtering.
- Event detail view with an embedded **OpenStreetMap** marker and an external
  **Google Maps directions** action.
- Attendee registration producing a **QR pass** (`qr_flutter` + `mobile_scanner`).
- Organizer creation/edit of events, participant list, announcements, QR
  scan check-in, and gallery upload.
- Administrator approval/rejection of events, user/role management, gallery
  moderation, and aggregate statistics.
- In-app notifications stored in Firestore (no FCM push).
- Favorites, feedback (1–5 stars), profile, and a Contact/About screen.

### Out of scope (per SRS)
Payments, live streaming, social feeds, recommendation engines, Google Places /
geocoding APIs, in-app routing, Google Maps SDK, Supabase, REST backends,
Node.js/Laravel backends, multilingual support, certificates, and waitlists.

## 1.3 Key Problems Solved
1. **Discovery fragmentation** → one curated, approved event feed.
2. **Manual attendance** → QR pass generation and scan-to-check-in.
3. **Seat overbooking** → a Firestore transaction that increments a
   `registeredCount` counter atomically, with duplicate-registration prevention.
4. **Event trust** → a mandatory admin approval step before an event is visible.
5. **Information asymmetry** → real-time in-app notifications for registration,
   reminders, changes, cancellations, approvals, and feedback requests.

## 1.4 Definitions, Acronyms, and Abbreviations
- **SRS** — Software Requirements Specification for EventEase.
- **OSM** — OpenStreetMap, used for embedded event-location maps.
- **QR** — Quick Response barcode encoding the registration pass identifier.
- **M00–M30** — Implementation modules defined in `PLAN.md`.

## 1.5 References
- `Cross-platform App Development SRS.pdf` (EventEase, Aptech/Contest-AZM) — product authority.
- `PLAN.md` — implementation specification and module graph.
- `AGENTS.md` — architecture and engineering principles.

## 1.6 Overview
The remainder of this document set describes the architecture, use cases,
navigation, data model, and database design. Operational instructions, demo
credentials, and acceptance evidence live in `README.md`, `DEMO_CREDENTIALS.md`,
`docs/test-data.md`, and `docs/test-results.md`.
