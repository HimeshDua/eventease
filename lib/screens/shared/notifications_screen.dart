import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
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
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
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
                    if (item.eventId != null && item.eventId!.isNotEmpty)
                      Text(
                        'Event notification',
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
  }
}
