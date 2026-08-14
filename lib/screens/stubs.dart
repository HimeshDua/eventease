import 'package:flutter/material.dart';

import '../widgets/common.dart';

/// Temporary destinations keep role navigation usable until their respective
/// feature modules provide the real screens.
class FoundationPlaceholder extends StatelessWidget {
  final String title;
  const FoundationPlaceholder(this.title, {super.key});

  @override
  Widget build(BuildContext context) => EmptyView('$title is coming soon.');
}

/// ── TEAMMATE TASK SCREENS ──────────────────────────────────────────────
/// Each stub below is one assignable task. Replace the body with a real
/// implementation. Data access ONLY through the repositories in
/// lib/repositories/ — never call Firestore directly from a screen.
/// See TEAM_TASKS.md at the project root for who builds what and how.

class DiscoverStub extends StatelessWidget {
  const DiscoverStub({super.key});
  @override
  Widget build(BuildContext context) => const FoundationPlaceholder('Discover');
}

class MyEventsStub extends StatelessWidget {
  const MyEventsStub({super.key});
  @override
  Widget build(BuildContext context) => const FoundationPlaceholder('My Events');
}

class FavoritesStub extends StatelessWidget {
  const FavoritesStub({super.key});
  @override
  Widget build(BuildContext context) => const FoundationPlaceholder('Favorites');
}

class NotificationsStub extends StatelessWidget {
  const NotificationsStub({super.key});
  @override
  Widget build(BuildContext context) => const FoundationPlaceholder('Alerts');
}

class OrganizerStub extends StatelessWidget {
  const OrganizerStub({super.key});
  @override
  Widget build(BuildContext context) => const FoundationPlaceholder('Organizer Home');
}

class AdminStub extends StatelessWidget {
  const AdminStub({super.key});
  @override
  Widget build(BuildContext context) => const FoundationPlaceholder('Admin Home');
}

class ProfileStub extends StatelessWidget {
  const ProfileStub({super.key});
  @override
  Widget build(BuildContext context) => const FoundationPlaceholder('Profile');
}
