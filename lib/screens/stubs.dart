import 'package:flutter/material.dart';

import '../widgets/common.dart';

/// ── TEAMMATE TASK SCREENS ──────────────────────────────────────────────
/// Each stub below is one assignable task. Replace the body with a real
/// implementation. Data access ONLY through the repositories in
/// lib/repositories/ — never call Firestore directly from a screen.
/// See TEAM_TASKS.md at the project root for who builds what and how.

class DiscoverStub extends StatelessWidget {
  const DiscoverStub({super.key});
  @override
  Widget build(BuildContext context) => const EmptyView(
      'Discover: event list + search/filter\n(EventRepository.approvedUpcoming + EventRepository.filter)');
}

class MyEventsStub extends StatelessWidget {
  const MyEventsStub({super.key});
  @override
  Widget build(BuildContext context) => const EmptyView(
      'My Events: upcoming / completed / cancelled tabs + QR pass\n(RegistrationRepository.byUser)');
}

class FavoritesStub extends StatelessWidget {
  const FavoritesStub({super.key});
  @override
  Widget build(BuildContext context) => const EmptyView(
      'Favorites: saved events\n(FavoriteRepository.eventIds + EventRepository)');
}

class NotificationsStub extends StatelessWidget {
  const NotificationsStub({super.key});
  @override
  Widget build(BuildContext context) => const EmptyView(
      'Notifications list\n(NotificationRepository.byUser, markRead on tap)');
}

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

class ProfileStub extends StatelessWidget {
  const ProfileStub({super.key});
  @override
  Widget build(BuildContext context) => const EmptyView(
      'Profile: view/edit profile, change password\n(AuthService, UserRepository)');
}
