# EventEase Team Execution Board

This file assigns people, sequencing, handoffs, and evidence. `PLAN.md` remains the implementation authority. A module is complete only when its checklist and acceptance condition in `PLAN.md` are satisfied.

## Delivery model

- Himesh is the technical owner and primary implementer for Days 1 and 2.
- Day 1 is foundation work owned only by Himesh. Nobody else edits application source until the M10 checkpoint is committed.
- Day 2 remains Himesh-led. Each teammate receives one isolated screen track only after its dependencies are committed.
- Himesh is unavailable on Days 3 and 4. Teammates own audit, focused tests, acceptance evidence, documentation, APK, and video.
- No one changes a shared model, repository interface, Firebase rule, theme token, route contract, or package after the Day 1 freeze without recording the reason in the handoff log and getting Himesh's approval while he is available.
- Do not run typechecking, builds, browser validation, browser automation, or a development server unless the current user message explicitly authorizes it. Focused tests may be run when required by `PLAN.md`. APK creation requires explicit current-message build permission.

## People and permanent ownership

| Person | Permanent ownership | Must not change alone |
|---|---|---|
| Himesh | Architecture, Firebase configuration, Material 3 theme, models, repositories, rules, auth, attendee critical path, cross-role integration | None while available; he resolves shared-contract decisions |
| Teammate A | Event discovery screen on Day 2; attendee/shared UI audit and acceptance evidence after handoff | Models, repositories, Firebase rules, navigation contracts |
| Teammate B | Organizer event dashboard/form on Day 2; organizer audit and test evidence after handoff | Event schema, Storage paths, map service, registration transaction |
| Teammate C | Admin approval dashboard on Day 2; admin audit, demo data, documents, release package, and video after handoff | User-role service, event status rules, reporting formulas |

## Shared implementation contracts

Every contributor must follow these rules before opening an assigned file:

1. Read `PLAN.md` sections `GLOBAL_CONTRACT`, `DATA_SCHEMA`, `INTERFACE_REGISTRY`, and the assigned module.
2. Screens call Provider-managed repositories and services. Screens never import Firebase packages.
3. Use native Material 3 components and the shared Material Theme Builder light/dark schemes. Use `Theme.of(context)` tokens rather than screen-specific colors, typography, shapes, or shadows.
4. Embedded maps use the shared OpenStreetMap implementation with visible attribution. Google Maps is only the external Directions URL.
5. Preserve deterministic IDs, transaction invariants, ownership checks, and status transitions defined in `PLAN.md`.
6. Handle loading, empty, populated, and readable error states. Confirm destructive actions. Guard asynchronous UI work with mounted checks.
7. Do not add packages, duplicate repositories, alternate navigation systems, direct Firestore calls, or optional polish libraries.
8. Commit only the files owned by the task. Do not push or create a pull request unless explicitly requested.

## Branch and handoff protocol

- Himesh works on `main` during Day 1 and creates the checkpoint commit after M10.
- After that checkpoint, each teammate branches from the exact checkpoint commit: `task/attendee-discovery`, `task/organizer-event-form`, or `task/admin-approvals`.
- Teammates send Himesh the commit hash and the evidence block below. Himesh inspects and merges locally on Day 2.
- During Days 3 and 4, Teammate A acts as integration coordinator. Shared-file conflicts are resolved by the coordinator after consulting the file owner, not by overwriting one version.
- Never combine unfinished work from two people in one commit.

Use this handoff format:

```text
Owner:
PLAN modules:
Commit:
Files changed:
Acceptance evidence:
Focused checks actually run:
Known issue or blocker:
Next consumer:
```

## Day 1: Himesh foundation freeze

No teammate application-source work starts on Day 1. Teammates may clone the repository, read the SRS and `PLAN.md`, and prepare local Firebase access, but they do not edit `lib/`, Firebase rules, packages, or tests.

### Himesh task H1: establish the executable foundation

**PLAN modules:** M00-M04
**Produces:** known baseline, locked dependencies, strict Material 3 theme, resilient bootstrap, shared UI states, final domain models.

- [ ] Record the clean/dirty baseline and preserve unrelated work under M00.
- [ ] Complete M01 dependency and Material Theme Builder setup without adding optional UI packages.
- [ ] Complete or precisely record the external Firebase blocker in M02.
- [ ] Complete M03 bootstrap and shared loading/empty/error/confirmation/snackbar components.
- [ ] Complete M04 models, enums, serialization, timestamps, defaults, and required fields.
- [ ] Inspect model constructor consumers and correct every mismatch before repository work.

