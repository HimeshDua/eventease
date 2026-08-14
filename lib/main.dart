import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'firebase_options.dart';
import 'models/app_user.dart';
import 'repositories/event_repository.dart';
import 'repositories/gallery_repository.dart';
import 'repositories/contact_repository.dart';
import 'repositories/misc_repositories.dart';
import 'repositories/registration_repository.dart';
import 'services/map_launcher_service.dart';
import 'services/storage_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/blocked_account_screen.dart';
import 'screens/shell.dart';
import 'screens/shared/splash_screen.dart';
import 'services/auth_service.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EventEaseApp());
}

class EventEaseApp extends StatefulWidget {
  const EventEaseApp({super.key});

  @override
  State<EventEaseApp> createState() => _EventEaseAppState();
}

class _EventEaseAppState extends State<EventEaseApp> {
  late Future<FirebaseApp> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeFirebase();
  }

  Future<FirebaseApp> _initializeFirebase() =>
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  void _retryInitialization() {
    setState(() => _initialization = _initializeFirebase());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventEase',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<FirebaseApp>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SplashScreen();
          }
          if (snapshot.hasError) {
            return Scaffold(
              body: ErrorView(
                'EventEase could not connect to its services. Please check your connection and try again.',
                actionLabel: 'Try again',
                onAction: _retryInitialization,
              ),
            );
          }
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthService()),
              Provider(create: (_) => EventRepository()),
              Provider(create: (_) => RegistrationRepository()),
              Provider(create: (_) => FavoriteRepository()),
              Provider(create: (_) => FeedbackRepository()),
              Provider(create: (_) => NotificationRepository()),
              Provider(create: (_) => UserRepository()),
              Provider(create: (_) => StorageService()),
              Provider(create: (_) => GalleryRepository()),
              Provider(create: (_) => ContactRepository()),
              Provider(create: (_) => MapLauncherService()),
            ],
            child: const AuthGate(),
          );
        },
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
            body: ErrorView('We could not load your account. Please try again.'),
          );
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingView());
        }
        final user = snap.data;
        if (user == null) return const LoginScreen();
        if (!user.active) return const BlockedAccountScreen();
        return HomeShell(user: user);
      },
    );
  }
}
