import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';

/// Initializes FCM, stores device tokens on the signed-in profile, and handles
/// notification lifecycle events. Remote delivery is performed by the
/// Firebase Cloud Function in /functions when a Firestore notification is created.
class FcmNotificationService {
  FcmNotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _db;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  String? _initializedUserId;

  static Map<String, dynamic> payloadFor({
    required String title,
    required String body,
    String? eventId,
    required String type,
  }) => {
        'title': title,
        'body': body,
        'eventId': eventId,
        'type': type,
      };

  Future<void> initializeForUser(
    String userId, {
    void Function(RemoteMessage message)? onMessage,
    void Function(RemoteMessage message)? onOpened,
  }) async {
    if (_initializedUserId == userId) return;
    await dispose();
    _initializedUserId = userId;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _messaging.setAutoInitEnabled(true);
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _saveToken(userId, token);
    }

    _tokenSubscription = _messaging.onTokenRefresh.listen((token) async {
      if (_initializedUserId == userId && token.isNotEmpty) {
        await _saveToken(userId, token);
      }
    });

    if (onMessage != null) {
      _messageSubscription = FirebaseMessaging.onMessage.listen(onMessage);
    }
    if (onOpened != null) {
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(onOpened);
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) onOpened(initialMessage);
    }

    // Foreground notification display is platform-specific. The Firestore
    // notification is already persisted and the app's notification screen
    // listens to it live, so foreground messages remain visible in-app.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> _saveToken(String userId, String token) => _db
      .collection(Col.users)
      .doc(userId)
      .update({'fcmTokens': FieldValue.arrayUnion([token])});

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _openedSubscription?.cancel();
    _tokenSubscription = null;
    _messageSubscription = null;
    _openedSubscription = null;
    _initializedUserId = null;
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Notification payloads are rendered by the operating system when the app
  // is in the background. This handler exists for future data-payload work.
  debugPrint('Background FCM message: ${message.messageId}');
}
