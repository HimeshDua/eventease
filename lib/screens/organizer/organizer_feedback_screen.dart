import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event_feedback.dart';
import '../../repositories/misc_repositories.dart';
import '../../widgets/common.dart';

/// Feedback list and average rating for an owned event (SRS 1.6.13).
class OrganizerFeedbackScreen extends StatelessWidget {
  final String eventId;
  const OrganizerFeedbackScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final feedback = context.read<FeedbackRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: StreamBuilder<List<EventFeedback>>(
        stream: feedback.byEvent(eventId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const ErrorView('Could not load feedback.');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final items = snapshot.data ?? const <EventFeedback>[];
          if (items.isEmpty) {
            return const EmptyView(
              'No feedback yet.',
              icon: Icons.rate_review_outlined,
            );
          }
          final average =
              items.map((f) => f.rating).fold<int>(0, (a, b) => a + b) /
              items.length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Average rating: ${average.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${items.length} review${items.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (final item in items)
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            for (var i = 1; i <= 5; i++)
                              Icon(
                                i <= item.rating
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          ],
                        ),
                        if (item.comment.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(item.comment),
                        ],
                        if (item.submittedAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            formatEventDate(item.submittedAt!),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
