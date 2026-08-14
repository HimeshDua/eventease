# EventEase Team Task Sheet v3

Who does what, per day. Task ids (F01, A01, ...) are defined in PLAN.md; read your card there before starting. The global rules at the top of PLAN.md apply to every task.

## People
- Himesh: team lead, only experienced developer. Available Day 1 and Day 2 only. Owns architecture, Firebase, Material Theme Builder export, models, map contracts, security rules, all F tasks, integration gates, and the Day 2 handoff.
- Teammate A: attendee discovery, event details, favorites, My Events, QR, feedback, and notifications.
- Teammate B: organizer and admin screens, including venue picker, QR scanner, moderation, and statistics.
- Teammate C: profile, Contact/About, shared-screen polish, seed data, documents, APK, and video.

## One-time setup (each member, after Himesh finishes F01)
```
git clone <repo-url>
cd eventease
flutter pub get
flutter run
```
Get `firebase_options.dart` and `google-services.json` from Himesh. Do not commit `google-services.json` if the repo ever goes public. Work on your own branch, commit small with the task id in the message, merge locally with Himesh. Nobody pushes to any remote.

Do not run typechecking, builds, browser validation, or start a development server unless Himesh explicitly requests that action in the same message. APK creation remains a Day 4 deliverable and needs explicit build permission before its command is run.

## UI and map rules for everyone

1. Use only native Material 3 components and the shared Material Theme Builder light/dark themes.
2. Use `Theme.of(context)` tokens. Do not hardcode screen colors or add another component library.
3. The embedded venue map is OpenStreetMap through the shared map widget. Attribution must remain visible.
4. Google Maps is only the external Directions action. Do not add Google Maps SDK, API keys, geocoding, or a second map implementation.
5. Screens use repositories/services and never import Firebase packages directly.

## Day 1

| Who | Morning | Afternoon |
|---|---|---|
| Himesh | F01 Firebase, F02 strict Material 3 theme, F03 models | F04 auth, F05 registration, F06 repositories/map, F07 rules, F08 interface freeze |
| A | After F08, A01 Discover | Continue A01 details, OSM map, directions, register, favorite |
| B | After F08, O01 dashboard | Continue O01 event form and venue picker |
| C | Start I05 document skeleton from the SRS | Build the Profile and Contact/About portions of A03 after F08 |

End of Day 1, all together with Himesh: I01 integration gate. Demonstrate organizer venue selection, admin approval, attendee map/directions, registration, and QR. Nothing moves to Day 2 until I01 passes.

## Day 2

| Who | Morning | Afternoon |
|---|---|---|
| Himesh | Fix I01 findings and review shared boundaries | Pair on critical blockers, run I02, complete ownership handoff |
| A | A02 My Events, cancellation, QR | Finish attendee portions of A03 |
| B | O02 participants, announcements, scanner, feedback, gallery | D01 admin management and D02 statistics |
| C | Finish Profile/Contact portions of A03; begin I04 seed data | Continue I04 and I05; verify each delivered screen against its task check |

End of Day 2, all together: I02 feature freeze gate, the full SRS demo checklist steps 8 to 19. This is the handoff point. After I02, Himesh is gone; only bug fixes and polish are allowed.

### Day 2 handoff checklist (Himesh runs this before leaving)
1. I02 passed and committed.
2. Every teammate has the Firebase configuration and can open the project on their machine; runtime validation is recorded only if actually performed.
3. Firestore rules v2 deployed and verified.
4. Known-bugs list written into this file under a "Known issues" heading with a severity per item.
5. Scope-cut order (bottom of PLAN.md) read aloud so nobody invents new features.
6. Demo credentials draft exists in `DEMO_CREDENTIALS.md`.

## Day 3 (no Himesh, no new features)

All three follow I03 in PLAN.md, split as:
- A: Material 3, dark mode, and accessibility pass on attendee screens; empty/error copy audit.
- B: same pass on organizer/admin screens; scanner and map-gesture QA on the intended device when authorized.
- C: theme/shared-screen ownership, seed data final pass (I04), docs (I05), padding audit support.
Evening, all together: full checklist rerun on a real Android device, in light and dark. Write the fix list for Day 4 morning. Fix only what is on the list.

## Day 4 (delivery)

- Morning: fix the Day 3 list. Code freeze at noon. A and B fix, C finalizes I05 docs.
- Afternoon: after Himesh explicitly authorizes the build command, C runs I06 with A/B: produce and install the release APK, then record the mandatory MP4 following checklist steps 8 to 19 using `DEMO_CREDENTIALS.md` accounts.
- Package: docs folder, test data note, DEMO_CREDENTIALS.md, source, `app-release.apk`, video. Check every row of the SRS Required Deliverables table before calling it done.

## If someone is blocked
1. Re-read your task card's Needs line; if the dependency is not merged, take your next card instead.
2. Ask Himesh (Day 1 and 2) or the group chat (Day 3 and 4).
3. If an event/flow cannot be tested because data is missing, create it through the app UI as the organizer or admin demo account, never in the Firestore console except the first admin role flip.
4. Never bypass a blocker with a direct Firestore call from a screen, weakened security rule, duplicate repository, or second map implementation.
