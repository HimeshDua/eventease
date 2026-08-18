# EventEase Use Cases

## Actors
- **Attendee** — browses, registers, checks in via QR, favorites, gives feedback,
  reads notifications, edits profile.
- **Organizer** — creates/edits own events, manages participants, scans
  check-ins, sends announcements, uploads gallery, reads feedback, requests
  cancellation.
- **Administrator** — approves/rejects events, approves cancellations, manages
  users/roles, moderates gallery, views statistics.

## 1. Authentication (SRS 1.6.1)
| # | Actor | Use case |
|---|-------|----------|
| 1 | Unauthenticated | Register (attendee default; optional organizer request) |
| 2 | Unauthenticated | Login with email/password |
| 3 | Unauthenticated | Reset password via email link |
| 4 | Attendee/Organizer/Admin | Change password (re-authenticates first) |
| 5 | Attendee/Organizer/Admin | Logout |
| 6 | Signed-in (Auth) but no profile | Shown a recovery error with logout |
| 7 | Inactive account | Blocked screen with logout |

## 2. Event Discovery (1.6.2, 1.6.3)
| # | Actor | Use case |
|---|-------|----------|
| 8 | Attendee/Organizer | Browse approved, upcoming events |
| 9 | Attendee/Organizer | Filter by keyword, category, date, location, availability |
| 10 | Attendee/Organizer | Clear all filters |

## 3. Event Details & Registration (1.6.4–1.6.6)
| # | Actor | Use case |
|---|-------|----------|
| 11 | Attendee/Organizer | View details, banner, OSM map, organizer/contact |
| 12 | Attendee/Organizer | Open external Google Maps directions |
| 13 | Attendee | Toggle favorite |
| 14 | Attendee | Register (QR pass created) → confirmation screen |
| 15 | Attendee | Cancel an upcoming registration |
| 16 | Attendee | View issued QR pass |

## 4. My Events (1.6.8)
| # | Actor | Use case |
|---|-------|----------|
| 17 | Attendee | List upcoming / completed / cancelled registrations |
| 18 | Attendee | Open event details from a registration row |

## 5. Favorites, Notifications, Feedback (1.6.8, 1.6.9, 1.6.13)
| # | Actor | Use case |
|---|-------|----------|
| 19 | Attendee | List/remove favorites; open details |
| 20 | Attendee | View notifications (newest first, unread styling) |
| 21 | Attendee | Mark notification read; open detail |
| 22 | Attendee | Submit feedback (1–5 stars) for a completed, attended event |
| 23 | Attendee | Receive deterministic reminder (<24h) when enabled |
| 24 | Attendee | Receive feedback request for attended completed events |

## 6. Profile, Contact (1.6.15, 1.6.19)
| # | Actor | Use case |
|---|-------|----------|
| 25 | Attendee/Organizer | Edit name, phone, avatar (upload via StorageService) |
| 26 | Attendee/Organizer | Change password |
| 27 | Attendee/Organizer | Toggle reminder preference (Firestore + shared_preferences) |
| 28 | Attendee/Organizer | Request organizer access |
| 29 | Attendee/Organizer | Submit a contact message |
| 30 | Unauthenticated | View About (purpose, contributors) |

## 7. Organizer (1.6.11, 1.6.12, 1.6.18)
| # | Actor | Use case |
|---|-------|----------|
| 31 | Organizer | View dashboard (owned events, status, participant counts) |
| 32 | Organizer | Create event (OSM pin + required address, future start) |
| 33 | Organizer | Edit own, not-started event; critical edit → pending review |
| 34 | Organizer | View participants (registered/attended/cancelled) |
| 35 | Organizer | Send announcement to non-cancelled registrants |
| 36 | Organizer | View feedback + average rating for owned event |
| 37 | Organizer | Request cancellation (reason) for admin review |
| 38 | Organizer | Scan QR for attendance check-in |
| 39 | Organizer | Upload gallery for completed owned event |

## 8. Administrator (1.6.14, 1.6.16, 1.6.17)
| # | Actor | Use case |
|---|-------|----------|
| 40 | Administrator | Approve pending event → notify organizer |
| 41 | Administrator | Reject pending event → notify organizer |
| 42 | Administrator | Approve critical-change event → notify registrants |
| 43 | Administrator | Approve/reject cancellation request |
| 44 | Administrator | Cancel event with reason → notify registrants |
| 45 | Administrator | Delete only zero-registration events (keeps history otherwise) |
| 46 | Administrator | Approve organizer requests → roleApproved notification |
| 47 | Administrator | Promote/demote roles; activate/deactivate (not self) |
| 48 | Administrator | Moderate gallery images |
| 49 | Administrator | View reports (totals, popular events, attendance, avg rating) |

## 9. System
| # | Actor | Use case |
|---|-------|----------|
| 50 | All | Consistent loading / empty / error states |
| 51 | All | Friendly, non-crashing error messages |
| 52 | All | Offline cache for non-critical reads; connectivity required for writes |
