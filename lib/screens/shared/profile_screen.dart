import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/validators/auth_validators.dart';
import '../../models/app_user.dart';
import '../../repositories/misc_repositories.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common.dart';
import '../auth/auth_widgets.dart';
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
    final messenger = ScaffoldMessenger.of(context);
    final storage = context.read<StorageService>();
    final users = context.read<UserRepository>();
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (file == null) return;
    try {
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
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile picture updated.')),
      );
    // Common errors: storage permission denied, upload failure.
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(friendlyError(error)),
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
    final colorScheme = Theme.of(context).colorScheme;
    try {
      await context.read<UserRepository>().updateProfile(
        user.id,
        name: name,
        phone: phone,
      );
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Profile updated.')));
    // Common errors: Firestore permission denied or network error.
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

  Future<void> _changePassword() async {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.read<AuthService>();
    final formKey = GlobalKey<FormState>();
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final currentFocus = FocusNode();
    final newFocus = FocusNode();
    bool busy = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Change password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorText != null) ...[
                  Text(
                    errorText!,
                    style: TextStyle(color: colorScheme.error),
                  ),
                  const SizedBox(height: 12),
                ],
                PasswordFormField(
                  controller: currentCtrl,
                  label: 'Current password',
                  enabled: !busy,
                  focusNode: currentFocus,
                  autofillHints: const [AutofillHints.password],
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Current password is required'
                      : null,
                ),
                const SizedBox(height: 16),
                PasswordFormField(
                  controller: newCtrl,
                  label: 'New password',
                  enabled: !busy,
                  focusNode: newFocus,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: AuthValidators.password,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        busy = true;
                        errorText = null;
                        currentFocus.unfocus();
                        newFocus.unfocus();
                      });
                      try {
                        await auth.changePassword(
                          currentPassword: currentCtrl.text,
                          newPassword: newCtrl.text,
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Password changed.')),
                        );
                      // Common errors: wrong current password, requires-recent-login, network failure.
                      } catch (error) {
                        setDialogState(() {
                          busy = false;
                          errorText = friendlyError(error);
                        });
                      }
                    },
              child: busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Change'),
            ),
          ],
        ),
      ),
    );
    currentCtrl.dispose();
    newCtrl.dispose();
    currentFocus.dispose();
    newFocus.dispose();
  }

  Future<void> _toggleReminders(
    UserRepository users,
    AppUser user,
    bool enabled,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    try {
      await users.setRemindersEnabled(user.id, enabled);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remindersEnabled', enabled);
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text(
              'We could not save your preference. Please try again.',
            ),
            backgroundColor: colorScheme.errorContainer,
          ),
        );
      }
    }
  }

  Future<void> _requestOrganizer(UserRepository users, AppUser user) async {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    try {
      await users.requestOrganizerAccess(user.id);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Organizer access requested. An administrator will review it.',
          ),
        ),
      );
    // Common errors: Firestore write denial.
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(friendlyError(error)),
          backgroundColor: colorScheme.errorContainer,
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
