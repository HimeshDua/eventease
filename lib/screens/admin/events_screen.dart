import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/event.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/misc_repositories.dart';
import '../../widgets/common.dart';
import '../organizer/event_form_screen.dart';
import '../organizer/participants_screen.dart';
import '../shared/gallery_screen.dart';

/// Admin event management: view, search, filter, edit, cancel, delete (SRS 1.6.16).
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _search = TextEditingController();
  String _query = '';
  String _statusFilter = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = context.read<EventRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('All events')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: SearchBar(
                controller: _search,
              hintText: 'Search events',
              leading: const Icon(Icons.search),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close),
                  ),
              ],
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _StatusFilterChip(
                  label: 'All',
                  selected: _statusFilter == 'all',
                  onSelected: () => setState(() => _statusFilter = 'all'),
                ),
                for (final status in const [
                  EventStatus.pending,
                  EventStatus.approved,
                  EventStatus.rejected,
                  EventStatus.cancelled,
                  EventStatus.completed,
                ])
                  _StatusFilterChip(
                    label: _statusLabel(status),
                    selected: _statusFilter == status,
                    onSelected: () => setState(() => _statusFilter = status),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Event>>(
              stream: events.all(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorView(
                    'Could not load events: ${friendlyError(snapshot.error!)}',
                    actionLabel: 'Retry',
                    onAction: () => setState(() {}),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView();
                }
                var items = snapshot.data ?? const <Event>[];
                final normalized = _query.trim().toLowerCase();
                if (normalized.isNotEmpty) {
                  items = items
                      .where(
                        (e) =>
                            e.title.toLowerCase().contains(normalized) ||
                            e.location.toLowerCase().contains(normalized) ||
                            e.category.toLowerCase().contains(normalized),
                      )
                      .toList();
                }
                if (_statusFilter != 'all') {
                  items = items
                      .where((e) => e.status == _statusFilter)
                      .toList();
                }
                final sorted = [...items]
                  ..sort((a, b) {
                    final aTime =
                        a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                    final bTime =
                        b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                    return bTime.compareTo(aTime);
                  });
                if (sorted.isEmpty) {
                  return const EmptyView('No events match your search.');
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final event = sorted[index];
                    return _AdminEventCard(
                      event: event,
                      onOpen: () => _openDetails(context, event),
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

  void _openDetails(BuildContext context, Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _AdminEventDetails(event: event)),
    );
  }

  String _statusLabel(String status) => switch (status) {
    EventStatus.pending => 'Pending',
    EventStatus.approved => 'Approved',
    EventStatus.rejected => 'Rejected',
    EventStatus.cancelled => 'Cancelled',
    EventStatus.completed => 'Completed',
    _ => status,
  };
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _AdminEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onOpen;
  const _AdminEventCard({required this.event, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                formatEventDate(event.startTime),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                event.location,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  StatusBadge(status: event.status),
                  Chip(
                    label: Text('${event.registeredCount} registered'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminEventDetails extends StatefulWidget {
  final Event event;
  const _AdminEventDetails({required this.event});

  @override
  State<_AdminEventDetails> createState() => _AdminEventDetailsState();
}

class _AdminEventDetailsState extends State<_AdminEventDetails> {
  bool _busy = false;

  Future<void> _cancelWithReason() async {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final events = context.read<EventRepository>();
    final notifications = context.read<NotificationRepository>();
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel event'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Cancellation reason',
            hintText: 'Why is this event being cancelled?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Dismiss'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Cancel event'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.isEmpty) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: const Text('A cancellation reason is required.'),
          backgroundColor: colorScheme.errorContainer,
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await events.setStatus(widget.event.id, EventStatus.cancelled);
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
        message: '${widget.event.title} has been cancelled. Reason: $reason',
      );
    } catch (error) {
      debugPrint('Notification failed: $error');
    }
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Event cancelled.')));
    setState(() => _busy = false);
  }

  Future<void> _delete() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final events = context.read<EventRepository>();
    final confirmed = await confirm(
      context,
      'Delete this event permanently?',
      'This removes the event and all of its media. Only possible for events with no registrations.',
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      await events.adminDelete(widget.event.id);
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Event deleted.')));
      navigator.pop();
    // Delete: event has registrations, media deletion failure, or Firestore denial
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
    return Scaffold(
      appBar: AppBar(title: const Text('Event details')),
      body: StreamBuilder<Event>(
        stream: context.read<EventRepository>().watch(event.id),
        builder: (context, snapshot) {
          final current = snapshot.data ?? event;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                current.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  StatusBadge(status: current.status),
                  if (current.changeReviewPending)
                    const Chip(label: Text('Critical change pending review')),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                formatEventDate(current.startTime),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(current.location),
              const SizedBox(height: 4),
              Text(
                '${current.registeredCount}/${current.maxParticipants} registered',
              ),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ParticipantsScreen(eventId: current.id),
                  ),
                ),
                icon: const Icon(Icons.group_outlined),
                label: const Text('View participants'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GalleryScreen(eventId: current.id),
                  ),
                ),
                icon: const Icon(Icons.photo_outlined),
                label: const Text('View gallery'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventFormScreen(eventId: current.id),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit event'),
              ),
              if (current.status != EventStatus.cancelled) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _cancelWithReason,
                  icon: const Icon(Icons.event_busy_outlined),
                  label: const Text('Cancel event'),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy ? null : _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete event permanently'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
