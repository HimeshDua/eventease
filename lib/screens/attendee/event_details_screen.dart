import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/app_user.dart';
import '../../models/event.dart';
import '../../models/gallery_item.dart';
import '../../models/registration.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/gallery_repository.dart';
import '../../repositories/misc_repositories.dart';
import '../../repositories/registration_repository.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';
import '../../widgets/event_map.dart';
import '../shared/gallery_screen.dart';
import 'feedback_screen.dart';
import 'registration_confirmation_screen.dart';

/// Full event details: map, favorites, registration, gallery preview (SRS 1.6.5/1.6.6).
class EventDetailsScreen extends StatelessWidget {
  final String eventId;
  const EventDetailsScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final events = context.read<EventRepository>();
    final registrations = context.read<RegistrationRepository>();
    final favorites = context.read<FavoriteRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: StreamBuilder<Event>(
        stream: events.watch(eventId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const ErrorView('We could not load this event.');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final event = snapshot.data!;
          final user = context.read<AuthService>().currentUser;

          return StreamBuilder<Set<String>>(
            stream: favorites.eventIds(user?.id ?? ''),
            builder: (context, favSnapshot) {
              final isFavorite = (favSnapshot.data ?? const <String>{})
                  .contains(event.id);
              return StreamBuilder<List<Registration>>(
                stream: registrations.byUser(user?.id ?? ''),
                builder: (context, regSnapshot) {
                  final regs = regSnapshot.data ?? const <Registration>[];
                  Registration? myRegistration;
                  for (final r in regs) {
                    if (r.eventId == event.id) {
                      myRegistration = r;
                      break;
                    }
                  }
                  return _EventBody(
                    event: event,
                    user: user,
                    isFavorite: isFavorite,
                    myRegistration: myRegistration,
                    onToggleFavorite: () {
                      if (user == null) return;
                      if (isFavorite) {
                        favorites.remove(user.id, event.id);
                      } else {
                        favorites.add(user.id, event.id);
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _EventBody extends StatelessWidget {
  final Event event;
  final AppUser? user;
  final bool isFavorite;
  final Registration? myRegistration;
  final VoidCallback onToggleFavorite;

  const _EventBody({
    required this.event,
    required this.user,
    required this.isFavorite,
    required this.myRegistration,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: event.imageUrl!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (c, u) => Container(
              height: 200,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            errorWidget: (c, u, e) => Container(
              height: 200,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: isFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                    onPressed: onToggleFavorite,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(event.category)),
                  StatusBadge(status: event.status),
                  if (event.changeReviewPending)
                    const Chip(label: Text('Under review')),
                ],
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.calendar_month_outlined,
                text:
                    '${formatEventDate(event.startTime)}\n${formatEventDate(event.endTime)}',
              ),
              const SizedBox(height: 8),
              _InfoRow(icon: Icons.place_outlined, text: event.location),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.group_outlined,
                text: event.isFull
                    ? 'Event is full'
                    : '${event.availableSeats} of ${event.maxParticipants} seats available',
              ),
              if (event.contactInfo.isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.contact_phone_outlined,
                  text: event.contactInfo,
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'About this event',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                event.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (event.rules.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Rules', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  event.rules,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 24),
              Text('Location', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              EventMap(
                latitude: event.latitude,
                longitude: event.longitude,
                locationName: event.location,
              ),
              if (event.isCompleted) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Gallery',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GalleryScreen(eventId: event.id),
                        ),
                      ),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _GalleryPreview(eventId: event.id),
              ],
              const SizedBox(height: 24),
              _RegistrationArea(
                event: event,
                registration: myRegistration,
                user: user,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _RegistrationArea extends StatefulWidget {
  final Event event;
  final Registration? registration;
  final AppUser? user;
  const _RegistrationArea({
    required this.event,
    required this.registration,
    required this.user,
  });

  @override
  State<_RegistrationArea> createState() => _RegistrationAreaState();
}

class _RegistrationAreaState extends State<_RegistrationArea> {
  bool _busy = false;

  Future<void> _register() async {
    final user = widget.user;
    if (user == null) return;
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final registrations = context.read<RegistrationRepository>();
    final notifications = context.read<NotificationRepository>();
    final colorScheme = Theme.of(context).colorScheme;
    try {
      final registration = await registrations.register(
        widget.event.id,
        user.id,
      );
      await notifications.send(
        userId: user.id,
        eventId: widget.event.id,
        type: NotificationTypes.registration,
        title: 'Registration confirmed',
        message: 'You are registered for ${widget.event.title}.',
      );
      if (!mounted) return;
      navigator.push(
        MaterialPageRoute(
          builder: (_) => RegistrationConfirmationScreen(
            eventId: widget.event.id,
            registration: registration,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('$error'),
          backgroundColor: colorScheme.errorContainer,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final reg = widget.registration;
    if (reg == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final registrations = context.read<RegistrationRepository>();
    final confirmed = await confirm(
      context,
      'Cancel registration?',
      'Your seat will be released. This cannot be undone.',
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      await registrations.cancel(reg);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Registration cancelled.')),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('$error'),
          backgroundColor: colorScheme.errorContainer,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reg = widget.registration;
    final status = widget.event.status;
    final canRegister =
        widget.user != null &&
        status == EventStatus.approved &&
        !widget.event.hasStarted &&
        !widget.event.isFull &&
        (reg == null || reg.status == RegistrationStatus.cancelled);

    if (reg == null) {
      if (status != EventStatus.approved) return const SizedBox.shrink();
      if (widget.event.isFull) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.event_busy_outlined),
                SizedBox(height: 8),
                Text('This event is full.'),
              ],
            ),
          ),
        );
      }
      if (widget.event.hasStarted) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'This event has already started.',
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      return FilledButton(
        onPressed: _busy ? null : _register,
        child: _busy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Register for this event'),
      );
    }

    final label = switch (reg.status) {
      RegistrationStatus.registered => 'Registered',
      RegistrationStatus.attended => 'Attended',
      RegistrationStatus.cancelled => 'Registration cancelled',
      _ => '',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  reg.status == RegistrationStatus.attended
                      ? Icons.check_circle_outline
                      : Icons.confirmation_number_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (reg.status == RegistrationStatus.registered &&
                !widget.event.hasStarted) ...[
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: _busy ? null : _cancel,
                child: const Text('Cancel registration'),
              ),
            ],
            if (reg.status == RegistrationStatus.cancelled && canRegister) ...[
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _busy ? null : _register,
                child: const Text('Register again'),
              ),
            ],
            if (reg.status == RegistrationStatus.attended &&
                widget.event.isCompleted) ...[
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FeedbackScreen(eventId: widget.event.id),
                  ),
                ),
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Write feedback'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Latest gallery preview for completed events (SRS 1.6.18).
class _GalleryPreview extends StatelessWidget {
  final String eventId;
  const _GalleryPreview({required this.eventId});

  @override
  Widget build(BuildContext context) {
    final gallery = context.read<GalleryRepository>();
    return StreamBuilder<List<GalleryItem>>(
      stream: gallery.byEvent(eventId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const ErrorView('Could not load gallery.');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }
        final items = snapshot.data ?? const <GalleryItem>[];
        if (items.isEmpty) {
          return const EmptyView(
            'No gallery photos yet.',
            icon: Icons.photo_outlined,
          );
        }
        return SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: 100,
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) => Container(
                    width: 100,
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
