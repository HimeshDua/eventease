import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/app_user.dart';
import '../../models/registration.dart';
import '../../repositories/misc_repositories.dart';
import '../../repositories/registration_repository.dart';
import '../../widgets/common.dart';

/// Participant list for an owned event (SRS 1.6.12).
class ParticipantsScreen extends StatelessWidget {
  final String eventId;
  const ParticipantsScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final registrations = context.read<RegistrationRepository>();
    final users = context.read<UserRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Participants')),
      body: StreamBuilder<List<Registration>>(
        stream: registrations.byEvent(eventId),
        builder: (context, regSnapshot) {
          if (regSnapshot.hasError) {
            return const ErrorView('Could not load participants.');
          }
          if (regSnapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final regs = regSnapshot.data ?? const <Registration>[];
          if (regs.isEmpty) {
            return const EmptyView(
              'No registrations yet.',
              icon: Icons.group_outlined,
            );
          }
          return StreamBuilder<List<AppUser>>(
            stream: users.all(),
            builder: (context, userSnapshot) {
              final userMap = <String, AppUser>{
                for (final user in userSnapshot.data ?? const <AppUser>[])
                  user.id: user,
              };
              final registered = regs.where(
                (r) => r.status == RegistrationStatus.registered,
              );
              final attended = regs.where(
                (r) => r.status == RegistrationStatus.attended,
              );
              final cancelled = regs.where(
                (r) => r.status == RegistrationStatus.cancelled,
              );

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text('${registered.length} registered')),
                      Chip(label: Text('${attended.length} attended')),
                      Chip(label: Text('${cancelled.length} cancelled')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final reg in regs)
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            _initials(userMap[reg.userId]?.name ?? '?'),
                          ),
                        ),
                        title: Text(userMap[reg.userId]?.name ?? 'User'),
                        subtitle: Text(
                          userMap[reg.userId]?.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: _RegistrationStatusChip(status: reg.status),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _RegistrationStatusChip extends StatelessWidget {
  final String status;
  const _RegistrationStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      RegistrationStatus.attended => ('Attended', colorScheme.primary),
      RegistrationStatus.cancelled => ('Cancelled', colorScheme.error),
      _ => ('Registered', colorScheme.secondary),
    };
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: color),
      side: BorderSide(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}
