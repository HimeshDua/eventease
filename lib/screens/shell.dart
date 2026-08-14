import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'stubs.dart';

/// Foundation for role-aware, adaptive application navigation.
class HomeShell extends StatefulWidget {
  final AppUser user;
  const HomeShell({super.key, required this.user});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.role != widget.user.role) _index = 0;
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _destinationsFor(widget.user.role);
    final selectedIndex = _index.clamp(0, destinations.length - 1);
    final selected = destinations[selectedIndex];
    final railMode = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(selected.label == 'Home' ? 'EventEase' : selected.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => context.read<AuthService>().logout(),
          ),
        ],
      ),
      body: railMode
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: _select,
                  destinations: [
                    for (final destination in destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: selected.screen),
              ],
            )
          : selected.screen,
      bottomNavigationBar: railMode
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: _select,
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    label: destination.label,
                  ),
              ],
            ),
    );
  }

  void _select(int value) => setState(() => _index = value);

  List<_ShellDestination> _destinationsFor(String role) {
    if (role == Roles.organizer) {
      return const [
        _ShellDestination(
          'Organizer Home',
          Icons.dashboard_outlined,
          OrganizerStub(),
        ),
        _ShellDestination('Discover', Icons.explore_outlined, DiscoverStub()),
        _ShellDestination('My Events', Icons.event_outlined, MyEventsStub()),
        _ShellDestination(
          'Alerts',
          Icons.notifications_outlined,
          NotificationsStub(),
        ),
        _ShellDestination('Profile', Icons.person_outline, ProfileStub()),
      ];
    }
    if (role == Roles.admin) {
      return const [
        _ShellDestination('Admin Home', Icons.dashboard_outlined, AdminStub()),
        _ShellDestination(
          'Events',
          Icons.event_outlined,
          FoundationPlaceholder('Events'),
        ),
        _ShellDestination(
          'Users',
          Icons.group_outlined,
          FoundationPlaceholder('Users'),
        ),
        _ShellDestination(
          'Reports',
          Icons.bar_chart_outlined,
          FoundationPlaceholder('Reports'),
        ),
        _ShellDestination('Profile', Icons.person_outline, ProfileStub()),
      ];
    }
    return const [
      _ShellDestination(
        'Home',
        Icons.home_outlined,
        FoundationPlaceholder('Home'),
      ),
      _ShellDestination('Discover', Icons.explore_outlined, DiscoverStub()),
      _ShellDestination('My Events', Icons.event_outlined, MyEventsStub()),
      _ShellDestination(
        'Alerts',
        Icons.notifications_outlined,
        NotificationsStub(),
      ),
      _ShellDestination('Profile', Icons.person_outline, ProfileStub()),
    ];
  }
}

class _ShellDestination {
  final String label;
  final IconData icon;
  final Widget screen;
  const _ShellDestination(this.label, this.icon, this.screen);
}
