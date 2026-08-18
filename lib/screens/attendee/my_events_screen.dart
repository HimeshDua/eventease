import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/app_user.dart';
import '../../models/event.dart';
import '../../models/registration.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/misc_repositories.dart';
import '../../repositories/registration_repository.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';
import 'event_details_screen.dart';
import 'feedback_screen.dart';
import 'qr_pass_screen.dart';

/// Attendee's registered events with QR passes (SRS 1.6.7, 1.6.10).
class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  final Set<String> _handledNotifications = {};

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      return const ErrorView('Please sign in to view your events.');
    }
    final registrations = context.read<RegistrationRepository>();
    final events = context.read<EventRepository>();

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
          Expanded(
            child: StreamBuilder<List<Registration>>(
              stream: registrations.byUser(user.id),
              builder: (context, regSnapshot) {
                if (regSnapshot.hasError) {
                  return const ErrorView('Could not load your events.');
                }
                if (regSnapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView();
                }
                final regs = regSnapshot.data ?? const <Registration>[];
                final eventIds = regs.map((registration) => registration.eventId).toList();
                return StreamBuilder<List<Event>>(
                  stream: events.byIds(eventIds),
                  builder: (context, eventSnapshot) {
                    if (eventSnapshot.hasError) {
                      return const ErrorView('Could not load event details.');
                    }
                    final eventMap = {
                      for (final event in eventSnapshot.data ?? const <Event>[]) event.id: event,
                    };
                    final joined = <_Joined>[];
                    for (final reg in regs) {
                      final event = eventMap[reg.eventId];
                      if (event != null) {
                        joined.add(_Joined(reg, event));
                      }
                    }
                    _maybeTriggerSideEffects(joined, user);
                    return TabBarView(
                      children: [
                        _JoinedList(
                          title: 'Upcoming events',
                          emptyMessage: 'You have no upcoming events.',
                          items: joined.where((j) => j.isUpcoming).toList(),
                          onOpen: (j) => _openDetails(context, j.event),
                          onQr: (j) => _openQr(context, j),
                          onCancel: (j) => _cancelRegistration(context, j),
                        ),
                        _JoinedList(
                          title: 'Completed events',
                          emptyMessage: 'No completed events yet.',
                          items: joined.where((j) => j.isCompleted).toList(),
                          onOpen: (j) => _openDetails(context, j.event),
                          onQr: (j) => _openQr(context, j),
                          onFeedback: (j) => _openFeedback(context, j),
                        ),
                        _JoinedList(
                          title: 'Cancelled registrations',
                          emptyMessage: 'No cancelled registrations.',
                          items: joined.where((j) => j.isCancelled).toList(),
                          onOpen: (j) => _openDetails(context, j.event),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// M25 deterministic reminders and feedback requests (one per event).
  void _maybeTriggerSideEffects(List<_Joined> joined, AppUser user) {
    final notifications = context.read<NotificationRepository>();
    final now = DateTime.now();

    for (final item in joined) {
      // Reminder within 24 hours for an upcoming event when enabled.
      if (item.reg.status == RegistrationStatus.registered &&
          user.remindersEnabled &&
          !item.event.hasStarted &&
          item.event.startTime.isAfter(now) &&
          item.event.startTime.difference(now).inHours <= 24) {
        final docId = 'reminder_${user.id}_${item.event.id}';
        if (_handledNotifications.add(docId)) {
          notifications.sendOnce(
            docId: docId,
            userId: user.id,
            eventId: item.event.id,
            type: NotificationTypes.reminder,
            title: 'Event reminder',
            message:
                '${item.event.title} starts ${formatEventDate(item.event.startTime)}.',
          );
        }
      }

      // Feedback request once for an attended completed event.
      if (item.reg.status == RegistrationStatus.attended &&
          item.event.isCompleted) {
        final docId = 'feedbackRequest_${user.id}_${item.event.id}';
        if (_handledNotifications.add(docId)) {
          notifications.sendOnce(
            docId: docId,
            userId: user.id,
            eventId: item.event.id,
            type: NotificationTypes.feedbackRequest,
            title: 'How was the event?',
            message: 'Share your feedback for ${item.event.title}.',
          );
        }
      }
    }
  }

  void _openDetails(BuildContext context, Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailsScreen(eventId: event.id)),
    );
  }

  void _openQr(BuildContext context, _Joined item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            QrPassScreen(eventId: item.event.id, registration: item.reg),
      ),
    );
  }

  void _openFeedback(BuildContext context, _Joined item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackScreen(eventId: item.event.id),
      ),
    );
  }

  Future<void> _cancelRegistration(BuildContext context, _Joined item) async {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final registrations = context.read<RegistrationRepository>();
    final confirmed = await confirm(
      context,
      'Cancel registration?',
      'Your seat will be released. This cannot be undone.',
    );
    if (!confirmed) return;
    try {
      await registrations.cancel(item.reg);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Registration cancelled.')),
      );
    // registration cancellation failed (network error, event already started)
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(friendlyError(error)),
          backgroundColor: colorScheme.errorContainer,
        ),
      );
    }
  }
}

class _Joined {
  final Registration reg;
  final Event event;
  const _Joined(this.reg, this.event);

  bool get isUpcoming =>
      reg.status == RegistrationStatus.registered && !event.hasEnded;

  bool get isCompleted =>
      (reg.status == RegistrationStatus.attended ||
          reg.status == RegistrationStatus.registered) &&
      event.isCompleted;

  bool get isCancelled =>
      reg.status == RegistrationStatus.cancelled ||
      event.status == EventStatus.cancelled;
}

class _JoinedList extends StatelessWidget {
  final String title;
  final String emptyMessage;
  final List<_Joined> items;
  final ValueChanged<_Joined> onOpen;
  final ValueChanged<_Joined>? onQr;
  final ValueChanged<_Joined>? onCancel;
  final ValueChanged<_Joined>? onFeedback;

  const _JoinedList({
    required this.title,
    required this.emptyMessage,
    required this.items,
    required this.onOpen,
    this.onQr,
    this.onCancel,
    this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyView(emptyMessage);
    }
    final sorted = [...items]
      ..sort((a, b) => a.event.startTime.compareTo(b.event.startTime));
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final item = sorted[index];
        final colorScheme = Theme.of(context).colorScheme;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: InkWell(
            onTap: () => onOpen(item),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.event.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatEventDate(item.event.startTime),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          item.event.location,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        StatusBadge(status: item.event.status),
                      ],
                    ),
                  ),
                   IconButton(
                     tooltip: 'View QR pass',
                     onPressed: item.reg.status == RegistrationStatus.cancelled
                         ? null
                         : () => onQr?.call(item),
                     icon: const Icon(Icons.qr_code_2),
                   ),
                   if (onFeedback != null &&
                       item.reg.status == RegistrationStatus.attended)
                     IconButton(
                       tooltip: 'Write feedback',
                       onPressed: () => onFeedback!.call(item),
                       icon: const Icon(Icons.rate_review_outlined),
                     ),
                  if (onCancel != null)
                    IconButton(
                      tooltip: 'Cancel registration',
                      onPressed: () => onCancel!(item),
                      icon: const Icon(Icons.cancel_outlined),
                      color: colorScheme.error,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
