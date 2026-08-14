# EventEase — AGENTS.md

## 1. Project Identity

EventEase is a cross-platform mobile event-management application built with Flutter and Firebase.

The application has three roles:

- Attendee
- Organizer
- Administrator

The application allows users to:

- Discover events
- Search and filter events
- View event details
- View event locations on a map
- Register for events
- Receive a QR event pass
- Check in through QR scanning
- Favorite events
- Receive notifications
- Submit feedback
- Browse event galleries

Organizers can:

- Create events
- Edit events
- Submit events for approval
- Manage participants
- Scan attendee QR codes
- Record attendance
- Send event announcements
- Manage event galleries
- View feedback

Administrators can:

- Approve/reject events
- Manage users
- Manage events
- Moderate content
- View reports and statistics
- Manage appropriate roles

The SRS and existing project plan are the source of truth for product requirements.

Do not invent additional product requirements.

---

# 2. PRIMARY RULE

Work only within the scope of the existing EventEase requirements and implementation plan.

Before implementing anything:

1. Inspect the existing code.
2. Read the relevant section of `PLAN.md`.
3. Understand the existing architecture.
4. Reuse existing components, models, services, repositories, and utilities.
5. Make the smallest clean change that completely solves the requested task.

Do NOT redesign the application because you personally prefer another approach.

Do NOT introduce new architecture unless the existing architecture genuinely cannot support the requirement.

Do NOT add speculative functionality.

Do NOT "improve" unrelated code while working on a task.

Do NOT create abstractions without a concrete current use case.

---

# 3. SOURCE OF TRUTH

Use these sources in this order:

1. The user's current instruction
2. `AGENTS.md`
3. `PLAN.md`
4. The project SRS/documentation
5. Existing implementation and established project conventions
6. General engineering knowledge

If two sources conflict, follow the higher-priority source.

Never silently change requirements.

If an implementation decision is genuinely ambiguous and materially affects architecture or product behavior, stop and ask for clarification rather than inventing a requirement.

For small implementation details, use the simplest reasonable solution consistent with the existing project.

---

# 4. TECHNOLOGY STACK

The project uses:

- Flutter
- Dart
- Material 3
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Provider
- QR Flutter
- Mobile Scanner
- Image Picker
- Cached Network Image
- UUID
- Intl
- URL Launcher

Do not replace these technologies with alternatives.

Do not introduce:

- Riverpod
- Bloc
- GetX
- Redux
- GoRouter
- Supabase
- REST backend
- Node.js backend
- Laravel backend
- another database
- another UI framework
- another UI component library

unless the user explicitly changes the architecture.

---

# 5. DEPENDENCY POLICY

The existing `pubspec.yaml` is the approved dependency baseline.

Use existing dependencies whenever possible.

Do NOT install a package simply because it makes a small task easier.

Before adding a dependency, verify that:

- Flutter/Dart cannot reasonably solve the problem natively.
- Existing project dependencies cannot solve it.
- The requirement actually needs the dependency.
- The dependency is compatible with the current Flutter/Dart SDK.

Do not upgrade, downgrade, remove, replace, or reorganize dependencies without a concrete reason.

Do not modify `pubspec.yaml` unless the task genuinely requires a dependency change.

If a new dependency is genuinely necessary, explain why before adding it.

---

# 6. UI / DESIGN SYSTEM

EventEase uses Flutter Material 3.

Material 3 is the design system.

Do NOT create a separate custom design system.

Use:

- Material 3 components
- Material 3 typography
- Material 3 buttons
- Material 3 cards
- Material 3 text fields
- Material 3 dialogs
- Material 3 bottom sheets
- Material 3 navigation
- Material icons
- Material 3 states

Use the centralized application theme.

Never hard-code random colors, text styles, button styles, or component styles inside individual screens when an existing theme/component already provides them.

Do not introduce:

- Custom UI frameworks
- Third-party UI kits
- Google Fonts
- Glassmorphism
- Excessive gradients
- Excessive shadows
- Random animations
- Random decorative effects

The UI should be:

- Clean
- Professional
- Accessible
- Consistent
- Mobile-first
- Production-oriented

---

# 7. SHARED UI COMPONENTS

Reuse existing shared components.

Examples include:

- EventCard
- StatusBadge
- AppButton
- AppTextField
- LoadingState
- EmptyState
- ErrorState
- NotificationItem
- StatCard
- EventImage
- QR pass components
- Map/location components

Before creating a new component, search the project for an existing equivalent.

Do not create duplicate components with slightly different names or styling.

If a component genuinely needs to be shared, place it in the established shared/core component location.

---

# 8. ARCHITECTURE

Follow the existing layered architecture.

Conceptually:

UI
↓
Presentation / State
↓
Repository
↓
Service
↓
Firebase / Platform API

Screens/widgets must not contain direct Firestore/Firebase data-access logic when a repository/service abstraction already exists.

