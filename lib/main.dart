import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'firebase_options.dart';
import 'models/app_user.dart';
import 'repositories/event_repository.dart';
import 'repositories/misc_repositories.dart';
import 'repositories/registration_repository.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shell.dart';
import 'services/auth_service.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const EventEaseApp());
}

class EventEaseApp extends StatelessWidget {
  const EventEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => EventRepository()),
        Provider(create: (_) => RegistrationRepository()),
        Provider(create: (_) => FavoriteRepository()),
        Provider(create: (_) => FeedbackRepository()),
        Provider(create: (_) => NotificationRepository()),
        Provider(create: (_) => UserRepository()),
      ],
      child: MaterialApp(
        title: 'EventEase',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: const AuthGate(),
      ),
    );
  }
}

/// Routes to Login or the role-based shell depending on auth state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: context.read<AuthService>().userStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            body: Center(child: Text('An error occurred: ${snap.error}')),
          );
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingView());
        }
        final user = snap.data;
        if (user == null) return const LoginScreen();
        if (!user.active) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Your account has been deactivated.'),
                  TextButton(
                    onPressed: () => context.read<AuthService>().logout(),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          );
        }
        return HomeShell(user: user);
      },
    );
  }
}
