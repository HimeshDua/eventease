import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/event_feedback.dart';

/// Favorites (SRS 1.6.8) — one doc per user+event.
class FavoriteRepository {
  final FirebaseFirestore _db;

  FavoriteRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  String _docId(String userId, String eventId) => '${userId}_$eventId';

  Future<void> add(String userId, String eventId) =>
      _db.collection(Col.favorites).doc(_docId(userId, eventId)).set({
        'userId': userId,
        'eventId': eventId,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> remove(String userId, String eventId) =>
      _db.collection(Col.favorites).doc(_docId(userId, eventId)).delete();

  Stream<Set<String>> eventIds(String userId) => _db
      .collection(Col.favorites)
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((s) => s.docs.map((d) => d['eventId'] as String).toSet());
}

/// Feedback (SRS 1.6.13) — doc id user_event prevents duplicates by design.
class FeedbackRepository {
  final FirebaseFirestore _db;

  FeedbackRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  Future<void> submit(EventFeedback fb) => _db
      .collection(Col.feedback)
      .doc('${fb.userId}_${fb.eventId}')
      .set(fb.toMap());

  Stream<List<EventFeedback>> byEvent(String eventId) => _db
      .collection(Col.feedback)
      .where('eventId', isEqualTo: eventId)
      .snapshots()
      .map((s) => s.docs.map(EventFeedback.fromDoc).toList());

  Stream<List<EventFeedback>> all() => _db
      .collection(Col.feedback)
      .snapshots()
      .map((s) => s.docs.map(EventFeedback.fromDoc).toList());

  Future<bool> hasSubmitted(String userId, String eventId) async =>
      (await _db.collection(Col.feedback).doc('${userId}_$eventId').get())
          .exists;
}

/// Notification types (SRS 1.6.9). Kept in one place for callers.
class NotificationTypes {
  static const registration = 'registration';
  static const reminder = 'reminder';
  static const eventChanged = 'eventChanged';
  static const cancelled = 'cancelled';
  static const announcement = 'announcement';
  static const feedbackRequest = 'feedbackRequest';
  static const approval = 'approval';
  static const rejection = 'rejection';
  static const roleApproved = 'roleApproved';
}

/// In-app notifications (SRS 1.6.9). Fan-out helpers write one doc per user.
class NotificationRepository {
  final FirebaseFirestore _db;

  NotificationRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  Stream<List<AppNotification>> byUser(String userId) => _db
      .collection(Col.notifications)
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(AppNotification.fromDoc).toList());

  Stream<int> unreadCount(String userId) => _db
      .collection(Col.notifications)
      .where('userId', isEqualTo: userId)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.size);

  Future<void> send({
    required String userId,
    String? eventId,
    required String type,
    required String title,
    required String message,
  }) => _db.collection(Col.notifications).add({
    'userId': userId,
    'eventId': eventId,
    'type': type,
    'title': title,
    'message': message,
    'isRead': false,
    'createdAt': FieldValue.serverTimestamp(),
  });

  /// Creates a notification only if [docId] does not already exist.
  Future<void> sendOnce({
    required String docId,
    required String userId,
    String? eventId,
    required String type,
    required String title,
    required String message,
  }) async {
    final ref = _db.collection(Col.notifications).doc(docId);
    await _db.runTransaction((transaction) async {
      if ((await transaction.get(ref)).exists) return;
      transaction.set(ref, {
        'userId': userId,
        'eventId': eventId,
        'type': type,
        'title': title,
        'message': message,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Notify every registered (non-cancelled) user of an event.
  Future<void> sendToEventRegistrants({
    required String eventId,
    required String type,
    required String title,
    required String message,
  }) async {
    final regs = await _db
        .collection(Col.registrations)
        .where('eventId', isEqualTo: eventId)
        .where('status', whereIn: ['registered', 'attended'])
        .get();
    const maxBatchWrites = 450;
    for (var start = 0; start < regs.docs.length; start += maxBatchWrites) {
      final end = start + maxBatchWrites > regs.docs.length
          ? regs.docs.length
          : start + maxBatchWrites;
      final batch = _db.batch();
      for (final registration in regs.docs.sublist(start, end)) {
        batch.set(_db.collection(Col.notifications).doc(), {
          'userId': registration['userId'],
          'eventId': eventId,
          'type': type,
          'title': title,
          'message': message,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  Future<void> markRead(String notificationId) => _db
      .collection(Col.notifications)
      .doc(notificationId)
      .update({'isRead': true});
}

/// Admin user management (SRS 1.6.17).
class UserRepository {
  final FirebaseFirestore _db;

  UserRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  Stream<List<AppUser>> all() => _db
      .collection(Col.users)
      .snapshots()
      .map((s) => s.docs.map(AppUser.fromDoc).toList());

  Future<void> updateProfile(
    String userId, {
    required String name,
    required String phone,
    String? profileImageUrl,
  }) => _db.collection(Col.users).doc(userId).update({
    'name': name,
    'phone': phone,
    'profileImageUrl': profileImageUrl,
  });

  Future<void> requestOrganizerAccess(String userId) => _db
      .collection(Col.users)
      .doc(userId)
      .update({'organizerRequested': true});

  /// SRS 1.6.15 reminder preference; the client caches it in shared_preferences.
  Future<void> setRemindersEnabled(String userId, bool enabled) => _db
      .collection(Col.users)
      .doc(userId)
      .update({'remindersEnabled': enabled});

  Future<void> setRole(String userId, String role) =>
      _db.collection(Col.users).doc(userId).update({'role': role});

  Future<void> setActive(String userId, bool active) =>
      _db.collection(Col.users).doc(userId).update({'active': active});
}
