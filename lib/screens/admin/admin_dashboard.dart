import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/event.dart';
import '../../models/registration.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/misc_repositories.dart';
import '../../repositories/registration_repository.dart';
import '../../widgets/common.dart';
import 'approvals_screen.dart';
import 'events_screen.dart';
import 'stats_screen.dart';
import 'users_screen.dart';

/// Admin summary dashboard (SRS 1.6.16).
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final events = context.read<EventRepository>();
    final registrations = context.read<RegistrationRepository>();
    final users = context.read<UserRepository>();

    return StreamBuilder<List<Event>>(
      stream: events.all(),
      builder: (context, eventSnapshot) {
        return StreamBuilder<List<Registration>>(
          stream: registrations.allRegistrations(),
          builder: (context, regSnapshot) {
            return StreamBuilder<List<AppUser>>(
              stream: users.all(),
              builder: (context, userSnapshot) {
                final hasError =
                    eventSnapshot.hasError ||
                    regSnapshot.hasError ||
                    userSnapshot.hasError;
                if (hasError) {
                  return const ErrorView('Could not load admin statistics.');
                }
                final allEvents = eventSnapshot.data ?? const <Event>[];
                final allRegistrations =
                    regSnapshot.data ?? const <Registration>[];
                final allUsers = userSnapshot.data ?? const <AppUser>[];

                final pending = allEvents
                    .where((e) => e.status == 'pending')
                    .length;
                final cancellationRequests = allEvents
                    .where((e) => e.cancellationRequested)
                    .length;

                if (eventSnapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView();
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Administrator',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Events',
                            value: allEvents.length.toString(),
                            icon: Icons.event_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            label: 'Users',
                            value: allUsers.length.toString(),
                            icon: Icons.group_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Registrations',
                            value: allRegistrations.length.toString(),
                            icon: Icons.assignment_turned_in_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            label: 'Pending',
                            value: pending.toString(),
                            icon: Icons.pending_actions_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (cancellationRequests > 0)
                      Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: ListTile(
                          leading: const Icon(Icons.event_busy_outlined),
                          title: Text(
                            '$cancellationRequests cancellation request${cancellationRequests == 1 ? '' : 's'}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ApprovalsScreen(),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _ActionTile(
                      icon: Icons.fact_check_outlined,
                      title: 'Approvals',
                      subtitle: 'Approve or reject pending events',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ApprovalsScreen(),
                        ),
                      ),
                    ),
                    _ActionTile(
                      icon: Icons.event_outlined,
                      title: 'Events',
                      subtitle: 'Moderate all events',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EventsScreen()),
                      ),
                    ),
                    _ActionTile(
                      icon: Icons.group_outlined,
                      title: 'Users',
                      subtitle: 'Manage users and roles',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UsersScreen()),
                      ),
                    ),
                    _ActionTile(
                      icon: Icons.bar_chart_outlined,
                      title: 'Reports',
                      subtitle: 'View statistics and ratings',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StatsScreen()),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
