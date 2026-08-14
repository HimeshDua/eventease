import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/registration.dart';

/// Displays the QR pass for a registered event (SRS 1.6.10).
class QrPassScreen extends StatelessWidget {
  final String eventId;
  final Registration registration;

  const QrPassScreen({
    super.key,
    required this.eventId,
    required this.registration,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('My QR Pass')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'EventEase',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: registration.qrCode,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Event ID: $eventId',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Registration: ${registration.id}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              Text(
                'Show this QR code at the venue. The organizer will scan it to check you in.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
