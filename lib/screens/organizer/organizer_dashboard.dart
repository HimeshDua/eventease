import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../repositories/event_repository.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';
import 'event_form_screen.dart';
import 'organizer_event_details_screen.dart';

/// Organizer's owned events with status and participant counts (SRS 1.6.11).
class OrganizerDashboard extends StatelessWidget {
  const OrganizerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      return const ErrorView('Please sign in to manage your events.');
    }
    final events = context.read<EventRepository>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'My events',
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
        Expanded(
          child: StreamBuilder<List<Event>>(
            stream: events.byOrganizer(user.id),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const ErrorView('Could not load your events.');
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView();
              }
              final items = snapshot.data ?? const <Event>[];
              if (items.isEmpty) {
                return const EmptyView(
                  'You have not created any events yet.',
                  icon: Icons.event_outlined,
                );
              }
              final sorted = [...items]
                ..sort((a, b) {
                  final aTime =
                      a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final bTime =
                      b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return bTime.compareTo(aTime);
                });
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final event = sorted[index];
                  return _OrganizerEventCard(
                    event: event,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OrganizerEventDetailsScreen(eventId: event.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
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
