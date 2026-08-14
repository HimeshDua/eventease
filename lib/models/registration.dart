import 'package:cloud_firestore/cloud_firestore.dart';

class Registration {
  final String id;
  final String eventId;
  final String userId;
  final String status; // RegistrationStatus.*
  final String qrCode; // unique string encoded in the QR pass
  final DateTime? registeredAt;
  final DateTime? checkedInAt;

  const Registration({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    required this.qrCode,
    this.registeredAt,
    this.checkedInAt,
  });

  factory Registration.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Registration(
      id: doc.id,
      eventId: d['eventId'] ?? '',
      userId: d['userId'] ?? '',
      status: d['status'] ?? 'registered',
      qrCode: d['qrCode'] ?? '',
      registeredAt: (d['registeredAt'] as Timestamp?)?.toDate(),
      checkedInAt: (d['checkedInAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'eventId': eventId,
        'userId': userId,
        'status': status,
        'qrCode': qrCode,
        'registeredAt': registeredAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(registeredAt!),
        'checkedInAt':
            checkedInAt == null ? null : Timestamp.fromDate(checkedInAt!),
      };
}
