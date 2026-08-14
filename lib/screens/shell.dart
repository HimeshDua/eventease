import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../models/app_user.dart';
import '../repositories/misc_repositories.dart';
import '../services/auth_service.dart';
import 'admin/admin_dashboard.dart';
import 'admin/events_screen.dart';
import 'admin/stats_screen.dart';
import 'admin/users_screen.dart';
import 'attendee/attendee_dashboard.dart';
import 'attendee/discover_screen.dart';
import 'attendee/my_events_screen.dart';
import 'organizer/organizer_dashboard.dart';
import 'shared/notifications_screen.dart';
import 'shared/profile_screen.dart';

/// Role-aware adaptive application navigation (SRS navigation requirements).
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
                    icon: destination.label == 'Alerts'
                        ? _AlertsIcon(
                            icon: destination.icon,
                            userId: widget.user.id,
                          )
                        : Icon(destination.icon),
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
          OrganizerDashboard(),
        ),
        _ShellDestination('Discover', Icons.explore_outlined, DiscoverScreen()),
        _ShellDestination('My Events', Icons.event_outlined, MyEventsScreen()),
        _ShellDestination(
          'Alerts',
          Icons.notifications_outlined,
          NotificationsScreen(),
        ),
        _ShellDestination('Profile', Icons.person_outline, ProfileScreen()),
      ];
    }
    if (role == Roles.admin) {
      return const [
        _ShellDestination(
          'Admin Home',
          Icons.dashboard_outlined,
          AdminDashboard(),
        ),
        _ShellDestination('Events', Icons.event_outlined, EventsScreen()),
        _ShellDestination('Users', Icons.group_outlined, UsersScreen()),
        _ShellDestination('Reports', Icons.bar_chart_outlined, StatsScreen()),
        _ShellDestination('Profile', Icons.person_outline, ProfileScreen()),
      ];
    }
    return const [
      _ShellDestination('Home', Icons.home_outlined, AttendeeDashboard()),
      _ShellDestination('Discover', Icons.explore_outlined, DiscoverScreen()),
      _ShellDestination('My Events', Icons.event_outlined, MyEventsScreen()),
      _ShellDestination(
        'Alerts',
        Icons.notifications_outlined,
        NotificationsScreen(),
      ),
      _ShellDestination('Profile', Icons.person_outline, ProfileScreen()),
    ];
  }
}

/// Unread notification badge for the Alerts destination.
class _AlertsIcon extends StatelessWidget {
  final IconData icon;
  final String userId;
  const _AlertsIcon({required this.icon, required this.userId});

  @override
  Widget build(BuildContext context) {
    final notifications = context.read<NotificationRepository>();
    return StreamBuilder<int>(
      stream: notifications.unreadCount(userId),
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;
        if (unread == 0) {
          return Icon(icon);
        }
        return Badge.count(count: unread, child: Icon(icon));
      },
    );
  }
}

class _ShellDestination {
  final String label;
  final IconData icon;
  final Widget screen;
  const _ShellDestination(this.label, this.icon, this.screen);
}
