import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/event_feedback.dart';

/// Favorites (SRS 1.6.8) — one doc per user+event.
class FavoriteRepository {
  final _db = FirebaseFirestore.instance;

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
  final _db = FirebaseFirestore.instance;

  Future<void> submit(EventFeedback fb) => _db
      .collection(Col.feedback)
      .doc('${fb.userId}_${fb.eventId}')
      .set(fb.toMap());

  Stream<List<EventFeedback>> byEvent(String eventId) => _db
      .collection(Col.feedback)
      .where('eventId', isEqualTo: eventId)
      .snapshots()
      .map((s) => s.docs.map(EventFeedback.fromDoc).toList());

  Future<bool> hasSubmitted(String userId, String eventId) async =>
      (await _db.collection(Col.feedback).doc('${userId}_$eventId').get())
          .exists;
}

/// In-app notifications (SRS 1.6.9). Fan-out helpers write one doc per user.
class NotificationRepository {
  final _db = FirebaseFirestore.instance;

  Stream<List<AppNotification>> byUser(String userId) => _db
      .collection(Col.notifications)
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(AppNotification.fromDoc).toList());

  Future<void> send({
    required String userId,
    String? eventId,
    required String title,
    required String message,
  }) =>
      _db.collection(Col.notifications).add({
        'userId': userId,
        'eventId': eventId,
        'title': title,
        'message': message,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

  /// Notify every registered (non-cancelled) user of an event.
  Future<void> sendToEventRegistrants({
    required String eventId,
    required String title,
    required String message,
  }) async {
    final regs = await _db
        .collection(Col.registrations)
        .where('eventId', isEqualTo: eventId)
        .where('status', whereIn: ['registered', 'attended']).get();
    final batch = _db.batch();
    for (final r in regs.docs) {
      batch.set(_db.collection(Col.notifications).doc(), {
        'userId': r['userId'],
        'eventId': eventId,
        'title': title,
        'message': message,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> markRead(String notificationId) => _db
      .collection(Col.notifications)
      .doc(notificationId)
      .update({'isRead': true});
}

/// Admin user management (SRS 1.6.17).
class UserRepository {
  final _db = FirebaseFirestore.instance;

  Stream<List<AppUser>> all() => _db
      .collection(Col.users)
      .snapshots()
      .map((s) => s.docs.map(AppUser.fromDoc).toList());

  Future<void> setRole(String userId, String role) =>
      _db.collection(Col.users).doc(userId).update({'role': role});

  Future<void> setActive(String userId, bool active) =>
      _db.collection(Col.users).doc(userId).update({'active': active});
}
