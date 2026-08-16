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
      .snapshots()
      .map((s) {
        final items = s.docs.map(AppNotification.fromDoc).toList();
        items.sort((a, b) {
          final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
        return items;
      });

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
      .map(_decodeUsers);

  /// Admin: only users who are currently waiting for organizer approval.
  Stream<List<AppUser>> organizerRequests() => _db
      .collection(Col.users)
      .where('organizerRequested', isEqualTo: true)
      .snapshots()
      .map(_decodeUsers);

  /// Admin/user-details stream for one profile. This avoids downloading the
  /// entire users collection just to inspect a single account.
  Stream<AppUser> watch(String userId) => _db
      .collection(Col.users)
      .doc(userId)
      .snapshots()
      .map(AppUser.fromDoc);

  List<AppUser> _decodeUsers(QuerySnapshot<Map<String, dynamic>> snapshot) {
    try {
      return snapshot.docs.map(AppUser.fromDoc).toList();
    } catch (error) {
      throw StateError('Could not read a user profile: $error');
    }
  }

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
      _db.collection(Col.users).doc(userId).update({
        'role': role,
        if (role != Roles.attendee) 'organizerRequested': false,
      });

  Future<void> approveOrganizerRequest(String userId) =>
      _db.collection(Col.users).doc(userId).update({
        'role': Roles.organizer,
        'organizerRequested': false,
      });

  Future<void> rejectOrganizerRequest(String userId) =>
      _db.collection(Col.users).doc(userId).update({
        'organizerRequested': false,
      });

  Future<void> setActive(String userId, bool active) =>
      _db.collection(Col.users).doc(userId).update({'active': active});
}
