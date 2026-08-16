import 'package:flutter/material.dart';

import '../widgets/common.dart';

/// ── REMAINING TASK SCREENS ─────────────────────────────────────────────
/// Attendee-facing screens are implemented (see lib/screens/attendee/ and
/// lib/screens/shared/). Organizer and Admin are the next task. Data access
/// ONLY through the repositories in lib/repositories/ -- never call Firestore
/// directly from a screen. See PLAN.md modules M17-M23 for the exact scope.

class OrganizerStub extends StatelessWidget {
  const OrganizerStub({super.key});
  @override
  Widget build(BuildContext context) => const EmptyView(
      'Organizer dashboard: my events, create/edit, participants, QR scanner\n(EventRepository.byOrganizer, RegistrationRepository.byEvent/checkInByQr)');
}

class AdminStub extends StatelessWidget {
  const AdminStub({super.key});
  @override
  Widget build(BuildContext context) => const EmptyView(
      'Admin: approvals, users, stats\n(EventRepository.all/setStatus, UserRepository)');
}
