import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/app_user.dart';
import '../../repositories/misc_repositories.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';
import 'user_details_screen.dart';

/// Admin user management: search, activate, deactivate, roles (SRS 1.6.17).
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final users = context.read<UserRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          return SizedBox(
            width: width,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: SearchBar(
                      controller: _search,
                      hintText: 'Search by name or email',
                      leading: const Icon(Icons.search),
                      trailing: [
                        if (_query.isNotEmpty)
                          IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                      ],
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<AppUser>>(
                    stream: users.all(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return ErrorView(
                          'Could not load users: ${friendlyError(snapshot.error!)}',
                          actionLabel: 'Retry',
                          onAction: () => setState(() {}),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LoadingView();
                      }
                      var items = snapshot.data ?? const <AppUser>[];
                      final normalized = _query.trim().toLowerCase();
                      if (normalized.isNotEmpty) {
                        items = items
                            .where(
                              (u) =>
                                  u.name.toLowerCase().contains(normalized) ||
                                  u.email.toLowerCase().contains(normalized) ||
                                  u.phone.toLowerCase().contains(normalized),
                            )
                            .toList();
                      }
                      items = [...items]
                        ..sort(
                          (a, b) => a.name
                              .toLowerCase()
                              .compareTo(b.name.toLowerCase()),
                        );
                      if (items.isEmpty) {
                        return const EmptyView('No users match your search.');
                      }
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width,
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final user = items[index];
                          return SizedBox(
                            width: double.infinity,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      UserDetailsScreen(userId: user.id),
                                ),
                              ),
                              child: _UserCard(user: user),
                            ),
                          );
                        },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

}

class _UserCard extends StatefulWidget {
  final AppUser user;
  const _UserCard({required this.user});

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  bool _busy = false;

  Future<void> _setRole(String role) async {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final users = context.read<UserRepository>();
    final notifications = context.read<NotificationRepository>();
    try {
      await users.setRole(widget.user.id, role);
      if (role == Roles.organizer) {
        await notifications.send(
          userId: widget.user.id,
          type: NotificationTypes.roleApproved,
          title: 'Organizer access approved',
          message: 'You can now create and manage events.',
        );
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Role updated to ${_roleLabel(role)}.')),
      );
    // setRole: Firestore write denial (only admin can change roles)
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

  Future<void> _toggleActive() async {
    final user = widget.user;
    final currentAdmin = context.read<AuthService>().currentUser;
    final users = context.read<UserRepository>();
    if (user.id == currentAdmin?.id && user.active) {
      showSnack(
        context,
        'You cannot deactivate your own account.',
        error: true,
      );
      return;
    }
    final newActive = !user.active;
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await confirm(
      context,
      newActive ? 'Activate account?' : 'Deactivate account?',
      newActive
          ? '${user.name} will be able to sign in again.'
          : '${user.name} will not be able to sign in until reactivated.',
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      await users.setActive(user.id, newActive);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            newActive ? 'Account activated.' : 'Account deactivated.',
          ),
        ),
      );
    // toggleActive: Firestore write denial or cannot deactivate self
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

  String _roleLabel(String role) => switch (role) {
    Roles.organizer => 'Organizer',
    Roles.admin => 'Administrator',
    _ => 'Attendee',
  };

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: user.active ? null : colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text(_initials(user.name))),
              title: Text(
                user.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.email,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!user.active)
                    Text(
                      'Deactivated',
                      style: TextStyle(color: colorScheme.error),
                    ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                tooltip: 'Change role',
                onSelected: _setRole,
                itemBuilder: (context) => [
                  for (final role in const [
                    Roles.attendee,
                    Roles.organizer,
                    Roles.admin,
                  ])
                    PopupMenuItem(
                      value: role,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (user.role == role)
                            Icon(
                              Icons.check,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                          if (user.role == role) const SizedBox(width: 8),
                          Text(_roleLabel(role)),
                        ],
                      ),
                    ),
                ],
                child: Chip(
                  label: Text(_roleLabel(user.role)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            if (user.organizerRequested && user.role == Roles.attendee)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const Icon(Icons.badge_outlined, size: 18),
                    const Text('Requested organizer access'),
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: _busy ? null : () => _setRole(Roles.organizer),
                      child: const Text('Approve'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _busy ? null : _toggleActive,
                  icon: Icon(
                    user.active
                        ? Icons.block_outlined
                        : Icons.check_circle_outline,
                  ),
                  label: Text(user.active ? 'Deactivate' : 'Activate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
