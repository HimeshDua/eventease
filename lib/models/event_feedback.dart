import 'package:cloud_firestore/cloud_firestore.dart';

class EventFeedback {
  final String id;
  final String eventId;
  final String userId;
  final int rating; // 1-5
  final String comment;
  final DateTime? submittedAt;

  const EventFeedback({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.rating,
    this.comment = '',
    this.submittedAt,
  });

  factory EventFeedback.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EventFeedback(
      id: doc.id,
      eventId: d['eventId'] ?? '',
      userId: d['userId'] ?? '',
      rating: d['rating'] ?? 0,
      comment: d['comment'] ?? '',
      submittedAt: (d['submittedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'eventId': eventId,
        'userId': userId,
        'rating': rating,
        'comment': comment,
        'submittedAt': FieldValue.serverTimestamp(),
      };
}
