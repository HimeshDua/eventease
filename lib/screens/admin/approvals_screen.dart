import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/event.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/misc_repositories.dart';
import '../../widgets/common.dart';

/// Admin approval queue for pending events and cancellation requests (SRS 1.6.16).
class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  final Set<String> _approvedChangeNotified = {};

  @override
  Widget build(BuildContext context) {
    final events = context.read<EventRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Approvals')),
      body: StreamBuilder<List<Event>>(
        stream: events.all(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const ErrorView('Could not load pending events.');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final allEvents = snapshot.data ?? const <Event>[];
          final pendingEvents =
              allEvents.where((e) => e.status == EventStatus.pending).toList()
                ..sort((a, b) {
                  final aTime =
                      a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final bTime =
                      b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return aTime.compareTo(bTime);
                });
          final cancellationRequests = allEvents
              .where((e) => e.cancellationRequested)
              .toList();

          if (pendingEvents.isEmpty && cancellationRequests.isEmpty) {
            return const EmptyView(
              'No events waiting for approval.',
              icon: Icons.fact_check_outlined,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (cancellationRequests.isNotEmpty) ...[
                Text(
                  'Cancellation requests',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final event in cancellationRequests)
                  _CancellationRequestCard(event: event),
                const SizedBox(height: 24),
              ],
              if (pendingEvents.isNotEmpty) ...[
                Text(
                  'Pending events',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final event in pendingEvents)
                  _PendingEventCard(
                    event: event,
                    onApproved: () => _notifyRegistrantsIfChanged(event),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// M25: when approving a critical-change re-review, notify active registrants.
  void _notifyRegistrantsIfChanged(Event event) {
    if (!event.changeReviewPending) return;
    if (_approvedChangeNotified.add(event.id)) {
      context.read<NotificationRepository>().sendToEventRegistrants(
        eventId: event.id,
        type: NotificationTypes.eventChanged,
        title: 'Event updated',
        message: '${event.title} has been updated and re-approved.',
      );
    }
  }
}

class _PendingEventCard extends StatefulWidget {
  final Event event;
  final VoidCallback onApproved;
  const _PendingEventCard({required this.event, required this.onApproved});

  @override
  State<_PendingEventCard> createState() => _PendingEventCardState();
}

class _PendingEventCardState extends State<_PendingEventCard> {
  bool _busy = false;

  Future<void> _approve() async {
    final confirmed = await confirm(
      context,
      'Approve event?',
      '${widget.event.title} will become visible to attendees.',
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<EventRepository>().setStatus(
        widget.event.id,
        EventStatus.approved,
      );
      await context.read<NotificationRepository>().send(
        userId: widget.event.organizerId,
        eventId: widget.event.id,
        type: NotificationTypes.approval,
        title: 'Event approved',
        message: '${widget.event.title} has been approved.',
      );
      widget.onApproved();
      messenger.showSnackBar(const SnackBar(content: Text('Event approved.')));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('$error'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject event'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            hintText: 'Why is this event not approved?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<EventRepository>().setStatus(
        widget.event.id,
        EventStatus.rejected,
      );
      await context.read<NotificationRepository>().send(
        userId: widget.event.organizerId,
        eventId: widget.event.id,
        type: NotificationTypes.rejection,
        title: 'Event rejected',
        message: reason.isEmpty
            ? '${widget.event.title} was not approved.'
            : '${widget.event.title} was not approved. Reason: $reason',
      );
      messenger.showSnackBar(const SnackBar(content: Text('Event rejected.')));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('$error'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (event.changeReviewPending)
                  const Chip(
                    label: Text('Critical change'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formatEventDate(event.startTime),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(event.location, style: Theme.of(context).textTheme.bodySmall),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _busy ? null : _reject,
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy ? null : _approve,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CancellationRequestCard extends StatefulWidget {
  final Event event;
  const _CancellationRequestCard({required this.event});

  @override
  State<_CancellationRequestCard> createState() =>
      _CancellationRequestCardState();
}

class _CancellationRequestCardState extends State<_CancellationRequestCard> {
  bool _busy = false;

  Future<void> _approve() async {
    final confirmed = await confirm(
      context,
      'Approve cancellation?',
      'Registered attendees will be notified that the event is cancelled.',
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final events = context.read<EventRepository>();
      final notifications = context.read<NotificationRepository>();
      await events.approveCancellation(widget.event.id);
      await notifications.sendToEventRegistrants(
        eventId: widget.event.id,
        type: NotificationTypes.cancelled,
        title: 'Event cancelled',
        message: '${widget.event.title} has been cancelled.',
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Cancellation approved.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('$error'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final confirmed = await confirm(
      context,
      'Reject cancellation request?',
      'The event will remain active and the request will be cleared.',
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<EventRepository>().rejectCancellation(widget.event.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Cancellation request rejected.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('$error'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Reason: ${event.cancellationReason ?? 'No reason provided'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _busy ? null : _reject,
                  child: const Text('Keep event'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy ? null : _approve,
                  child: const Text('Cancel event'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
