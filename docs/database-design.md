# EventEase Database Design

## 5.1 Overview
The backend is **Firebase**: Firebase Authentication (credentials), Cloud
Firestore (structured data), and Firebase Storage (images). There is no
relational database. All authorization is enforced in **Firebase Security
Rules**, never only in the Flutter client.

| Collection / Bucket | Purpose |
|---------------------|---------|
| Authentication (Firebase Auth) | Email/password credentials only; passwords never stored in Firestore |
| `users/{uid}` | User profiles and roles |
| `events/{eventId}` | Events authored by organizers |
| `registrations/{userId}_{eventId}` | Attendee registrations / QR passes |
| `attendance/{userId}_{eventId}` | Check-in records (1:1 with registration) |
| `favorites/{userId}_{eventId}` | Attendee favorites |
| `feedback/{userId}_{eventId}` | Attendee feedback (1–5) |
| `notifications/{docId}` | In-app notifications (no FCM) |
| `gallery/{mediaId}` | Event gallery image references |
| `contactMessages/{messageId}` | Contact form submissions |
| Storage `profiles/{userId}/avatar.jpg` | Profile photos |
| Storage `events/{ownerId}/{eventId}/cover.jpg` | Event cover images |
| Storage `gallery/{eventId}/{uuid}.jpg` | Gallery media |

## 5.2 users/{uid}
| Field | Type | Notes |
|-------|------|-------|
| (id) | string | Firebase Auth `uid` (document id) |
| name | string | |
| email | string | |
| phone | string | |
| role | string | `attendee` on signup; admin may set `organizer`/`admin` |
| profileImageUrl | string? | |
| active | boolean | `true` on signup; admin may deactivate |
| organizerRequested | boolean | set on signup if user opts in |
| remindersEnabled | boolean | `true` on signup |
| createdAt | timestamp | server timestamp |

## 5.3 events/{eventId}
| Field | Type | Notes |
|-------|------|-------|
| organizerId | string | `users.id`; the only writer besides admin |
| title | string | |
| description | string | |
| category | string | one of 8 fixed categories |
| location | string | human address; required when editing via form |
| latitude | number | valid coordinates required on create |
| longitude | number | valid coordinates required on create |
| rules | string | |
| contactInfo | string | |
| startTime | timestamp | must be future on create; end after start |
| endTime | timestamp | |
| maxParticipants | integer | must be positive |
| registeredCount | integer | mutated only by registration/cancel transactions |
| status | string | pending / approved / rejected / cancelled / completed |
| imageUrl | string? | Storage cover path |
| cancellationRequested | boolean | organizer requests cancellation here |
| cancellationReason | string? | |
| changeReviewPending | boolean | set true on critical edit of approved event |
| createdAt | timestamp | server timestamp on create |
| updatedAt | timestamp | server timestamp on every update |

## 5.4 registrations/{userId}_{eventId}
| Field | Type | Notes |
|-------|------|-------|
| (id) | string | deterministic `userId_eventId` |
| eventId | string | |
| userId | string | |
| status | string | registered / cancelled / attended |
| qrCode | string | unique UUID v4, regenerated on reactivation |
| registeredAt | timestamp | |
| checkedInAt | timestamp? | |
| participantName | string | snapshot of user name at registration |
| participantEmail | string | snapshot of user email |

## 5.5 attendance/{userId}_{eventId}
| Field | Type | Notes |
|-------|------|-------|
| (id) | string | deterministic `userId_eventId` (1:1 with registration) |
| registrationId | string | |
| eventId | string | |
| userId | string | |
| attended | boolean | `true` on check-in |
| checkedInAt | timestamp | |

## 5.6 favorites/{userId}_{eventId}, feedback/{userId}_{eventId}
| Collection | Field | Type |
|------------|-------|------|
| favorites | userId | string |
| favorites | eventId | string |
| favorites | createdAt | timestamp |
| feedback | eventId | string |
| feedback | userId | string |
| feedback | rating | integer (1–5) |
| feedback | comment | string |
| feedback | submittedAt | timestamp |

## 5.7 notifications/{docId}
| Field | Type | Notes |
|-------|------|-------|
| userId | string | recipient |
| eventId | string? | |
| type | string | one of 9 notification types |
| title | string | |
| message | string | |
| isRead | boolean | |
| createdAt | timestamp | server timestamp |

## 5.8 gallery/{mediaId}, contactMessages/{messageId}
| gallery mediaId | eventId, uploadedBy, imageUrl, caption?, uploadedAt |
| contactMessages messageId | userId, name, email, subject, message, submittedAt |

## 5.9 Indexes (firestore.indexes.json)
Composite indexes are declared only for the queries actually issued:
- `events`: status ASC, startTime ASC
- `notifications`: userId ASC, createdAt DESC
- `notifications`: userId ASC, isRead ASC
- `registrations`: eventId ASC, status ASC
- `gallery`: eventId ASC, uploadedAt DESC

## 5.10 Rules Enforcement Map
Every repository write maps to a Firestore allow rule:
- `users` create: self, attendee, active, email matches auth.
- `users` update: self (role/active immutable) or admin.
- `events` create: organizer/admin, pending, count 0, valid coords.
- `events` update: admin system-wide; organizer owner-only (cannot approve,
  cannot change count/createdAt, critical edit flips to pending).
- Counter delta: exactly ±1, tied to the authenticated registration write.
- `registrations` create: UID + deterministic ID match.
- `registrations` update: owner cancels own active pass; owner/admin checks in.
- `attendance` create: admin/owning organizer, deterministic ID.
- `favorites`/`feedback`: deterministic ownership; feedback requires ended event
  + attended registration + rating 1–5.
- `notifications`: recipient reads/marks own; self/event-owner/admin create by type.
- `gallery` create: ended owned event; owner/admin deletes.
- `contactMessages`: self-create; admin read.
- Storage: identity/event-owned paths, `image/*`, < 10 MB.

## 5.11 Consistency & Concurrency
- Seat count never trusts the client; it is incremented/decremented inside
  Firestore transactions (read-before-write), preventing race conditions.
- Duplicate registration, check-in, favorite, and feedback are prevented by
  deterministic document IDs and `runTransaction` existence checks.
- `sendOnce` creates a notification only if its deterministic ID is absent.
