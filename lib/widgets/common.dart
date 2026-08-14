import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';

/// Shared UI helpers — use these everywhere for consistent loading/empty/error
/// states (SRS 1.6.20).
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyView(this.message, {super.key, this.icon = Icons.inbox_outlined});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
}

class ErrorView extends StatelessWidget {
  final String message;
  const ErrorView(this.message, {super.key});
  @override
  Widget build(BuildContext context) =>
      EmptyView(message, icon: Icons.error_outline);
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: error ? Colors.red.shade700 : null,
  ));
}

/// Confirmation dialog for destructive actions (SRS 1.6.20).
Future<bool> confirm(BuildContext context, String title, String body) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Confirm')),
      ],
    ),
  );
  return ok ?? false;
}

String formatEventDate(DateTime d) =>
    DateFormat('EEE, d MMM yyyy • h:mm a').format(d);

/// Standard event card used on Discover, Favorites, My Events (SRS 1.6.3).
class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final Widget? trailing;
  const EventCard(
      {super.key, required this.event, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: event.imageUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (c, u, e) => const SizedBox(height: 8),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(formatEventDate(event.startTime),
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(event.location,
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 6),
                        Wrap(spacing: 6, children: [
                          Chip(
                            label: Text(event.category),
                            visualDensity: VisualDensity.compact,
                          ),
                          Chip(
                            label: Text(event.isFull
                                ? 'Full'
                                : '${event.availableSeats} seats left'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ]),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