Do not put business logic inside UI widgets unnecessarily.

Keep:

- UI rendering in widgets/screens
- state management in providers/presentation layer
- data access in repositories
- Firebase API operations in services
- reusable utilities in appropriate utility locations

Do not introduce unnecessary architectural layers.

The goal is separation of concerns, not abstraction for its own sake.

---

# 9. STATE MANAGEMENT

Use Provider as the project's state-management solution.

Do not introduce another state-management framework.

Providers should own relevant screen/application state and coordinate with repositories/services.

Avoid putting large amounts of business logic directly inside widgets.

Avoid creating a provider for trivial local UI state that can be handled with normal Flutter state.

Use the simplest appropriate state-management approach.

---

# 10. FIREBASE

Firebase is the backend.

Use:

- Firebase Authentication for authentication
- Cloud Firestore for application data
- Firebase Storage for images/media
- Firebase Cloud Messaging if/when push notifications are implemented

Do not create a second backend.

Do not duplicate Firebase access logic throughout the application.

Use repositories/services.

Never expose credentials or secrets in source code.

Never store passwords manually.

Firebase Authentication owns authentication credentials.

---

# 11. FIRESTORE

Use the existing Firestore data model and naming conventions.

Core logical entities include:

- Users
- Events
- Registrations
- Attendance
- Favorites
- Notifications
- Feedback
- Gallery
- Contact Messages

Do not create duplicate collections for the same concept.

Do not rename established fields without checking all usages.

Do not change the database schema casually.

If a schema change is necessary:

1. Identify all affected code.
2. Update the model/repository/service consistently.
3. Check existing reads and writes.
4. Check security implications.
5. Document the change if it affects the project plan.

---

# 12. SECURITY

Security is a requirement, not an optional enhancement.

Never trust client-side role checks alone.

The UI may hide functionality based on role, but backend/database security must enforce authorization.

Attendees must not access organizer/admin operations.

Organizers must only manage resources they are authorized to manage.

Administrators may perform system-wide administrative operations.

Never expose:

- Passwords
- Authentication secrets
- Private credentials
- Sensitive configuration

Do not weaken Firebase security rules to make development easier.

Do not bypass authorization to make a feature work.

---

# 13. ROLE SYSTEM

There are exactly three application roles:

- Attendee
- Organizer
- Administrator

Do not invent additional roles unless explicitly requested.

A user must not be able to arbitrarily promote themselves through the client UI.

Role-based navigation and authorization must remain consistent.

---

# 14. EVENT LIFECYCLE

Events follow the established workflow.

Conceptually:

Organizer creates event
↓
Pending approval
↓
Administrator reviews
↓
Approved
↓
Attendees can discover/register
↓
Event occurs
↓
Attendance recorded
↓
Feedback/gallery available

Do not bypass approval rules.

Do not make pending events publicly available unless the requirements explicitly allow it.

---

# 15. REGISTRATION

Registration must respect:

- Authentication
- Event availability
- Maximum participant capacity
- Duplicate registration prevention
- Event status

Do not allow users to register multiple times for the same event.

Do not decrement/increment capacity in an unsafe client-only manner.

Consider concurrency when implementing registration.

---

# 16. QR CODE

QR codes represent event registration/passes.

Attendee:

Register
→ Registration created
→ QR pass available

Organizer:

Scan QR
→ Validate registration
→ Check event
→ Prevent duplicate check-in
→ Record attendance

Do not treat the QR code as authentication.

Do not trust arbitrary QR content from the client.

The scanner must validate the registration against backend data.

Duplicate check-ins must be prevented.

---

# 17. GOOGLE MAPS / LOCATION

The application includes event-location functionality.

For organizers:

Create/Edit Event
→ Select/search location
→ Select map position
→ Save location information

Store appropriate event location information such as:

- Location name
- Latitude
- Longitude

For attendees:

Event Details
→ View location/map
→ Open location in Google Maps when appropriate

Do not introduce Google Places API, Google Geocoding API, or additional mapping infrastructure unless explicitly required.

Do not add a separate Maps product area.

Maps are part of the event-location experience.

---

# 18. IMAGES

Use:

- Image Picker for selecting images
- Firebase Storage for uploaded images
- Cached Network Image for remote images where appropriate

Images should have appropriate loading, error, and placeholder states.

Do not upload unnecessarily large files.

Do not create duplicate image-upload implementations.

---

# 19. ERROR / LOADING / EMPTY STATES

Every data-driven screen should account for:

- Loading
- Success
- Empty
- Error

Use clear user-facing messages.

Do not leave users staring at a blank screen.

Do not expose raw Firebase exceptions or stack traces to users.

Developer logs may contain useful diagnostic information, but user-facing errors should be understandable.

---

# 20. FORMS

Forms must have:

- Clear labels
- Validation
- Appropriate input types
- Loading states
- Error states
- Disabled states where appropriate
- Success feedback

