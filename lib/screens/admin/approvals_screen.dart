import 'package:eventease/models/app_user.dart';
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
  @override
  Widget build(BuildContext context) {
    final events = context.read<EventRepository>();
    final users = context.read<UserRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Approvals')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          return SizedBox(
            width: width,
            child: StreamBuilder<List<Event>>(
              stream: events.watchPendingEvents(),
              builder: (context, pendingSnapshot) {
                if (pendingSnapshot.hasError) {
                  return ErrorView(
                    'Could not load pending events: ${friendlyError(pendingSnapshot.error!)}',
                    actionLabel: 'Retry',
                    onAction: () => setState(() {}),
                  );
                }
                if (pendingSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const LoadingView();
                }

                return StreamBuilder<List<Event>>(
                  stream: events.watchCancellationRequests(),
                  builder: (context, cancellationSnapshot) {
                    if (cancellationSnapshot.hasError) {
                      return ErrorView(
                        'Could not load cancellation requests: ${friendlyError(cancellationSnapshot.error!)}',
                        actionLabel: 'Retry',
                        onAction: () => setState(() {}),
                      );
                    }
                    if (cancellationSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const LoadingView();
                    }

                    return StreamBuilder<List<AppUser>>(
                      stream: users.organizerRequests(),
                      builder: (context, organizerSnapshot) {
                        if (organizerSnapshot.hasError) {
                          return ErrorView(
                            'Could not load organizer requests: ${friendlyError(organizerSnapshot.error!)}',
                            actionLabel: 'Retry',
                            onAction: () => setState(() {}),
                          );
                        }
                        if (organizerSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LoadingView();
                        }

                        final pendingEvents =
                            [...(pendingSnapshot.data ?? const <Event>[])]
                              ..sort((a, b) {
                                final aTime =
                                    a.createdAt ??
                                    DateTime.fromMillisecondsSinceEpoch(0);
                                final bTime =
                                    b.createdAt ??
                                    DateTime.fromMillisecondsSinceEpoch(0);
                                return aTime.compareTo(bTime);
                              });
                        final cancellationRequests =
                            cancellationSnapshot.data ?? const <Event>[];
                        final organizerRequests =
                            [...(organizerSnapshot.data ?? const <AppUser>[])]
                              ..sort(
                                (a, b) => a.name.toLowerCase().compareTo(
                                  b.name.toLowerCase(),
                                ),
                              );

                        if (pendingEvents.isEmpty &&
                            cancellationRequests.isEmpty &&
                            organizerRequests.isEmpty) {
                          return const EmptyView(
                            'No pending approvals.',
                            icon: Icons.fact_check_outlined,
                          );
                        }

                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width,
                          ),
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (organizerRequests.isNotEmpty) ...[
                                Text(
                                  'Organizer requests',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                for (final user in organizerRequests)
                                  SizedBox(
                                    width: double.infinity,
                                    child: _OrganizerRequestCard(user: user),
                                  ),
                                const SizedBox(height: 24),
                              ],
                              if (cancellationRequests.isNotEmpty) ...[
                                Text(
                                  'Cancellation requests',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                for (final event in cancellationRequests)
                                  SizedBox(
                                    width: double.infinity,
                                    child: _CancellationRequestCard(
                                      event: event,
                                    ),
                                  ),
                                const SizedBox(height: 24),
                              ],
                              if (pendingEvents.isNotEmpty) ...[
                                Text(
                                  'Pending events',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                for (final event in pendingEvents)
                                  SizedBox(
                                    width: double.infinity,
                                    child: _PendingEventCard(
                                      event: event,
                                      onApproved: () =>
                                          _notifyRegistrantsIfChanged(event),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// M25: when approving a critical-change re-review, notify active registrants.
  void _notifyRegistrantsIfChanged(Event event) {
    if (!event.changeReviewPending) return;
    context.read<NotificationRepository>().sendToEventRegistrants(
      eventId: event.id,
      type: NotificationTypes.eventChanged,
      title: 'Event updated',
      message: '${event.title} has been updated and re-approved.',
    );
  }
}

class _OrganizerRequestCard extends StatefulWidget {
  final AppUser user;
  const _OrganizerRequestCard({required this.user});

  @override
  State<_OrganizerRequestCard> createState() => _OrganizerRequestCardState();
}

class _OrganizerRequestCardState extends State<_OrganizerRequestCard> {
  bool _busy = false;

  Future<void> _approve() async {
    final users = context.read<UserRepository>();
    final notifications = context.read<NotificationRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await confirm(
      context,
      'Approve organizer request?',
      '${widget.user.name} will be granted organizer access.',
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      await users.approveOrganizerRequest(widget.user.id);
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(friendlyError(error)),
          backgroundColor: colorScheme.errorContainer,
        ),
      );
      setState(() => _busy = false);
      return;
    }
    try {
      await notifications.send(
        userId: widget.user.id,
        type: NotificationTypes.roleApproved,
        title: 'Organizer access approved',
        message: 'You can now create and manage events.',
      );
    } catch (error) {
      debugPrint('Notification failed: $error');
    }
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Organizer request approved.')),
    );
    setState(() => _busy = false);
  }

  Future<void> _reject() async {
    final users = context.read<UserRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await confirm(
      context,
      'Reject organizer request?',
      '${widget.user.name} will remain an attendee and the request will be cleared.',
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      await users.rejectOrganizerRequest(widget.user.id);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Organizer request rejected.')),
      );
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
    final user = widget.user;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(user.email),
            if (user.phone.isNotEmpty) Text(user.phone),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: _busy ? null : _reject,
                    child: const Text('Reject'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
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
            ),
          ],
        ),
      ),
    );
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
    final events = context.read<EventRepository>();
    final notifications = context.read<NotificationRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await confirm(
      context,
      'Approve event?',
      '${widget.event.title} will become visible to attendees.',
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      await events.setStatus(widget.event.id, EventStatus.approved);
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(friendlyError(error)),
          backgroundColor: colorScheme.errorContainer,
        ),
      );
      setState(() => _busy = false);
      return;
    }
    try {
      await notifications.send(
        userId: widget.event.organizerId,
        eventId: widget.event.id,
        type: NotificationTypes.approval,
        title: 'Event approved',
        message: '${widget.event.title} has been approved.',
      );
    } catch (error) {
      debugPrint('Notification failed: $error');
    }
    try {
      widget.onApproved();
    } catch (error) {
      debugPrint('Registrant notification failed: $error');
    }
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Event approved.')));
    setState(() => _busy = false);
  }

  Future<void> _reject() async {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final events = context.read<EventRepository>();
    final notifications = context.read<NotificationRepository>();
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
    try {
      await events.setStatus(widget.event.id, EventStatus.rejected);
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(friendlyError(error)),
          backgroundColor: colorScheme.errorContainer,
        ),
      );
      setState(() => _busy = false);
      return;
    }
    try {
      await notifications.send(
        userId: widget.event.organizerId,
        eventId: widget.event.id,
        type: NotificationTypes.rejection,
        title: 'Event rejected',
        message: reason.isEmpty
            ? '${widget.event.title} was not approved.'
            : '${widget.event.title} was not approved. Reason: $reason',
      );
    } catch (error) {
      debugPrint('Notification failed: $error');
    }
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Event rejected.')));
    setState(() => _busy = false);
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
            Text(event.title, style: Theme.of(context).textTheme.titleMedium),
            if (event.changeReviewPending) ...[
              const SizedBox(height: 6),
              const Chip(
                label: Text('Critical change'),
                visualDensity: VisualDensity.compact,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              formatEventDate(event.startTime),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(event.location, style: Theme.of(context).textTheme.bodySmall),
            const Divider(height: 24),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: _busy ? null : _reject,
                    child: const Text('Reject'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
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
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final events = context.read<EventRepository>();
    final notifications = context.read<NotificationRepository>();
    final confirmed = await confirm(
      context,
      'Approve cancellation?',
      'Registered attendees will be notified that the event is cancelled.',
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      await events.approveCancellation(widget.event.id);
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(friendlyError(error)),
          backgroundColor: colorScheme.errorContainer,
        ),
      );
      setState(() => _busy = false);
      return;
    }
    try {
      await notifications.sendToEventRegistrants(
        eventId: widget.event.id,
        type: NotificationTypes.cancelled,
        title: 'Event cancelled',
        message: '${widget.event.title} has been cancelled.',
      );
    } catch (error) {
      debugPrint('Notification failed: $error');
    }
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Cancellation approved.')),
    );
    setState(() => _busy = false);
  }

  Future<void> _reject() async {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final events = context.read<EventRepository>();
    final confirmed = await confirm(
      context,
      'Reject cancellation request?',
      'The event will remain active and the request will be cleared.',
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      await events.rejectCancellation(widget.event.id);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Cancellation request rejected.')),
      );
      // Approve/reject cancellations: Firestore write failure or notification fan-out error
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
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: _busy ? null : _reject,
                    child: const Text('Keep event'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: _busy ? null : _approve,
                    child: const Text('Cancel event'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
