import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/event.dart';
import '../../models/registration.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/registration_repository.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';
import 'event_form_screen.dart';
import 'organizer_event_details_screen.dart';

/// Organizer's owned events with status and participant counts (SRS 1.6.11).
class OrganizerDashboard extends StatelessWidget {
  final bool showHeader;
  final bool showStats;
  const OrganizerDashboard({
    super.key,
    this.showHeader = true,
    this.showStats = true,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      return const ErrorView('Please sign in to manage your events.');
    }
    final eventsRepository = context.read<EventRepository>();
    final registrationsRepository = context.read<RegistrationRepository>();

    return StreamBuilder<List<Event>>(
      stream: eventsRepository.byOrganizer(user.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const ErrorView('Could not load your events.');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }

        final items = snapshot.data ?? const <Event>[];
        final now = DateTime.now();
        final pending = items.where((e) => e.status == EventStatus.pending).length;
        final approved = items.where((e) => e.status == EventStatus.approved).length;
        final rejected = items.where((e) => e.status == EventStatus.rejected).length;
        final cancelled = items.where((e) => e.status == EventStatus.cancelled).length;
        final upcoming = items
            .where((e) => e.status == EventStatus.approved && e.startTime.isAfter(now) && !e.hasEnded)
            .length;
        final totalRegistrations = items.fold<int>(0, (sum, event) => sum + event.registeredCount);
        final sorted = [...items]
          ..sort((a, b) {
            final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });

        return StreamBuilder<List<Registration>>(
          stream: registrationsRepository.byEvents(items.map((e) => e.id)),
          builder: (context, registrationSnapshot) {
            if (registrationSnapshot.hasError) {
              return const ErrorView('Could not load organizer attendance data.');
            }
            final registrations = registrationSnapshot.data ?? const <Registration>[];
            final attendance = registrations
                .where((r) => r.status == RegistrationStatus.attended)
                .length;

            return Column(
              children: [
                if (showHeader)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Organizer dashboard',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EventFormScreen()),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('New event'),
                        ),
                      ],
                    ),
                  ),
                if (!showHeader)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: FilledButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EventFormScreen()),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('New event'),
                      ),
                    ),
                  ),
                if (showStats)
                  _StatsGrid(
                    totalEvents: items.length,
                    pending: pending,
                    approved: approved,
                    rejected: rejected,
                    cancelled: cancelled,
                    upcoming: upcoming,
                    registrations: totalRegistrations,
                    attendance: attendance,
                  ),
                Expanded(
                  child: sorted.isEmpty
                      ? const EmptyView(
                          'You have not created any events yet.',
                          icon: Icons.event_outlined,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: sorted.length,
                          itemBuilder: (context, index) {
                            final event = sorted[index];
                            return _OrganizerEventCard(
                              event: event,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OrganizerEventDetailsScreen(eventId: event.id),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int totalEvents;
  final int pending;
  final int approved;
  final int rejected;
  final int cancelled;
  final int upcoming;
  final int registrations;
  final int attendance;

  const _StatsGrid({
    required this.totalEvents,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.cancelled,
    required this.upcoming,
    required this.registrations,
    required this.attendance,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('Total events', totalEvents, Icons.event_outlined),
      ('Pending', pending, Icons.pending_actions_outlined),
      ('Approved', approved, Icons.verified_outlined),
      ('Rejected', rejected, Icons.cancel_outlined),
      ('Cancelled', cancelled, Icons.event_busy_outlined),
      ('Upcoming', upcoming, Icons.upcoming_outlined),
      ('Registrations', registrations, Icons.group_outlined),
      ('Attendance', attendance, Icons.how_to_reg_outlined),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        mainAxisExtent: 86,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(stat.$3),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(stat.$1, style: Theme.of(context).textTheme.bodySmall),
                      Text(stat.$2.toString(), style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrganizerEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  const _OrganizerEventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatEventDate(event.startTime),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [
                        StatusBadge(status: event.status),
                        Chip(
                          label: Text(
                            '${event.registeredCount}/${event.maxParticipants} registered',
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        if (event.cancellationRequested)
                          const Chip(
                            label: Text('Cancellation requested'),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