Do not duplicate validation rules across multiple layers unnecessarily.

Important business validation should not exist only in the UI.

---

# 21. NAVIGATION

Use the existing navigation approach defined by the project.

Do not introduce a new routing framework.

Navigation must respect authentication and user roles.

Unauthenticated users should not access protected application areas.

Users should be directed to the appropriate experience based on their role.

Do not create multiple competing navigation systems.

---

# 22. ATTENDEE NAVIGATION

The primary attendee navigation is:

- Home
- Discover
- My Events
- Favorites
- Profile

Notifications should be accessible without occupying a primary navigation slot.

Do not add unrelated navigation destinations.

---

# 23. ORGANIZER NAVIGATION

Organizer navigation should focus on:

- Dashboard
- Events
- Participants
- Attendance
- Profile

Use the existing project structure rather than inventing additional organizer sections.

---

# 24. ADMIN NAVIGATION

Admin navigation should focus on:

- Dashboard
- Approvals
- Users
- Events
- Reports

Do not overload the admin navigation with attendee functionality.

---

# 25. CODE STYLE

Write production-quality Dart.

Prefer:

- Clear names
- Small focused methods
- Small focused widgets
- Immutable data where practical
- Null safety
- Explicit types where they improve readability
- Early returns where appropriate
- Reusable components where justified

Avoid:

- Giant widgets
- Giant methods
- Duplicate logic
- Magic numbers
- Magic strings
- Dead code
- Commented-out code
- Unnecessary abstractions
- Clever code that is difficult to maintain

Do not optimize prematurely.

Readable code is more important than clever code.

---

# 26. FILE ORGANIZATION

Follow the existing project structure.

Do not reorganize the entire project for stylistic reasons.

Before creating a file:

1. Search for an existing related file.
2. Check the established naming convention.
3. Put the file in the appropriate feature/layer.

Feature code should remain grouped logically.

Do not scatter one feature across unrelated folders.

---

# 27. EXISTING CODE

Treat existing code as intentional unless there is evidence it is broken.

Before changing existing code:

- Understand why it exists.
- Search for usages.
- Check dependencies.
- Check whether other features rely on it.

Do not rewrite working code merely because another implementation is personally preferred.

Do not refactor unrelated code during feature work.

If existing code is genuinely incorrect, make the smallest safe correction.

---

# 28. GIT SAFETY

Do not:

- Delete unrelated files
- Rewrite unrelated modules
- Reset user changes
- Force-reset branches
- Remove working features
- Modify unrelated configuration

Preserve existing work.

If you discover unrelated uncommitted changes, do not overwrite them.

Keep changes focused on the requested task.

---

# 29. SCOPE CONTROL

Do not implement features that were not requested or specified.

Examples of out-of-scope additions include:

- Payments
- E-commerce
- Live streaming
- Chat systems
- Social feeds
- Complex recommendation engines
- AI features
- Advanced analytics
- Unrequested maps APIs
- Unrequested third-party services
- Unrequested animations
- Unrequested localization
- Unrequested offline architecture

If an idea could be useful but is not part of the current scope, do not implement it.

Mention it only if it directly blocks the current task.

---

# 30. PRODUCTION ENGINEERING PRINCIPLES

Build the project as if it will be maintained by another developer after the current team leaves.

Prioritize:

- Maintainability
- Testability
- Security
- Predictability
- Consistency
- Clear boundaries
- Error handling
- Accessibility
- Performance where relevant

But do not over-engineer a student project.

"Production quality" means clean, maintainable, secure, understandable software.

It does NOT mean adding enterprise-level complexity everywhere.

---

# 31. PERFORMANCE

Avoid obvious performance problems.

Examples:

- Do not repeatedly query Firestore unnecessarily.
- Do not rebuild expensive widgets unnecessarily.
- Use pagination where the existing requirements/data volume justify it.
- Cache network images appropriately.
- Dispose controllers/listeners correctly.
- Avoid loading large datasets when only a subset is needed.

Do not prematurely introduce complex caching or offline synchronization.

---

# 32. ACCESSIBILITY

Use Material 3 accessibility conventions.

Important interactive elements should have meaningful labels.

Maintain readable contrast.

Do not rely solely on color to communicate status.

Buttons and touch targets should be appropriately sized.

Do not sacrifice usability for visual appearance.

---

# 33. TESTING

When implementing important business logic, consider tests for:

- Authentication behavior
- Registration rules
- Capacity handling
- Duplicate registration prevention
- QR validation
- Duplicate check-in prevention
- Role authorization
- Repository behavior
- Important validation rules

Do not write meaningless tests just to increase coverage.

Test behavior that could break the product.

---

# 34. VALIDATION AFTER CHANGES

After meaningful implementation changes, run appropriate checks.

At minimum when practical:

```bash
flutter analyze
