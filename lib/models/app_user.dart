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
    final d = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      phone: d['phone'] ?? '',
      role: d['role'] ?? 'attendee',
      profileImageUrl: d['profileImageUrl'],
      active: d['active'] ?? true,
      organizerRequested: d['organizerRequested'] ?? false,
      remindersEnabled: d['remindersEnabled'] ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
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
