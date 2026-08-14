# EventEase Test Data Specification (M28)

## Demo Accounts

| Role | Email | Password | Name |
|------|-------|----------|------|
| Attendee | attendee@eventease.demo | Test123! | Alex Attendee |
| Organizer | organizer@eventease.demo | Test123! | Olivia Organizer |
| Admin | admin@eventease.demo | Test123! | Adam Admin |

**Setup:** Create the first two accounts through the app registration. Set the admin account role manually in Firestore console (`users/{uid}` → `role: "admin"`).

## Events (12+ across all 8 categories)

| # | Title | Category | Status | Location | Coordinates | Capacity | Date |
|---|-------|----------|--------|----------|-------------|----------|------|
| 1 | Flutter Workshop | Technology | approved | Karachi | 24.8607, 67.0011 | 50 | Tomorrow + 2h |
| 2 | AI Conference | Technology | approved | Lahore | 31.5204, 74.3587 | 200 | Tomorrow + 1d |
| 3 | Python Bootcamp | Education | pending | Islamabad | 33.6844, 73.0479 | 30 | +3d |
| 4 | Data Science Talk | Education | approved | Karachi | 24.8607, 67.0011 | 40 | +4d |
| 5 | Football Tournament | Sports | approved | Lahore | 31.5204, 74.3587 | 100 | +2d |
| 6 | Yoga Session | Sports | rejected | Karachi | 24.8607, 67.0011 | 20 | +5d |
| 7 | Jazz Night | Music | approved | Karachi | 24.8607, 67.0011 | 80 | +3d |
| 8 | Classical Concert | Music | cancelled | Lahore | 31.5204, 74.3587 | 60 | +6d |
| 9 | Startup Pitch | Business | approved | Islamabad | 33.6844, 73.0479 | 30 | +2d |
| 10 | Marketing Summit | Business | pending | Karachi | 24.8607, 67.0011 | 150 | +7d |
| 11 | Hackathon | Workshop | approved | Lahore | 31.5204, 74.3587 | 50 | +4d |
| 12 | Design Sprint | Workshop | approved | Karachi | 24.8607, 67.0011 | 25 | +5d |
| 13 | Community Meetup | Community | approved | Karachi | 24.8607, 67.0011 | 100 | +1d |
| 14 | Tech Conference | Conference | approved | Lahore | 31.5204, 74.3587 | 500 | +8d |
| 15 | Full Event (for capacity test) | Conference | approved | Karachi | 24.8607, 67.0011 | 2 | +1d |

## Registrations

- Alex Attendee registered for: Flutter Workshop, Jazz Night, Startup Pitch, Full Event
- Alex attended: Community Meetup (checked in)
- Alex cancelled: Hackathon registration
- Olivia Organizer registered for: AI Conference

## Favorites

- Alex Attendee favorites: Flutter Workshop, AI Conference, Jazz Night

## Feedback

- Alex Attendee on Community Meetup: rating 5, "Great community event!"
- Alex Attendee on Flutter Workshop: rating 4, "Very informative."

## Notifications

Types present: registration, reminder, eventChanged, cancelled, announcement, feedbackRequest, approval, rejection, roleApproved

## Gallery

- 2 images in Community Meetup gallery (uploaded by Olivia Organizer)

## Expected Statistics (for M23 reconciliation)

- Total events: 15
- Total registrations: 6 (Alex: 4 active + 1 cancelled, Olivia: 1)
- Total attendees (checked in): 1
- Total users: 3
- Top 3 events: Flutter Workshop (1), Jazz Night (1), Startup Pitch (1) — tied, order by creation
- Average rating: (5 + 4) / 2 = 4.5
