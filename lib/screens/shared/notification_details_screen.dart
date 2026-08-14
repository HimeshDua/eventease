import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../repositories/misc_repositories.dart';
import '../../widgets/common.dart';

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
          ],
        ),
      ),
    );
  }
}
