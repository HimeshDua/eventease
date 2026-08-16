import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/app_user.dart';
import '../../models/event.dart';
import '../../models/registration.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/misc_repositories.dart';
import '../../repositories/registration_repository.dart';
import '../../widgets/common.dart';

class UserDetailsScreen extends StatelessWidget {
  final String userId;

  const UserDetailsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final users = context.read<UserRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('User details')),
      body: StreamBuilder<AppUser>(
        stream: users.watch(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(
              'Could not load user: ${friendlyError(snapshot.error!)}',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final user = snapshot.data;
          if (user == null) return const EmptyView('User not found.');
          return _UserDetailsBody(user: user);
        },
      ),
    );
  }
}

class _UserDetailsBody extends StatelessWidget {
  final AppUser user;
  const _UserDetailsBody({required this.user});

  @override
  Widget build(BuildContext context) {
    final events = context.read<EventRepository>();
    final registrations = context.read<RegistrationRepository>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: user.profileImageUrl == null
              ? CircleAvatar(
                  radius: 42,
                  child: Text(
                    user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 28),
                  ),
                )
              : CircleAvatar(
                  radius: 42,
                  backgroundImage: CachedNetworkImageProvider(
                    user.profileImageUrl!,
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            user.name,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        ListTile(leading: const Icon(Icons.email_outlined), title: Text(user.email)),
        ListTile(leading: const Icon(Icons.phone_outlined), title: Text(user.phone.isEmpty ? 'Not provided' : user.phone)),
        ListTile(leading: const Icon(Icons.badge_outlined), title: Text(_roleLabel(user.role))),
        ListTile(leading: const Icon(Icons.verified_user_outlined), title: Text(user.active ? 'Active' : 'Inactive')),
        ListTile(leading: const Icon(Icons.person_search_outlined), title: Text(user.organizerRequested ? 'Organizer request pending' : 'No organizer request')),
        ListTile(leading: const Icon(Icons.calendar_today_outlined), title: Text(user.createdAt == null ? 'Creation date unavailable' : formatEventDate(user.createdAt!))),
        const Divider(),
        if (user.role == Roles.organizer)
          StreamBuilder<List<Event>>(
            stream: events.byOrganizer(user.id),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text('Events: ${friendlyError(snapshot.error!)}');
              if (!snapshot.hasData) return const LinearProgressIndicator();
              return ListTile(
                leading: const Icon(Icons.event_outlined),
                title: const Text('Events created'),
                trailing: Text('${snapshot.data!.length}'),
              );
            },
          ),
        StreamBuilder<List<Registration>>(
          stream: registrations.byUser(user.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text('Registrations: ${friendlyError(snapshot.error!)}');
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final attendance = snapshot.data!.where((r) => r.status == RegistrationStatus.attended).length;
            return Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.assignment_turned_in_outlined),
                  title: const Text('Registrations'),
                  trailing: Text('${snapshot.data!.length}'),
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('Attendance'),
                  trailing: Text('$attendance'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _roleLabel(String role) => switch (role) {
    Roles.organizer => 'Organizer',
    Roles.admin => 'Administrator',
    _ => 'Attendee',
  };
}
