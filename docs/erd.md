# EventEase Entity-Relationship Diagram

Firestore is a document database; relationships are expressed through
deterministic document IDs and denormalized references rather than foreign
keys. The diagram below is an entity-relationship description of the logical
collections.

## Entities

```
                    ┌──────────────────────────────────────────────┐
                    │ USERS  (users/{uid})                         │
                    │  id (uid = document id)                      │
                    │  name, email, phone, role                   │
                    │  profileImageUrl?, active, organizerRequested│
                    │  remindersEnabled, createdAt                  │
                    │  role ∈ {attendee, organizer, admin}       │
                    └──────────────────────────────────────────────┘
                           ▲                                  │ owns
                           │ uid == organizerId
                           │                                  ▼
┌──────────────┐   owns    └────────────────────────────┐  ┌──────────────────────────────────┐
│ FAVORITES    │◀────────┤ EVENTS  (events/{eventId})   │  │ REGISTRATIONS  (registrations/{   │
│ favorites/{  │           │  id, organizerId, title     │  │   userId}_{eventId})             │
│  userId}_{  │           │  description, category      │  │  eventId, userId, status         │
│  eventId})  │           │  location, latitude,        │  │  qrCode, registeredAt,            │
│  userId,    │           │  longitude, maxParticipants,│  │  checkedInAt?, participantName,  │
│  eventId,   │           │  registeredCount, status    │  │  participantEmail                 │
│  createdAt  │           │  status ∈ pending/approved/ │  │  status ∈ registered/cancelled/   │
│              │           │  rejected/cancelled/completed│  │  attended                          │
└──────────────┘           │  cancellationRequested,    │  │                                  │
                           │  cancellationReason?,       │  │  id (deterministic:               │
                           │  changeReviewPending,        │  │   userId_eventId)                │
                           │  imageUrl?, rules,           │  │                                  │
                           │  contactInfo, createdAt,    │  └──────────────▲───────────────────┘
                           │  updatedAt                   │                 │ 1..1
                           └──────────────▲──────────────┘                 │ checks-in
                                          │ 1..*                           │
                                          │ owns                          │ 1..1
                              ┌───────────┴──────────────┐  ┌──────────────┴───────────────┐
                              │ GALLERY  (gallery/{mediaId})│  │ ATTENDANCE (attendance/{     │
                              │  eventId, uploadedBy,      │  │   userId}_{eventId})         │
                              │  imageUrl, caption?,       │  │  registrationId, eventId,    │
                              │  uploadedAt                 │  │  userId, attended,           │
                              └──────────────────────────┘  │  checkedInAt                  │
                                                          └───────────────────────────────┘
```

```
                    ┌──────────────────────────────────────────────┐
                    │ FEEDBACK  (feedback/{userId}_{eventId})      │
                    │  eventId, userId, rating (1..5), comment?    │
                    │  submittedAt                                  │
                    └──────────────────────────────────────────────┘
                          │ ownsEvent
                          │
                    ┌─────▼──────┐
                    │ EVENTS     │ (same EVENTS entity)

                    ┌──────────────────────────────────────────────┐
                    │ NOTIFICATIONS (notifications/{autoId})       │
                    │  userId, eventId?, type, title, message,     │
                    │  isRead, createdAt                           │
                    └──────────────────────────────────────────────┘

                    ┌──────────────────────────────────────────────┐
                    │ CONTACT MESSAGES (contactMessages/{messageId})│
                    │  userId, name, email, subject, message,      │
                    │  submittedAt                                  │
                    └──────────────────────────────────────────────┘
```

## Relationship Summary

| From | To | Cardinality | Mechanism |
|------|----|-------------|-----------|
| User (attendee) | Event | M:N | Favorites docs `userId_eventId` |
| User (attendee) | Event | M:N | Registrations docs `userId_eventId` |
| Registration | Attendance | 1:1 | shared deterministic ID `userId_eventId` |
| User (organizer) | Event | 1:M | `events.organizerId == users.id` |
| User (organizer) | Gallery | 1:M | `gallery.uploadedBy` / `gallery.eventId` |
| User (attendee) | Feedback | M:N | Feedback docs `userId_eventId` |
| Event | Feedback | 1:M | `feedback.eventId` |
| Event | Registration | 1:M | `registrations.eventId` |
| Event | Gallery | 1:M | `gallery.eventId` |
| User | Notification | 1:M | `notifications.userId` |
| User | ContactMessage | 1:M | `contactMessages.userId` |

## Deterministic IDs (duplicate prevention by design)
- `registrations/{userId}_{eventId}`
- `favorites/{userId}_{eventId}`
- `feedback/{userId}_{eventId}`
- `attendance/{userId}_{eventId}`
- `notifications/{sendOnce docId}` (caller-supplied; `sendOnce` skips existing)
