import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/contact_repository.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

/// Contact form and About information (SRS 1.6.19).
class ContactAboutScreen extends StatefulWidget {
  const ContactAboutScreen({super.key});

  @override
  State<ContactAboutScreen> createState() => _ContactAboutScreenState();
}

class _ContactAboutScreenState extends State<ContactAboutScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    final subject = _subject.text.trim();
    final message = _message.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      showSnack(
        context,
        'Please enter both a subject and a message.',
        error: true,
      );
      return;
    }
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await context.read<ContactRepository>().submit(
        userId: user.id,
        name: user.name,
        email: user.email,
        subject: subject,
        message: message,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Message sent. Thank you!')),
      );
      navigator.pop();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('$error'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
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
      return const ErrorView('Please sign in to contact support.');
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Contact & About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About EventEase',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'EventEase is a cross-platform event discovery and '
                    'management application. Attendees can discover events, '
                    'register, receive QR passes, and share feedback. '
                    'Organizers create and manage events while administrators '
                    'approve content and manage users.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Contributors: Himesh Dua (Team Lead) and the EventEase '
                    'development team.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Send us a message',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: user.name,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: user.email,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _subject,
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _message,
            decoration: const InputDecoration(
              labelText: 'Message',
              alignLabelWithHint: true,
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send message'),
          ),
        ],
      ),
    );
  }
}
