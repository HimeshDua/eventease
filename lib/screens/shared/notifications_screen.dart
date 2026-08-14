import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/misc_repositories.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';
import 'notification_details_screen.dart';

/// Notification history, newest first, with unread styling (SRS 1.6.9).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      return const ErrorView('Please sign in to view notifications.');
    }
    final notifications = context.read<NotificationRepository>();
    final events = context.read<EventRepository>();

    return StreamBuilder<List<AppNotification>>(
      stream: notifications.byUser(user.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const ErrorView('Could not load notifications.');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }
        final items = snapshot.data ?? const <AppNotification>[];
        if (items.isEmpty) {
          return const EmptyView(
            'No notifications yet.',
            icon: Icons.notifications_none,
          );
        }
        return StreamBuilder<Map<String, String>>(
          stream: events.all().map(
            (list) => {for (final event in list) event.id: event.title},
          ),
          builder: (context, eventSnapshot) {
            final eventTitles = eventSnapshot.data ?? const <String, String>{};
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final eventTitle = item.eventId == null
                    ? null
                    : eventTitles[item.eventId];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  color: item.isRead
                      ? null
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: ListTile(
                    title: Text(
                      item.title,
                      style: item.isRead
                          ? Theme.of(context).textTheme.bodyLarge
                          : Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (eventTitle != null)
                          Text(
                            eventTitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        Text(
                          item.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: !item.isRead
                        ? Icon(
                            Icons.circle,
                            size: 12,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            NotificationDetailsScreen(notification: item),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
