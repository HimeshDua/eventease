import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'stubs.dart';

/// Role-based navigation shell (SRS 1.6.2). Each tab points at a screen —
/// teammates replace the Stub screens with real implementations.
class HomeShell extends StatefulWidget {
  final AppUser user;
  const HomeShell({super.key, required this.user});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final role = widget.user.role;

    final tabs = <({String label, IconData icon, Widget screen})>[
      (label: 'Discover', icon: Icons.explore, screen: const DiscoverStub()),
      (label: 'My Events', icon: Icons.event, screen: const MyEventsStub()),
      (label: 'Favorites', icon: Icons.favorite, screen: const FavoritesStub()),
      (
        label: 'Alerts',
        icon: Icons.notifications,
        screen: const NotificationsStub()
      ),
      if (role == Roles.organizer)
        (
          label: 'Organize',
          icon: Icons.edit_calendar,
          screen: const OrganizerStub()
        ),
      if (role == Roles.admin)
        (
          label: 'Admin',
          icon: Icons.admin_panel_settings,
          screen: const AdminStub()
        ),
      (label: 'Profile', icon: Icons.person, screen: const ProfileStub()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(tabs[_index].label == 'Discover'
            ? 'EventEase'
            : tabs[_index].label),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => context.read<AuthService>().logout(),
          ),
        ],
      ),
      body: tabs[_index].screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final t in tabs)
            NavigationDestination(icon: Icon(t.icon), label: t.label),
        ],
      ),
    );
  }
}
