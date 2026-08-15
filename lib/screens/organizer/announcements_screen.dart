import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/misc_repositories.dart';
import '../../widgets/common.dart';

/// Send an announcement to all non-cancelled registrants (SRS 1.6.12).
class AnnouncementsScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  const AnnouncementsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _message = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _message.text.trim();
    if (message.isEmpty) {
      showSnack(context, 'Please enter an announcement message.',
          error: true);
      return;
    }
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    try {
      await context.read<NotificationRepository>().sendToEventRegistrants(
            eventId: widget.eventId,
            type: NotificationTypes.announcement,
            title: 'Announcement',
            message: message,
          );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Announcement sent to participants.')),
      );
      navigator.pop();
    // announcement delivery failed (network error, no registrants)
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(friendlyError(error)),
          backgroundColor: colorScheme.errorContainer,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send announcement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.eventTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'This message will be sent to every active registrant of the event.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _message,
              decoration: const InputDecoration(
                labelText: 'Announcement message',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _send,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send announcement'),
            ),
          ],
        ),
      ),
    );
  }
}
