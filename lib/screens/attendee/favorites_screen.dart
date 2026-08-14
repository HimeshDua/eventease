import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/misc_repositories.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';
import 'event_details_screen.dart';

/// Favorite events list (SRS 1.6.8).
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      return const ErrorView('Please sign in to view favorites.');
    }
    final favorites = context.read<FavoriteRepository>();
    final events = context.read<EventRepository>();

    return StreamBuilder<Set<String>>(
      stream: favorites.eventIds(user.id),
      builder: (context, favSnapshot) {
        if (favSnapshot.hasError) {
          return const ErrorView('Could not load your favorites.');
        }
        if (favSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }
        final favoriteIds = favSnapshot.data ?? const <String>{};
        if (favoriteIds.isEmpty) {
          return const EmptyView(
            'No favorites yet. Tap the heart on an event to save it here.',
            icon: Icons.favorite_border,
          );
        }
        return StreamBuilder<List<Event>>(
          stream: events.all(),
          builder: (context, eventSnapshot) {
            if (eventSnapshot.hasError) {
              return const ErrorView('Could not load events.');
            }
            final allEvents = eventSnapshot.data ?? const <Event>[];
            final matches =
                allEvents
                    .where((event) => favoriteIds.contains(event.id))
                    .toList()
                  ..sort((a, b) => a.startTime.compareTo(b.startTime));
            if (matches.isEmpty) {
              return const EmptyView(
                'No favorites yet. Tap the heart on an event to save it here.',
                icon: Icons.favorite_border,
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final event = matches[index];
                return EventCard(
                  event: event,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventDetailsScreen(eventId: event.id),
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove from favorites',
                    onPressed: () => favorites.remove(user.id, event.id),
                    icon: Icon(
                      Icons.favorite,
                      color: Theme.of(context).colorScheme.primary,
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
