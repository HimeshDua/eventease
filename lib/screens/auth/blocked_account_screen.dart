import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';

class BlockedAccountScreen extends StatelessWidget {
  const BlockedAccountScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block_outlined, size: 56),
                const SizedBox(height: 16),
                Text('Account unavailable', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text(
                  'Your account has been deactivated. Please contact an administrator for help.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: () => context.read<AuthService>().logout(),
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      );
}
