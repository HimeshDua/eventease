import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/event.dart';
import '../../models/event_feedback.dart';
import '../../models/registration.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/misc_repositories.dart';
import '../../repositories/registration_repository.dart';
import '../../widgets/common.dart';
import '../shared/gallery_screen.dart';
import 'announcements_screen.dart';
import 'event_form_screen.dart';
import 'gallery_upload_screen.dart';
import 'organizer_feedback_screen.dart';
import 'participants_screen.dart';
import 'scanner_screen.dart';

/// Organizer's management hub for a single event (SRS 1.6.11/1.6.12/1.6.18).
///
/// Provides access to edit, participants, QR scanning, announcements,
/// feedback, and gallery management from one place. Each action respects
/// the event lifecycle state.
class OrganizerEventDetailsScreen extends StatelessWidget {
  final String eventId;
  const OrganizerEventDetailsScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final events = context.read<EventRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event details'),
        actions: [
          IconButton(
            tooltip: 'Edit event',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _openEdit(context),
          ),
        ],
      ),
      body: StreamBuilder<Event>(
        stream: events.watch(eventId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const ErrorView('Could not load this event.');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final event = snapshot.data!;
          return StreamBuilder<List<Registration>>(
            stream: context.read<RegistrationRepository>().byEvent(eventId),
            builder: (context, regSnapshot) {
              final registrations = regSnapshot.data ?? const <Registration>[];
              return StreamBuilder<List<EventFeedback>>(
                stream: context.read<FeedbackRepository>().byEvent(eventId),
                builder: (context, feedbackSnapshot) {
                  final feedback =
                      feedbackSnapshot.data ?? const <EventFeedback>[];
                  return _Body(
                    event: event,
                    registrations: registrations,
                    feedback: feedback,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventFormScreen(eventId: eventId)),
    );
  }
}

class _Body extends StatelessWidget {
  final Event event;
  final List<Registration> registrations;
  final List<EventFeedback> feedback;
  const _Body({
    required this.event,
    required this.registrations,
    required this.feedback,
  });

  @override
  Widget build(BuildContext context) {
    final registered = registrations
        .where((r) => r.status == RegistrationStatus.registered)
        .length;
    final attended = registrations
        .where((r) => r.status == RegistrationStatus.attended)
        .length;
    final cancelled = registrations
        .where((r) => r.status == RegistrationStatus.cancelled)
        .length;

    final canScan = event.status == EventStatus.approved && !event.hasEnded;
    final canAnnounce =
        event.status == EventStatus.approved && !event.hasStarted;
    final canUploadGallery = event.isCompleted;
    final canRequestCancellation =
        event.status == EventStatus.approved &&
        !event.hasStarted &&
        !event.cancellationRequested;
    final averageRating = feedback.isEmpty
        ? 0.0
        : feedback.map((item) => item.rating).fold<int>(0, (a, b) => a + b) /
              feedback.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      event.imageUrl!,
                      height: 190,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  event.category,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(event.description),
                const SizedBox(height: 8),
                Text('Starts: ${formatEventDate(event.startTime)}'),
                Text('Ends: ${formatEventDate(event.endTime)}'),
                const SizedBox(height: 4),
                Text('Location: ${event.location}'),
                Text('Capacity: ${event.maxParticipants}'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    StatusBadge(status: event.status),
                    Chip(
                      label: Text('$registered registered'),
                      visualDensity: VisualDensity.compact,
                    ),
                    if (attended > 0)
                      Chip(
                        label: Text('$attended attended'),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (cancelled > 0)
                      Chip(
                        label: Text('$cancelled cancelled'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                if (event.changeReviewPending) ...[
                  const SizedBox(height: 8),
                  const Chip(label: Text('Critical change pending review')),
                ],
                if (event.cancellationRequested) ...[
                  const SizedBox(height: 8),
                  const Chip(
                    label: Text('Cancellation request pending review'),
                  ),
                ],
                const SizedBox(height: 12),
                if (event.rules.isNotEmpty) ...[
                  Text('Rules', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(event.rules),
                  const SizedBox(height: 8),
                ],
                if (event.contactInfo.isNotEmpty) ...[
                  Text(
                    'Contact',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(event.contactInfo),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Remaining capacity: ${event.availableSeats.clamp(0, event.maxParticipants)}',
                ),
                const SizedBox(height: 4),
                Text(
                  'Feedback: ${feedback.length} reviews · ${averageRating.toStringAsFixed(1)} / 5',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _ActionTile(
          icon: Icons.group_outlined,
          title: 'Participants',
          subtitle: 'View and manage registered attendees',
          onTap: () => _openParticipants(context),
        ),
        if (canScan)
          _ActionTile(
            icon: Icons.qr_code_scanner_outlined,
            title: 'Scan QR check-in',
            subtitle: 'Scan attendee passes for this event',
            onTap: () => _openScanner(context),
          ),
        if (canAnnounce)
          _ActionTile(
            icon: Icons.campaign_outlined,
            title: 'Send announcement',
            subtitle: 'Notify all active registrants',
            onTap: () => _openAnnouncements(context),
          ),
        _ActionTile(
          icon: Icons.rate_review_outlined,
          title: 'Feedback',
          subtitle: 'View ratings and comments from attendees',
          onTap: () => _openFeedback(context),
        ),
        if (canUploadGallery)
          _ActionTile(
            icon: Icons.photo_library_outlined,
            title: 'Upload gallery photo',
            subtitle: 'Add a photo to this event\'s gallery',
            onTap: () => _openGalleryUpload(context),
          ),
        if (event.isCompleted)
          _ActionTile(
            icon: Icons.image_outlined,
            title: 'View gallery',
            subtitle: 'Browse all gallery photos',
            onTap: () => _openGallery(context),
          ),
        if (canRequestCancellation)
          _ActionTile(
            icon: Icons.event_busy_outlined,
            title: 'Request cancellation',
            subtitle: 'Ask an administrator to cancel this event',
            onTap: () => _requestCancellation(context),
            foregroundColor: Theme.of(context).colorScheme.error,
            iconColor: Theme.of(context).colorScheme.error,
          ),
      ],
    );
  }

  void _openParticipants(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ParticipantsScreen(eventId: event.id)),
    );
  }

  void _openScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ScannerScreen(eventId: event.id)),
    );
  }

  void _openAnnouncements(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AnnouncementsScreen(eventId: event.id, eventTitle: event.title),
      ),
    );
  }

  void _openFeedback(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrganizerFeedbackScreen(eventId: event.id),
      ),
    );
  }

  void _openGalleryUpload(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GalleryUploadScreen(eventId: event.id)),
    );
  }

  void _openGallery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GalleryScreen(eventId: event.id)),
    );
  }

  Future<void> _requestCancellation(BuildContext context) async {
    final events = context.read<EventRepository>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request cancellation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your request will be reviewed by an administrator. '
              'Registered attendees will be notified.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Reason (required)',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Submit request'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = reason?.trim() ?? '';
    if (trimmed.isEmpty) return;
    try {
      await events.requestCancellation(event.id, trimmed);
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Cancellation request submitted.')),
        );
      }
      navigator.pop();
      // cancellation request failed (not owned, already requested, network error)
    } catch (error) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(friendlyError(error)),
            backgroundColor: colorScheme.errorContainer,
          ),
        );
      }
    }
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? foregroundColor;
  final Color? iconColor;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.foregroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        foregroundColor ?? Theme.of(context).colorScheme.onSurface;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? effectiveColor),
        title: Text(title, style: TextStyle(color: effectiveColor)),
        subtitle: Text(subtitle),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        enabled: onTap != null,
        onTap: onTap,
      ),
    );
  }
}
