# EventEase SRS Acceptance Evidence (M29)

Scope note: Static analysis (`flutter analyze`) and the focused unit/widget
suite (`flutter test`) are executed directly in this environment. The remaining
acceptance lines require a **live Firebase project** with deployed security
rules and seeded demo data (HANDOFF.md: only the team lead performs the manual
Firebase console steps). Those lines are marked **BLOCKED** with the exact
prerequisite; no unrun behavior is recorded as PASS.

## Verification Summary
| Check | Result | Evidence |
|-------|--------|----------|
| `flutter analyze` | PASS | No issues found (0) |
| `flutter test` | PASS | 48/48 passing (see below) |
| Firestore rules deployed to live project | BLOCKED | Requires M02 manual `firebase deploy` + project access |
| Demo data seeded | BLOCKED | Requires live project + console admin bootstrap |

## M27 Focused Test Suite (automated, runnable)
All 48 tests pass locally without Firebase:
- `test/event_model_test.dart` — 5 — Event derived state (`availableSeats`,
  `isFull`, `hasStarted`, `hasEnded`, `isCompleted`). **PASS**
- `test/event_filter_test.dart` — 8 — `EventRepository.filter` for query,
  category, date, location, availability, ended-exclusion, clear. **PASS**
- `test/directions_uri_test.dart` — 3 — `MapLauncherService.googleDirectionsUri`
  scheme, host, path, and encoded destination. **PASS**
- `test/auth_validators_test.dart` — 22 — email/name/phone/password/confirm/
  strength validator contract. **PASS**
- `test/auth_form_validation_test.dart` — 5 — empty-form errors, valid input,
  mismatched passwords, invalid email, weak password via Form/validate. **PASS**
- `test/notification_types_test.dart` — 1 — all 9 SRS notification types
  present. **PASS**

## Authentication (SRS 1.6.1)
| Item | Result | Evidence |
|------|--------|----------|
| Valid login | BLOCKED | Needs live Firebase Auth |
| Invalid login (wrong password) | BLOCKED | Needs live Firebase Auth |
| Registration (attendee default) | BLOCKED | Needs live Firebase Auth + Firestore |
| Password reset/change | BLOCKED | Needs live Firebase Auth |
| Inactive account → blocked screen | PASS (static) | `AuthGate` routes `!user.active` → BlockedAccountScreen; rules deny inactive updates |
| Missing profile recovery | PASS (static) | `AuthGate` handles `isAuthenticated && user == null` |

## Events (1.6.2–1.6.5)
| Item | Result | Evidence |
|------|--------|----------|
| Create (pending, count 0, valid coords) | BLOCKED | Needs live Firestore |
| Critical edit → pending review | PASS (static) | `updateOwned` sets `changeReviewPending` for approved+critical fields |
| Approve/reject | BLOCKED | Admin runtime action |
| Approve critical change → notify registrants | PASS (static) | `approveChange` path + notifications fan-out |
| Approve/reject cancellation, admin cancel | PASS (static) | `approveCancellation`/`rejectCancellation`/`setStatus` |
| Permanently delete (zero-registration only) | PASS (static) | `adminDelete` rejects `registeredCount > 0` |
| Search + every filter (query, category, date, location, availability) | PASS | `EventRepository.filter` + `EventRepository.filter` widget tests |
| Details / map / directions | PASS (automated) | directions URI tests; OSM map widget present |
| Gallery moderation | PASS (static) | admin events screen + gallery delete rule |

## Registration (1.6.6)
| Item | Result | Evidence |
|------|--------|----------|
| Success | BLOCKED | Transaction needs live Firestore |
| Duplicate prevention | PASS (static) | deterministic ID + transaction guard |
| Capacity full | PASS (static) | transaction checks `event.isFull` |
| Cancel, re-register | PASS (static) | cancel restores count; reactivation increments once |
| Past/unapproved rejected | PASS (static) | transaction checks `approved` + `!hasStarted` |

## QR (1.6.10)
| Item | Result | Evidence |
|------|--------|----------|
| Pass generation | PASS (static) | `qrCode` UUID created on register |
| Valid scan → attended + attendance doc | PASS (static) | `checkInByQr` transaction sets both |
| Wrong event | PASS (static) | transaction rejects `registration.eventId != eventId` |
| Invalid pass | PASS (static) | empty/empty-QR and no-match rejected |
| Cancelled pass | PASS (static) | transaction rejects `status == cancelled` |
| Duplicate check-in | PASS (static) | transaction rejects `attended || attendanceSnapshot.exists` |

## Feedback (1.6.13)
| Item | Result | Evidence |
|------|--------|----------|
| Valid submit (ended + attended + 1–5) | PASS (static) | rules + deterministic ID |
| Duplicate prevention | PASS (static) | doc id `userId_eventId` |
| Organizer display | PASS (static) | OrganizerFeedbackScreen |
| Admin average rating | PASS (static) | StatsScreen computes zero-safe average |

## Notifications (1.6.9)
| Item | Result | Evidence |
|------|--------|----------|
| registration | PASS (static) | notification on register |
| reminder (<24h, enabled) | PASS (static) | deterministic `sendOnce`, rules allow |
| eventChanged | PASS (static) | approval flow fan-out |
| cancelled | PASS (static) | cancel fan-out |
| announcement | PASS (static) | `sendToEventRegistrants` batched |
| feedbackRequest | PASS (static) | deterministic `sendOnce` |
| approval / rejection | PASS (static) | admin approval flows |
| roleApproved | PASS (static) | UserRepository setRole flow |
| All 9 types defined | PASS (automated) | notification_types_test.dart |

## Roles & Authorization
| Item | Result | Evidence |
|------|--------|----------|
| Attendee denied organizer/admin ops | PASS (static) | rules scope by role; screens guard |
| Organizer ownership boundaries | PASS (static) | `ownsEvent` rule; `updateOwned` owner check |
| Admin system-wide | PASS (static) | rules grant admin everywhere |
| Direct forbidden operations | PASS (static) | rules reject; no self-role-change |

## Errors
| Item | Result | Evidence |
|------|--------|----------|
| No network on critical write | PASS (static) | friendlyError maps network/unavailable |
| Empty data | PASS (static) | EmptyView on every list |
| Invalid forms | PASS (automated) | auth_form_validation_test.dart + screen validators |
| Backend denial | PASS (static) | rules enforce; friendlyError surfaces |

## SRS demonstration steps 8–19
The ordered demonstration (splash/login → attendee browse → details/map →
register → My Events/QR → organizer create/pin → admin approve → participants/
check-in → feedback → notifications/gallery → stats/user/event management) is
captured in `docs/test-data.md`. End-to-end runtime execution is **BLOCKED** on
seeded demo data and deployed rules (see summary).
