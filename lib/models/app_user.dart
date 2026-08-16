import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // Roles.attendee / organizer / admin
  final String? profileImageUrl;
  final bool active;
  final bool organizerRequested;
  final bool remindersEnabled;
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImageUrl,
    this.active = true,
    this.organizerRequested = false,
    this.remindersEnabled = true,
    this.createdAt,
  });

  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final data = doc.data();
    if (data is! Map<String, dynamic>) {
      throw StateError('User ${doc.id} has an invalid Firestore document.');
    }

    DateTime? parseDate(Object? value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    String readString(String field, {String fallback = ''}) {
      final value = data[field];
      return value is String ? value : fallback;
    }

    bool readBool(String field, {required bool fallback}) {
      final value = data[field];
      return value is bool ? value : fallback;
    }

    final image = data['profileImageUrl'];
    return AppUser(
      id: doc.id,
      name: readString('name'),
      email: readString('email'),
      phone: readString('phone'),
      role: readString('role', fallback: 'attendee'),
      profileImageUrl: image is String && image.isNotEmpty ? image : null,
      active: readBool('active', fallback: true),
      organizerRequested: readBool('organizerRequested', fallback: false),
      remindersEnabled: readBool('remindersEnabled', fallback: true),
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'profileImageUrl': profileImageUrl,
        'active': active,
        'organizerRequested': organizerRequested,
        'remindersEnabled': remindersEnabled,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };
}