**Exit evidence:** M00-M04 acceptance statements can each be answered with a file path, source trace, or precise external blocker.

### Himesh task H2: freeze data and security boundaries

**PLAN modules:** M05-M08
**Consumes:** H1
**Produces:** final auth/profile service, event and registration invariants, engagement/storage/map services, Firestore and Storage rules.

- [ ] Complete authentication, profile creation, organizer request, role changes, deactivation, and friendly errors in M05.
- [ ] Complete event ownership/status behavior and all registration/cancellation/check-in transactions in M06.
- [ ] Complete favorites, feedback, notifications, gallery, contact, Storage, Provider wiring, and Google Directions service in M07.
- [ ] Complete least-privilege Firestore and Storage rules in M08. Map every repository operation to an explicit rule.
- [ ] Confirm screens require no direct Firebase imports and all later contributors can use the frozen interfaces without extending them.

**Exit evidence:** interface signatures match `PLAN.md`; transaction invariants and rule coverage are traceable; external deployment probes are marked honestly if unavailable.

### Himesh task H3: freeze the application shell

**PLAN modules:** M09-M10
**Consumes:** H1, H2
**Produces:** complete auth screens, role-aware adaptive shell, real route destinations, reusable session/error behavior.

- [ ] Complete all authentication states and validations in M09.
- [ ] Complete attendee, organizer, and admin destinations using Material 3 `NavigationBar`/`NavigationRail` in M10.
- [ ] Remove reliance on placeholder navigation contracts even if destination screen bodies are completed on Day 2.
- [ ] Commit the Day 1 checkpoint and send its exact hash to all teammates.

**Day 1 freeze gate:** M00-M10 are committed; schemas, interfaces, rules, theme, packages, and route names are frozen; no unresolved compile-level contract is knowingly handed to teammates.

## Day 2: Himesh-led feature completion

Himesh owns the integrated product. Teammates implement only the three bounded modules listed below. If a dependency is not committed, they review the SRS acceptance rows for their track rather than inventing an interface.

### Himesh task H4: attendee critical path

**PLAN modules:** M11, M13-M16
**Consumes:** M05-M07 plus Teammate A's M12
**Produces:** attendee dashboard, details/map/directions/registration, My Events/QR, favorites, notifications, feedback, profile, preferences, Contact/About.

- [ ] Complete M11 home dashboard with upcoming registrations, recommendations, trending events, and recently added events.
- [ ] Merge and inspect M12 before wiring discovery navigation into details.
- [ ] Complete M13 registration eligibility, embedded OSM map, attribution, and external Google Directions action.
- [ ] Complete M14 upcoming/past/cancelled classifications, deterministic QR pass, cancellation, and reminders.
- [ ] Complete M15 favorites, notification history/details, unread state, and one-feedback-per-attendee behavior.
- [ ] Complete M16 profile/avatar/password/preferences/organizer request and Contact/About.

**Exit evidence:** the attendee flow is traceable from login to discovery, details, registration, QR, cancellation, feedback, and notifications, including failure paths.

### Teammate A task A1: discovery and filters

**PLAN module:** M12
**Start gate:** H3 checkpoint and M06 interfaces are available
**Owned files:** discovery/filter screens and their screen-local widgets only
**Next consumer:** Himesh H4

- [ ] Build approved upcoming event browse/search with debounce.
- [ ] Implement category, date, location, and available-seat filters using `EventRepository.filter` exactly as defined.
- [ ] Add Clear Filters, result count, loading, empty, and error states.
- [ ] Wire event selection to the existing details route without changing the route contract.
- [ ] Check compact and wide layouts by source inspection using shared Material 3 tokens.
- [ ] Commit only M12 files and send the handoff block to Himesh.

**Acceptance evidence:** every SRS discovery/filter control maps to a repository filter argument; no Firebase package import exists in owned screens.

### Teammate B task B1: organizer dashboard and event form

**PLAN module:** M17
**Start gate:** H3 checkpoint plus M06/M07 interfaces
**Owned files:** organizer dashboard, event form, location picker
**Next consumer:** Himesh H5

