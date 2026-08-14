import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../repositories/misc_repositories.dart';
import '../../widgets/common.dart';
import '../attendee/feedback_screen.dart';
import '../attendee/my_events_screen.dart';
import '../attendee/event_details_screen.dart';

/// Full notification view; marks the item read when opened (SRS 1.6.9).
class NotificationDetailsScreen extends StatefulWidget {
  final AppNotification notification;
  const NotificationDetailsScreen({super.key, required this.notification});

  @override
  State<NotificationDetailsScreen> createState() =>
      _NotificationDetailsScreenState();
}

class _NotificationDetailsScreenState extends State<NotificationDetailsScreen> {
  bool _markInitiated = false;

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  Future<void> _markRead() async {
    if (_markInitiated || widget.notification.isRead) return;
    _markInitiated = true;
    try {
      await context.read<NotificationRepository>().markRead(
        widget.notification.id,
      );
    } catch (_) {
      // A failed read-mark must not crash the details view.
    }
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Notification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notification.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (notification.createdAt != null)
              Text(
                formatEventDate(notification.createdAt!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const Divider(height: 32),
            Text(
              notification.message,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (_actionFor(context, notification) != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      _actionFor(context, notification)!.action(context),
                  icon: Icon(_actionFor(context, notification)!.icon),
                  label: Text(_actionFor(context, notification)!.label),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationAction {
  final IconData icon;
  final String label;
  final void Function(BuildContext) action;
  const _NotificationAction(this.icon, this.label, this.action);
}

_NotificationAction? _actionFor(
  BuildContext context,
  AppNotification notification,
) {
  final eventId = notification.eventId;
  if (eventId == null || eventId.isEmpty) return null;
  switch (notification.type) {
    case NotificationTypes.feedbackRequest:
      return _NotificationAction(
        Icons.rate_review_outlined,
        'Write feedback',
        (context) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FeedbackScreen(eventId: eventId),
          ),
        ),
      );
    case NotificationTypes.registration:
    case NotificationTypes.announcement:
    case NotificationTypes.eventChanged:
    case NotificationTypes.cancelled:
      return _NotificationAction(
        Icons.event_outlined,
        'View event',
        (context) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailsScreen(eventId: eventId),
          ),
        ),
      );
    case NotificationTypes.reminder:
      return _NotificationAction(
        Icons.event_available_outlined,
        'Open My Events',
        (context) => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyEventsScreen()),
        ),
      );
    default:
      return null;
  }
}
