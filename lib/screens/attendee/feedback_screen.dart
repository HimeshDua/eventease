import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/event.dart';
import '../../models/event_feedback.dart';
import '../../models/registration.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/misc_repositories.dart';
import '../../repositories/registration_repository.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

/// Submit one 1-5 rating for an attended completed event (SRS 1.6.13).
class FeedbackScreen extends StatefulWidget {
  final String eventId;
  const FeedbackScreen({super.key, required this.eventId});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _comment = TextEditingController();
  int _rating = 0;
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    if (_rating < 1) {
      showSnack(
        context,
        'Please choose a rating from 1 to 5 stars.',
        error: true,
      );
      return;
    }
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final feedback = EventFeedback(
      id: '${user.id}_${widget.eventId}',
      eventId: widget.eventId,
      userId: user.id,
      rating: _rating,
      comment: _comment.text.trim(),
    );
    try {
      await context.read<FeedbackRepository>().submit(feedback);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!')),
      );
      navigator.pop();
    // feedback submission failed (not attended, duplicate, network error)
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
    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      return const ErrorView('Please sign in to submit feedback.');
    }
    final events = context.read<EventRepository>();
    final registrations = context.read<RegistrationRepository>();
    final feedbackRepo = context.read<FeedbackRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: StreamBuilder<Event>(
        stream: events.watch(widget.eventId),
        builder: (context, eventSnapshot) {
          if (eventSnapshot.hasError) {
            return const ErrorView('Could not load event.');
          }
          if (eventSnapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final event = eventSnapshot.data!;
          if (!event.isCompleted) {
            return const EmptyView(
              'Feedback is available only after the event ends.',
              icon: Icons.hourglass_empty,
            );
          }
          return StreamBuilder<List<Registration>>(
            stream: registrations.byUser(user.id),
            builder: (context, regSnapshot) {
              final regs = regSnapshot.data ?? const <Registration>[];
              final attended = regs.any(
                (r) =>
                    r.eventId == widget.eventId &&
                    r.status == RegistrationStatus.attended,
              );
              if (!attended) {
                return const EmptyView(
                  'Feedback is available only to attendees.',
                  icon: Icons.verified_user_outlined,
                );
              }
              return FutureBuilder<bool>(
                future: feedbackRepo.hasSubmitted(user.id, widget.eventId),
                builder: (context, submittedSnapshot) {
                  if (submittedSnapshot.connectionState !=
                      ConnectionState.done) {
                    return const LoadingView();
                  }
                  if (submittedSnapshot.data ?? false) {
                    return const EmptyView(
                      'You already submitted feedback for this event.',
                      icon: Icons.check_circle_outline,
                    );
                  }
                  return _FeedbackForm(
                    rating: _rating,
                    comment: _comment,
                    busy: _busy,
                    onRatingChanged: (value) => setState(() => _rating = value),
                    onSubmit: _submit,
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

class _FeedbackForm extends StatelessWidget {
  final int rating;
  final TextEditingController comment;
  final bool busy;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  const _FeedbackForm({
    required this.rating,
    required this.comment,
    required this.busy,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate this event',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: '$i star${i == 1 ? '' : 's'}',
                  onPressed: () => onRatingChanged(i),
                  iconSize: 36,
                  icon: Icon(
                    i <= rating ? Icons.star : Icons.star_border,
                    color: i <= rating
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: comment,
            decoration: const InputDecoration(
              labelText: 'Comment (optional)',
              alignLabelWithHint: true,
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : onSubmit,
            child: busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit feedback'),
          ),
        ],
      ),
    );
  }
}
