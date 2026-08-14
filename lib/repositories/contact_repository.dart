import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';

/// Submits contact messages for administrator review.
class ContactRepository {
  final FirebaseFirestore _db;

  ContactRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Future<void> submit({
    required String userId,
    required String name,
    required String email,
    required String subject,
    required String message,
  }) =>
      _db.collection(Col.contactMessages).add({
        'userId': userId,
        'name': name,
        'email': email,
        'subject': subject,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
      });
}
