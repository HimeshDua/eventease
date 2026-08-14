import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String organizerId;
  final String title;
  final String description;
  final String category;
  final String location;
  final double latitude;
  final double longitude;
  final String rules;
  final String contactInfo;
  final DateTime startTime;
  final DateTime endTime;
  final int maxParticipants;
  final int registeredCount; // maintained by registration transaction
  final String status; // EventStatus.*
  final String? imageUrl;
  final bool cancellationRequested;
  final String? cancellationReason;
  final bool changeReviewPending;
  final DateTime? createdAt;

  const Event({
    required this.id,
    required this.organizerId,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.latitude = 0,
    this.longitude = 0,
    required this.rules,
    required this.contactInfo,
    required this.startTime,
    required this.endTime,
    required this.maxParticipants,
    this.registeredCount = 0,
    required this.status,
    this.imageUrl,
    this.cancellationRequested = false,
    this.cancellationReason,
    this.changeReviewPending = false,
    this.createdAt,
  });

  int get availableSeats => maxParticipants - registeredCount;
  bool get isFull => availableSeats <= 0;
  bool get hasStarted => DateTime.now().isAfter(startTime);
  bool get hasEnded => DateTime.now().isAfter(endTime);
  bool get isCompleted => status == 'completed' || hasEnded;

  factory Event.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      organizerId: d['organizerId'] ?? '',
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      category: d['category'] ?? '',
      location: d['location'] ?? '',
      latitude: (d['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (d['longitude'] as num?)?.toDouble() ?? 0,
      rules: d['rules'] ?? '',
      contactInfo: d['contactInfo'] ?? '',
      startTime: (d['startTime'] as Timestamp).toDate(),
      endTime: (d['endTime'] as Timestamp).toDate(),
      maxParticipants: d['maxParticipants'] ?? 0,
      registeredCount: d['registeredCount'] ?? 0,
      status: d['status'] ?? 'pending',
      imageUrl: d['imageUrl'],
      cancellationRequested: d['cancellationRequested'] ?? false,
      cancellationReason: d['cancellationReason'],
      changeReviewPending: d['changeReviewPending'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'organizerId': organizerId,
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'rules': rules,
        'contactInfo': contactInfo,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'maxParticipants': maxParticipants,
        'registeredCount': registeredCount,
        'status': status,
        'imageUrl': imageUrl,
        'cancellationRequested': cancellationRequested,
        'cancellationReason': cancellationReason,
        'changeReviewPending': changeReviewPending,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };
}