- [ ] Build the organizer-owned event list with statuses and participant counts.
- [ ] Build the complete structured create/edit form with all SRS fields and cover image.
- [ ] Use the shared OSM picker for manual coordinates and required address. Keep attribution visible.
- [ ] Enforce date, capacity, coordinate, ownership, started-event, and critical-edit constraints through existing repositories.
- [ ] Show pending/rejected/cancelled/completed states and readable submission failures.
- [ ] Commit only M17 files and send the handoff block to Himesh.

**Acceptance evidence:** create/edit uses the frozen repository and Storage paths; no second map, geocoder, direct Firebase call, or custom theme is introduced.

### Teammate C task C1: admin dashboard and approvals

**PLAN module:** M20
**Start gate:** H3 checkpoint plus M05-M07 interfaces
**Owned files:** admin dashboard and approval queue screens
**Next consumer:** Himesh H6

- [ ] Build summary cards for pending approvals, approved events, users, and registrations.
- [ ] Build approval cards/details with approve and reject actions, confirmation, optional rejection reason, and readable failures.
- [ ] Surface critical-change reapproval separately from new-event approval.
- [ ] Preserve the rule that organizers cannot approve their own events.
- [ ] Commit only M20 files and send the handoff block to Himesh.

**Acceptance evidence:** every decision calls the frozen repository, changes the correct status, and has the notification behavior required by M20/M25.

### Himesh task H5: organizer completion

**PLAN modules:** M18-M19
**Consumes:** Teammate B M17
**Produces:** participant management, announcements, cancellation requests, organizer feedback view, scanner, and gallery.

- [ ] Inspect and merge M17 without changing frozen interfaces.
- [ ] Complete M18 participant list, announcement fan-out, cancellation request, and feedback summary.
- [ ] Complete M19 guarded QR scan states, duplicate-scan protection, gallery upload, and shared gallery browsing.
- [ ] Trace each organizer read/write back to owned-event rules.

**Exit evidence:** organizer flow covers create, approval state, participants, announcements, scan/check-in, cancellation request, feedback, and gallery.

### Himesh task H6: admin completion and reporting

**PLAN modules:** M21-M23
**Consumes:** Teammate C M20
**Produces:** event moderation, user/role management, reports and statistics.

- [ ] Inspect and merge M20 without weakening authorization.
- [ ] Complete M21 event filters, moderation, cancellation resolution, and guarded deletion.
- [ ] Complete M22 user search, activation, deactivation, organizer promotion, and role propagation.
- [ ] Complete M23 metric definitions, category/registration/attendance aggregates, and empty/loading/error states.

**Exit evidence:** admin operations are role-protected and reporting formulas reconcile with repository data rather than UI-local guesses.

### Himesh task H7: full integration and handoff

**PLAN modules:** M24-M25
**Consumes:** all Day 2 feature modules
**Produces:** one navigable application and one notification writer matrix.

- [ ] Replace every stub destination and remove `stubs.dart` references under M24.
- [ ] Verify role destinations, nested navigation, back behavior, badges, deep links, and logout behavior by source tracing.
- [ ] Complete every M25 notification trigger with one writer path and no duplicate notification documents.
- [ ] Resolve shared-file conflicts, inspect the complete diff, and record known issues by severity.
- [ ] Commit the Day 2 handoff state and provide Teammates A-C with the exact hash and demo-account prerequisites.

**Day 2 freeze gate:** M00-M25 are committed; every required feature exists in source; no feature stub remains; remaining work is audit, focused regression coverage, evidence, documentation, and release packaging.

## Day 3: teammate quality and evidence pass

No new product features, packages, schemas, or architectural layers are allowed. Fix only defects discovered while completing M26-M29.

### Teammate A task A2: integration coordination and attendee audit

**Primary PLAN modules:** M26, M29
**Contributors:** B and C provide their track evidence

- [ ] Create the M26 audit checklist and assign organizer rows to B and admin rows to C.
- [ ] Audit shared and attendee screens for Material 3 tokens, accessibility, mounted handling, loading/empty/error states, bounded streams, offline messages, and map attribution.
- [ ] Fix defects only in shared/attendee files; coordinate any shared-file change before editing.
- [ ] Assemble the M29 SRS acceptance matrix with PASS, FAIL, or BLOCKED and observed evidence for every row.
- [ ] Keep blocked Firebase/runtime/build items honest; do not mark an unrun flow PASS.

**Handoff:** send the final audit and acceptance matrix to C for inclusion in the deliverables.

### Teammate B task B2: organizer audit and focused tests

**Primary PLAN module:** M27 organizer/repository portion
**Contributes to:** M26, M29

