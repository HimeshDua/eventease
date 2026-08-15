import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/errors.dart' as errors;
import '../models/app_user.dart';

/// Handles Firebase Auth + the matching Firestore user profile.
/// Exposed app-wide via Provider; listen to [userStream] for auth state.
class AuthService extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  /// Emits the AppUser profile (with role) whenever auth state changes.
  Stream<AppUser?> get userStream =>
      _auth.authStateChanges().asyncExpand((fbUser) {
        if (fbUser == null) {
          _currentUser = null;
          return Stream<AppUser?>.value(null);
        }
        return _db.collection(Col.users).doc(fbUser.uid).snapshots().map((doc) {
          _currentUser = doc.exists ? AppUser.fromDoc(doc) : null;
          return _currentUser;
        });
      });

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    bool wantsOrganizer = false,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Default role is attendee. Organizer requests start as attendee and
    // are upgraded by an admin (SRS 1.6.1).
    final user = AppUser(
      id: cred.user!.uid,
      name: name,
      email: email,
      phone: phone,
      role: Roles.attendee,
      organizerRequested: wantsOrganizer,
    );
    await _db.collection(Col.users).doc(user.id).set({
      ...user.toMap(),
      'organizerRequested': wantsOrganizer,
    });
    _currentUser = user;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() => _auth.signOut();

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in again to change your password.');
    }
    await user.updatePassword(newPassword);
  }

  /// Turns FirebaseAuth exceptions into user-friendly messages (SRS 1.6.1).
  ///
  /// Delegates to the centralized [friendlyError] handler in
  /// `lib/core/errors.dart` so the error-mapping logic lives in one place.
  // Delegates to the centralized error handler in lib/core/errors.dart.
  static String friendlyError(Object e) => errors.friendlyError(e);
}
