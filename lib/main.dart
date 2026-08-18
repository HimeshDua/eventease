import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'services/auth_service.dart';
import 'services/fcm_notification_service.dart';
import 'widgets/common.dart';

final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
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
        Provider(create: (_) => FcmNotificationService()),
      ],
      child: const EventEaseApp(),
    ),
  );
}

class EventEaseApp extends StatelessWidget {
  const EventEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventEase',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      scaffoldMessengerKey: rootMessengerKey,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

/// Routes to Login or the role-based shell depending on auth state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: context.watch<AuthService>().userStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            body: ErrorView(
              'We could not load your account. Please try again.',
            ),
          );
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingView());
        }
        final user = snap.data;
        if (user == null) {
          // Authenticated in Firebase Auth but no Firestore profile document exists.
          // This typically happens when the account was created in the Firebase
          // Console without a matching users/{uid} document, or if the profile
          // was deleted.
          if (context.read<AuthService>().isAuthenticated) {
            return Scaffold(
              body: ErrorView(
                'We could not find your account profile. Please contact support.',
                actionLabel: 'Logout',
                onAction: () => context.read<AuthService>().logout(),
              ),
            );
          }
          return const LoginScreen();
        }
        if (!user.active) return const BlockedAccountScreen();
        final fcm = context.read<FcmNotificationService>();
        fcm.initializeForUser(
          user.id,
          onMessage: (message) {
            final notification = message.notification;
            if (notification != null) {
              rootMessengerKey.currentState?.showSnackBar(
                SnackBar(
                  content: Text(
                    notification.body == null || notification.body!.isEmpty
                        ? notification.title ?? 'New EventEase notification'
                        : '${notification.title ?? 'EventEase'}: ${notification.body}',
                  ),
                ),
              );
            }
          },
          onOpened: (message) {},
        );
        return HomeShell(user: user);
      },
    );
  }
}
