# EventEase P0 Security/Integration Fixes — Progress Tracker

**Started:** 2026-08-18
**Goal:** Complete all 12 P0 items, then run analyze/tests, audit, and finalize.

---

## P0 Items

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | storage.rules — gallery/cover/admin/type+size | pending | Need to harden gallery write path + image constraints |
| 2 | firestore.rules — registeredCount tied to registration transition | pending | Must be in same transaction as registration status change |
| 3 | firestore.rules — registration create/update hardening | pending | Event exists, approved, not started/cancelled, capacity, userId/eventId, immutable fields, status transitions |
| 4 | firestore.rules — attendance hardening | pending | Verify registration exists, userId/eventId match, registered status, organizer owns event |
| 5 | firestore.rules — feedback hardening | pending | Verify registration attended, userId match, rating 1-5, deterministic ID |
| 6 | firestore.rules — user hardening | pending | Self updates limited to allowed fields, protect email/role/active/createdAt, admin self-protection |
| 7 | firestore.rules — event hardening | pending | Protect status/cancellation/changeReview/organizerId/registeredCount/createdAt, prevent maxParticipants < registeredCount |
| 8 | Gallery completion consistency | pending | Use Event.isCompleted definition (status == completed OR endTime <= now) |
| 9 | Admin gallery moderation flow | pending | Admin can view gallery + delete individual images |
| 10 | Critical-change notification duplication fix | pending | Deterministic notification IDs instead of in-memory Set |
| 11 | Notification failure handling | pending | Primary op success independent of notification failure |
| 12 | About screen unauthenticated access | pending | About text visible without auth, contact form stays protected |

---

## Post-Fix Tasks

| # | Task | Status | Notes |
|---|------|--------|-------|
| A | flutter analyze | pending | |
| B | flutter test | pending | |
| C | Inspect rules against repo transactions | pending | |
| D | Search for TODO/stubs/not implemented | pending | |
| E | Update FINAL_AUDIT_REPORT.md | pending | |
| F | Do not claim Storage/security fixed unless rules contain the fix | pending | Verification step |

---

## Chunked Work Plan

**Chunk 1:** storage.rules + firestore.rules top + events + registrations
**Chunk 2:** firestore.rules attendance + feedback + notifications + gallery
**Chunk 3:** firestore.rules users + misc helpers + final review of firestore.rules
**Chunk 4:** Admin gallery moderation UI + notification duplication fix + notification failure handling
**Chunk 5:** About screen unauthenticated + verify all + analyze + tests + audit
