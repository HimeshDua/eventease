import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/app_notification.dart';
import '../../models/app_user.dart';
import '../../models/event.dart';
import '../../models/registration.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/misc_repositories.dart';
import '../../repositories/registration_repository.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';
import 'discover_screen.dart';
import 'event_details_screen.dart';
import 'favorites_screen.dart';
import 'my_events_screen.dart';
import '../shared/notifications_screen.dart';

/// Personalized attendee home dashboard (SRS 1.6.2).
class AttendeeDashboard extends StatelessWidget {
  const AttendeeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return _GreetingHeader(
      child: StreamBuilder<AppUser?>(
        stream: context.read<AuthService>().userStream,
        builder: (context, userSnapshot) {
          final user = userSnapshot.data;
          if (user == null) {
            return const ErrorView('Please sign in to view your dashboard.');
          }
          return DashboardBody(user: user);
        },
      ),
    );
  }
}

/// Top greeting area that stays pinned above the scrolling dashboard.
class _GreetingHeader extends StatelessWidget {
  final Widget child;
  const _GreetingHeader({required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class DashboardBody extends StatelessWidget {
  final AppUser user;
  const DashboardBody({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final events = context.read<EventRepository>();
    final registrations = context.read<RegistrationRepository>();
    final favorites = context.read<FavoriteRepository>();
    final notifications = context.read<NotificationRepository>();

    return StreamBuilder<List<Event>>(
      stream: events.approvedUpcoming(),
      builder: (context, eventSnapshot) {
        return StreamBuilder<List<Registration>>(
          stream: registrations.byUser(user.id),
          builder: (context, regSnapshot) {
            return StreamBuilder<Set<String>>(
              stream: favorites.eventIds(user.id),
              builder: (context, favSnapshot) {
                return StreamBuilder<List<AppNotification>>(
                  stream: notifications.byUser(user.id),
                  builder: (context, notificationSnapshot) {
                    final upcomingEvents =
                        eventSnapshot.data ?? const <Event>[];
                    final regs = regSnapshot.data ?? const <Registration>[];

                    final favoriteEvents = <Event>[];
                    final upcomingRegistered = <Event>[];

                    for (final reg in regs) {
                      final event = upcomingEvents
                          .where((e) => e.id == reg.eventId)
                          .firstOrNull;
                      if (event == null) continue;
                      if (reg.status == RegistrationStatus.registered &&
                          !event.hasEnded) {
                        upcomingRegistered.add(event);
                      }
                    }

                    final favoriteIds = favSnapshot.data ?? const <String>{};
                    favoriteEvents.addAll(
                      upcomingEvents
                          .where((e) => favoriteIds.contains(e.id))
                          .toList(),
                    );

                    final unreadCount =
                        (notificationSnapshot.data ?? const <AppNotification>[])
                            .where((n) => !n.isRead)
                            .length;

                    final hasError =
                        eventSnapshot.hasError ||
                        regSnapshot.hasError ||
                        favSnapshot.hasError ||
                        notificationSnapshot.hasError;
                    final isLoading =
                        eventSnapshot.connectionState ==
                            ConnectionState.waiting ||
                        regSnapshot.connectionState == ConnectionState.waiting;

                    if (hasError) {
                      return const ErrorView(
                        'We could not load your dashboard. Please try again.',
                      );
                    }
                    if (isLoading) {
                      return const LoadingView();
                    }

                    final nextRegistered =
                        upcomingRegistered.where((e) => !e.hasEnded).toList()
                          ..sort((a, b) => a.startTime.compareTo(b.startTime));

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Hello, ${user.name.split(' ').first}!',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Discover your next experience.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        _QuickActions(
                          onDiscover: () =>
                              _push(context, const DiscoverScreen()),
                          onMyEvents: () =>
                              _push(context, const MyEventsScreen()),
                          onFavorites: () =>
                              _push(context, const FavoritesScreen()),
                          onNotifications: () =>
                              _push(context, const NotificationsScreen()),
                        ),
                        const SizedBox(height: 24),
                        if (nextRegistered.isNotEmpty) ...[
                          _SectionHeader(
                            title: 'Next registered event',
                            onSeeAll: () =>
                                _push(context, const MyEventsScreen()),
                          ),
                          const SizedBox(height: 8),
                          EventCard(
                            event: nextRegistered.first,
                            onTap: () =>
                                _openDetails(context, nextRegistered.first),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (upcomingEvents.isNotEmpty) ...[
                          _SectionHeader(
                            title: 'Upcoming events',
                            onSeeAll: () =>
                                _push(context, const DiscoverScreen()),
                          ),
                          const SizedBox(height: 8),
                          ...upcomingEvents
                              .take(3)
                              .map(
                                (event) => EventCard(
                                  event: event,
                                  onTap: () => _openDetails(context, event),
                                ),
                              ),
                          const SizedBox(height: 16),
                        ],
                        if (favoriteEvents.isNotEmpty) ...[
                          _SectionHeader(
                            title: 'Your favorites',
                            onSeeAll: () =>
                                _push(context, const FavoritesScreen()),
                          ),
                          const SizedBox(height: 8),
                          ...favoriteEvents
                              .take(3)
                              .map(
                                (event) => EventCard(
                                  event: event,
                                  onTap: () => _openDetails(context, event),
                                ),
                              ),
                          const SizedBox(height: 16),
                        ],
                        _SectionHeader(
                          title: 'Notifications',
                          trailing: unreadCount > 0
                              ? Chip(
                                  label: Text('$unreadCount unread'),
                                  visualDensity: VisualDensity.compact,
                                )
                              : null,
                          onSeeAll: () =>
                              _push(context, const NotificationsScreen()),
                        ),
                        const SizedBox(height: 8),
                        const _UnreadNotificationsPreview(),
                        const SizedBox(height: 32),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _openDetails(BuildContext context, Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailsScreen(eventId: event.id)),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onDiscover;
  final VoidCallback onMyEvents;
  final VoidCallback onFavorites;
  final VoidCallback onNotifications;

  const _QuickActions({
    required this.onDiscover,
    required this.onMyEvents,
    required this.onFavorites,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.explore_outlined,
            label: 'Discover',
            onTap: onDiscover,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickAction(
            icon: Icons.event_outlined,
            label: 'My Events',
            onTap: onMyEvents,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickAction(
            icon: Icons.favorite_outline,
            label: 'Favorites',
            onTap: onFavorites,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickAction(
            icon: Icons.notifications_outlined,
            label: 'Alerts',
            onTap: onNotifications,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.trailing, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      ...[trailing].whereType<Widget>(),
      if (onSeeAll != null)
        TextButton(onPressed: onSeeAll, child: const Text('See all')),
    ];
    return Row(children: children);
  }
}

class _UnreadNotificationsPreview extends StatelessWidget {
  const _UnreadNotificationsPreview();

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return const SizedBox.shrink();
    final notifications = context.read<NotificationRepository>();
    return StreamBuilder<List<AppNotification>>(
      stream: notifications.byUser(user.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        final items = snapshot.data ?? const <AppNotification>[];
        final unread = items.where((n) => !n.isRead).take(2).toList();
        if (unread.isEmpty) {
          return Card(
            child: ListTile(
              leading: Icon(
                Icons.notifications_none,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              title: const Text('You are all caught up'),
            ),
          );
        }
        return Column(
          children: [
            for (final item in unread)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(
                    Icons.notifications_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    item.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
