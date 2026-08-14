import 'package:flutter/material.dart';

import '../../models/registration.dart';
import '../../widgets/common.dart';
import 'qr_pass_screen.dart';

/// Shown right after a successful registration (SRS 1.6.6).
class RegistrationConfirmationScreen extends StatelessWidget {
  final String eventId;
  final Registration registration;

  const RegistrationConfirmationScreen({
    super.key,
    required this.eventId,
    required this.registration,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration confirmed')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'You are registered!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Your QR pass is ready. Show it at the venue for check-in.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QrPassScreen(
                      eventId: eventId,
                      registration: registration,
                    ),
                  ),
                ),
                icon: const Icon(Icons.qr_code_2),
                label: const Text('View QR pass'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
