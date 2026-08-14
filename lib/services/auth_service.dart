import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
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
    if (user == null)
      throw Exception('Please sign in again to change your password.');
    await user.updatePassword(newPassword);
  }

  /// Turns FirebaseAuth exceptions into user-friendly messages (SRS 1.6.1).
  static String friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'Invalid email or password.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'weak-password':
          return 'Password is too weak (minimum 6 characters).';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'network-request-failed':
          return 'A network connection is required. Please try again.';
        case 'requires-recent-login':
          return 'Please sign in again before changing your password.';
        default:
          return e.message ?? 'Authentication failed.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
