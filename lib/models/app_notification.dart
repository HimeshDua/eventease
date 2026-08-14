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
    final d = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: d['userId'] ?? '',
      eventId: d['eventId'],
      type: d['type'] ?? '',
      title: d['title'] ?? '',
      message: d['message'] ?? '',
      isRead: d['isRead'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
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
