import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/event.dart';
import '../../models/event_feedback.dart';
import '../../models/registration.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/misc_repositories.dart';
import '../../repositories/registration_repository.dart';
import '../../widgets/common.dart';

/// Admin reports and statistics (SRS 1.6.17). Formulas:
/// total events, total registrations, total attendees (unique), total users,
/// top 3 events by registrations, event-wise attendance, average rating.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _retryToken = 0;

  @override
  Widget build(BuildContext context) {
    final events = context.read<EventRepository>();
    final registrations = context.read<RegistrationRepository>();
    final users = context.read<UserRepository>();
    final feedback = context.read<FeedbackRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Statistics')),
      body: StreamBuilder<List<Event>>(
        key: ValueKey('events-$_retryToken'),
        stream: events.all(),
        builder: (context, eventSnapshot) {
          return StreamBuilder<List<Registration>>(
            stream: registrations.allRegistrations(),
            builder: (context, regSnapshot) {
              return StreamBuilder<List<AppUser>>(
                stream: users.all(),
                builder: (context, userSnapshot) {
                  return StreamBuilder<List<EventFeedback>>(
                    stream: feedback.all(),
                    builder: (context, feedbackSnapshot) {
                      final hasError =
                          eventSnapshot.hasError ||
                          regSnapshot.hasError ||
                          userSnapshot.hasError ||
                          feedbackSnapshot.hasError;
                      if (hasError) {
                        final error = eventSnapshot.error ??
                            regSnapshot.error ??
                            userSnapshot.error ??
                            feedbackSnapshot.error;
                        return ErrorView(
                          'Could not load statistics: ${friendlyError(error!)}',
                          actionLabel: 'Retry',
                          onAction: () => setState(() => _retryToken++),
                        );
                      }
                      final isLoading =
                          eventSnapshot.connectionState ==
                              ConnectionState.waiting ||
                          regSnapshot.connectionState ==
                              ConnectionState.waiting ||
                          userSnapshot.connectionState ==
                              ConnectionState.waiting ||
                          feedbackSnapshot.connectionState ==
                              ConnectionState.waiting;
                      if (isLoading) {
                        return const LoadingView();
                      }

                      final allEvents = eventSnapshot.data ?? const <Event>[];
                      final allRegistrations =
                          regSnapshot.data ?? const <Registration>[];
                      final allUsers = userSnapshot.data ?? const <AppUser>[];
                      final allFeedback =
                          feedbackSnapshot.data ?? const <EventFeedback>[];

                      final totalRegistrations = allRegistrations.length;
                      final totalAttendees = allRegistrations
                          .where((r) => r.status == 'attended')
                          .length;
                      final totalEvents = allEvents.length;
                      final totalUsers = allUsers.length;

                      final topEvents = [...allEvents]
                        ..sort(
                          (a, b) =>
                              b.registeredCount.compareTo(a.registeredCount),
                        );

                      final attendanceByEvent = <String, int>{};
                      for (final reg in allRegistrations) {
                        if (reg.status == 'attended') {
                          attendanceByEvent[reg.eventId] =
                              (attendanceByEvent[reg.eventId] ?? 0) + 1;
                        }
                      }

                      final averageRating = allFeedback.isEmpty
                          ? 0.0
                          : allFeedback
                                    .map((f) => f.rating)
                                    .fold<int>(0, (a, b) => a + b) /
                                allFeedback.length;

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _StatRow(
                            label: 'Total events',
                            value: totalEvents.toString(),
                          ),
                          _StatRow(
                            label: 'Total registrations',
                            value: totalRegistrations.toString(),
                          ),
                          _StatRow(
                            label: 'Total attendees (checked in)',
                            value: totalAttendees.toString(),
                          ),
                          _StatRow(
                            label: 'Total users',
                            value: totalUsers.toString(),
                          ),
                          _StatRow(
                            label: 'Average rating',
                            value: allFeedback.isEmpty
                                ? 'No ratings yet'
                                : averageRating.toStringAsFixed(1),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Most popular events',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (topEvents.isEmpty)
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No events yet.'),
                              ),
                            )
                          else
                            for (final event in topEvents.take(3))
                              Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  title: Text(event.title),
                                  subtitle: Text(
                                    '${event.registeredCount} registrations',
                                  ),
                                  trailing: StatusBadge(status: event.status),
                                ),
                              ),
                          const SizedBox(height: 24),
                          Text(
                            'Event-wise attendance',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (attendanceByEvent.isEmpty)
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No attendance recorded yet.'),
                              ),
                            )
                          else
                            for (final entry
                                in attendanceByEvent.entries.toList()
                                  ..sort((a, b) => b.value.compareTo(a.value)))
                              Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: const Icon(Icons.event_seat),
                                  title: Text(
                                    _eventTitle(allEvents, entry.key),
                                  ),
                                  trailing: Text('${entry.value} attended'),
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
        },
      ),
    );
  }

  String _eventTitle(List<Event> events, String eventId) {
    for (final event in events) {
      if (event.id == eventId) return event.title;
    }
    return eventId;
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