- [ ] Audit M17-M19 against their SRS rows and Material 3/shared-map contracts.
- [ ] Add only focused regression tests required by M27 for event filtering, registration/cancellation/check-in invariants, map Directions URI, and security rules where supported.
- [ ] Run only the focused test files that are permitted and record exact results.
- [ ] Fix organizer defects found by those checks without broad refactoring.
- [ ] Send source paths, test results, and unresolved blockers to A.

### Teammate C task C2: admin audit, demo data, and document preparation

**Primary PLAN module:** M28
**Contributes to:** M26, M27, M29, M30

- [ ] Audit M20-M23 against approval, moderation, role, cancellation, and statistics requirements.
- [ ] Add focused admin behavior/rule coverage only where M27 requires meaningful confidence.
- [ ] Define deterministic M28 users, events, registrations, attendance, feedback, notifications, and gallery data for the complete demo sequence.
- [ ] Create/update the required documentation using actual architecture and evidence, never planned-but-unimplemented behavior.
- [ ] Prepare demo credentials without committing secrets.
- [ ] Send admin evidence and seed-count expectations to A; retain the documentation set for Day 4.

**Day 3 gate:** M26 audit has no unresolved critical source issue; focused checks have exact recorded results; M28 demo data supports the complete sequence; M29 contains an honest status for every SRS row.

## Day 4: fixes and submission

### Teammate A task A3: acceptance owner

- [ ] Triage M29 FAIL items by severity and assign only submission-blocking defects.
- [ ] Fix shared/attendee defects and update their evidence.
- [ ] Reconcile the final SRS acceptance matrix after B and C report their results.
- [ ] Stop feature work after the acceptance matrix is stable.

### Teammate B task B3: final functional fixes

- [ ] Fix submission-blocking organizer/admin defects assigned from M29.
- [ ] Re-run only the focused checks directly affected by each fix and report exact results.
- [ ] Confirm QR attendance, approval, cancellation, user management, and statistics evidence is ready for the demo sequence.
- [ ] Hand the final verified commit and evidence to A and C.

### Teammate C task C3: deliverables and release owner

**Primary PLAN module:** M30

- [ ] Finalize README, problem definition, design specification, use case, sitemap, ERD, database design, assumptions, backup/restore strategy, test evidence, and test-data instructions.
- [ ] Confirm source, documentation, demo credentials, and evidence contain no secrets.
- [ ] Request explicit current-message authorization before running any release build command.
- [ ] If authorized, produce and install the release APK and record the actual result. If not authorized, mark APK delivery BLOCKED rather than claiming success.
- [ ] Record the mandatory MP4 in SRS checklist order 8-19 using the deterministic demo accounts/data.
- [ ] Package source, documentation, test data, credentials instructions, APK, and MP4; create backup copies.
- [ ] Obtain A's final M29 matrix and confirm every M30 deliverable row has evidence.

**Terminal gate:** `PLAN.md` M00-M30 are accounted for; all focused checks actually run are recorded; the acceptance matrix is honest; all authorized deliverables exist; remaining external blockers are named precisely.

## Blocker policy

1. Check the module's `depends_on` line and the latest handoff hash.
2. If the dependency is missing, work only on source inspection, acceptance mapping, or documentation that does not require inventing the interface.
3. Record the blocker as `owner + module + missing dependency + exact next action`.
4. Never bypass a blocker through direct Firebase calls in screens, weakened rules, a duplicate repository, a second map implementation, hardcoded role/status data, or fake PASS evidence.
5. On Day 1 or 2, Himesh resolves shared-contract blockers. On Day 3 or 4, A coordinates and limits changes to the frozen architecture.

## Module ownership index

| Modules | Primary owner | Delivery point |
|---|---|---|
| M00-M10 | Himesh | Day 1 foundation freeze |
| M11, M13-M16 | Himesh | Day 2 attendee completion |
| M12 | Teammate A | Day 2 bounded contribution |
| M17 | Teammate B | Day 2 bounded contribution |
| M18-M19 | Himesh | Day 2 organizer completion |
| M20 | Teammate C | Day 2 bounded contribution |
| M21-M25 | Himesh | Day 2 admin/integration completion |
| M26 | Teammate A | Day 3 quality audit |
| M27 | Teammate B | Day 3 focused regression coverage |
| M28 | Teammate C | Day 3 deterministic demo data |
| M29 | Teammate A | Day 3-4 acceptance evidence |
| M30 | Teammate C | Day 4 release and submission |
