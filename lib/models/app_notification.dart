import 'package:cloud_firestore/cloud_firestore.dart';

/// In-app notification stored in Firestore (no FCM needed for minimum scope).
class AppNotification {
  final String id;
  final String userId;
  final String? eventId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    this.eventId,
    this.type = '',
    required this.title,
    required this.message,
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotification.fromDoc(DocumentSnapshot doc) {
    final raw = doc.data();
    final d = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    final created = d['createdAt'];
    DateTime? createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is DateTime) {
      createdAt = created;
    }
    return AppNotification(
      id: doc.id,
      userId: d['userId']?.toString() ?? '',
      eventId: d['eventId']?.toString(),
      type: d['type']?.toString() ?? '',
      title: d['title']?.toString() ?? 'Notification',
      message: d['message']?.toString() ?? '',
      isRead: d['isRead'] == true,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'eventId': eventId,
        'type': type,
        'title': title,
        'message': message,
        'isRead': isRead,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
