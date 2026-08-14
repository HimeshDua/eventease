import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../models/app_user.dart';
import '../../repositories/misc_repositories.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common.dart';
import 'contact_about_screen.dart';

/// Profile, avatar, password, reminder preference, organizer request (SRS 1.6.15).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _uploadAvatar(AppUser user) async {
    final picker = ImagePicker();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (file == null) return;
      final storage = context.read<StorageService>();
      final users = context.read<UserRepository>();
      final url = await storage.uploadImage(
        file,
        'profiles/${user.id}/avatar.jpg',
      );
      await users.updateProfile(
        user.id,
        name: _name.text.trim().isEmpty ? user.name : _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? user.phone : _phone.text.trim(),
        profileImageUrl: url,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile picture updated.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('$error'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
    }
  }

  Future<void> _saveProfile(AppUser user) async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty) {
      showSnack(context, 'Name is required.', error: true);
      return;
    }
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<UserRepository>().updateProfile(
        user.id,
        name: name,
        phone: phone,
      );
      messenger.showSnackBar(const SnackBar(content: Text('Profile updated.')));
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

  Future<void> _changePassword() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Change'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      controller.dispose();
      return;
    }
    final newPassword = controller.text;
    controller.dispose();
    if (newPassword.length < 6) {
      showSnack(
        context,
        'Password must be at least 6 characters.',
        error: true,
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AuthService>().changePassword(newPassword);
      messenger.showSnackBar(
        const SnackBar(content: Text('Password changed.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(AuthService.friendlyError(error)),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
    }
  }

  Future<void> _toggleReminders(
    UserRepository users,
    AppUser user,
    bool enabled,
  ) async {
    try {
      await users.setRemindersEnabled(user.id, enabled);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remindersEnabled', enabled);
    } catch (_) {
      if (mounted) {
        showSnack(
          context,
          'We could not save your preference. Please try again.',
          error: true,
        );
      }
    }
  }

  Future<void> _requestOrganizer(UserRepository users, AppUser user) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await users.requestOrganizerAccess(user.id);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Organizer access requested. An administrator will review it.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('$error'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    if (user == null) {
      return const ErrorView('Please sign in to view your profile.');
    }
    if (_name.text.isEmpty && !_initialized) {
      _name.text = user.name;
      _phone.text = user.phone;
      _initialized = true;
    }
    final users = context.read<UserRepository>();
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: colorScheme.surfaceContainerHighest,
                foregroundImage: user.profileImageUrl == null
                    ? null
                    : CachedNetworkImageProvider(user.profileImageUrl!),
                child: user.profileImageUrl == null
                    ? Text(
                        _initials(user.name),
                        style: Theme.of(context).textTheme.headlineMedium,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: IconButton.filledTonal(
                  tooltip: 'Change profile picture',
                  onPressed: () => _uploadAvatar(user),
                  icon: const Icon(Icons.camera_alt_outlined),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _roleLabel(user.role),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: colorScheme.primary),
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phone,
          decoration: const InputDecoration(labelText: 'Phone'),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: user.email,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Email',
            helperText: 'Email cannot be changed.',
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy ? null : () => _saveProfile(user),
          child: _busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save changes'),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _changePassword,
          icon: const Icon(Icons.lock_outline),
          label: const Text('Change password'),
        ),
        const Divider(height: 32),
        SwitchListTile(
          title: const Text('Event reminders'),
          subtitle: const Text('Get reminders within 24 hours of your events'),
          value: user.remindersEnabled,
          onChanged: (value) => _toggleReminders(users, user, value),
        ),
        const Divider(height: 8),
        if (user.role == Roles.attendee)
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Request organizer access'),
            subtitle: Text(
              user.organizerRequested
                  ? 'Request pending administrator approval.'
                  : 'Create and manage your own events.',
            ),
            trailing: user.organizerRequested
                ? const Chip(label: Text('Pending'))
                : const Icon(Icons.chevron_right),
            enabled: !user.organizerRequested,
            onTap: () => _requestOrganizer(users, user),
          ),
        ListTile(
          leading: const Icon(Icons.contact_support_outlined),
          title: const Text('Contact & About'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ContactAboutScreen()),
          ),
        ),
      ],
    );
  }

  bool _initialized = false;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _roleLabel(String role) => switch (role) {
    Roles.organizer => 'Organizer',
    Roles.admin => 'Administrator',
    _ => 'Attendee',
  };
}
