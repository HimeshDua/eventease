import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../models/event.dart';
import '../models/registration.dart';

/// Registration, QR pass, and attendance logic (SRS 1.6.6, 1.6.10).
/// Capacity, duplicate prevention, and check-in invariants are transactionally
/// enforced here; screens only call the public methods and surface failures.
class RegistrationRepository {
  RegistrationRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _regs =>
      _db.collection(Col.registrations);

  /// Registers [userId] for [eventId], or reactivates a cancelled pass.
  Future<Registration> register(String eventId, String userId) async {
    _requireCurrentUser(userId);
    final registrationRef = _regs.doc(_registrationId(eventId, userId));
    final eventRef = _db.collection(Col.events).doc(eventId);
    final userRef = _db.collection(Col.users).doc(userId);
    final qrCode = const Uuid().v4();

    await _db.runTransaction((transaction) async {
      final snapshots = await Future.wait([
        transaction.get(eventRef),
        transaction.get(registrationRef),
        transaction.get(userRef),
      ]);
      final eventSnapshot = snapshots[0];
      final registrationSnapshot = snapshots[1];
      final userSnapshot = snapshots[2];
      if (!eventSnapshot.exists) {
        throw StateError('Event not found.');
      }

      final event = Event.fromDoc(eventSnapshot);
      if (event.status != EventStatus.approved) {
        throw StateError('Registration is not open for this event.');
      }
      if (event.hasStarted) {
        throw StateError('This event has already started.');
      }
      if (event.isFull) {
        throw StateError('This event is full.');
      }

      final userName = userSnapshot.exists
          ? (userSnapshot.data() as Map<String, dynamic>)['name'] ?? ''
          : '';
      final userEmail = userSnapshot.exists
          ? (userSnapshot.data() as Map<String, dynamic>)['email'] ?? ''
          : '';

      if (registrationSnapshot.exists) {
        final registration = Registration.fromDoc(registrationSnapshot);
        if (registration.status == RegistrationStatus.registered ||
            registration.status == RegistrationStatus.attended) {
          throw StateError('You are already registered for this event.');
        }
        transaction.update(registrationRef, {
          'status': RegistrationStatus.registered,
          'qrCode': qrCode,
          'registeredAt': FieldValue.serverTimestamp(),
          'checkedInAt': null,
          'participantName': userName,
          'participantEmail': userEmail,
        });
      } else {
        transaction.set(registrationRef, {
          'eventId': eventId,
          'userId': userId,
          'status': RegistrationStatus.registered,
          'qrCode': qrCode,
          'registeredAt': FieldValue.serverTimestamp(),
          'checkedInAt': null,
          'participantName': userName,
          'participantEmail': userEmail,
        });
      }
      transaction.update(eventRef, {
        'registeredCount': event.registeredCount + 1,
      });
    });

    return Registration.fromDoc(await registrationRef.get());
  }

  /// Cancels an upcoming active registration and restores exactly one seat.
  Future<void> cancel(Registration registration) async {
    _requireCurrentUser(registration.userId);
    final registrationRef = _regs.doc(registration.id);
    final eventRef = _db.collection(Col.events).doc(registration.eventId);

    await _db.runTransaction((transaction) async {
      final snapshots = await Future.wait([
        transaction.get(registrationRef),
        transaction.get(eventRef),
      ]);
      final registrationSnapshot = snapshots[0];
      final eventSnapshot = snapshots[1];
      if (!registrationSnapshot.exists || !eventSnapshot.exists) {
        throw StateError('Registration or event not found.');
      }

      final freshRegistration = Registration.fromDoc(registrationSnapshot);
      final event = Event.fromDoc(eventSnapshot);
      if (freshRegistration.userId != registration.userId ||
          freshRegistration.eventId != registration.eventId) {
        throw StateError('Registration details do not match the stored pass.');
      }
      if (freshRegistration.status != RegistrationStatus.registered) {
        throw StateError('Only active registrations can be cancelled.');
      }
      if (event.hasStarted) {
        throw StateError('Registrations cannot be cancelled after the event starts.');
      }
      if (event.registeredCount <= 0) {
        throw StateError('Registration count cannot be reduced further.');
      }

      transaction.update(registrationRef, {
        'status': RegistrationStatus.cancelled,
      });
      transaction.update(eventRef, {
        'registeredCount': event.registeredCount - 1,
      });
    });
  }

  /// Marks a pass attended and creates its one deterministic attendance record.
  Future<Registration> checkInByQr(String qrCode, String eventId) async {
    final qrSnapshot = await _regs.where('qrCode', isEqualTo: qrCode).limit(1).get();
    if (qrSnapshot.docs.isEmpty) {
      throw StateError('Invalid QR code.');
    }

    final registrationRef = qrSnapshot.docs.first.reference;
    final eventRef = _db.collection(Col.events).doc(eventId);
    final attendanceRef = _db.collection(Col.attendance).doc(registrationRef.id);

    await _db.runTransaction((transaction) async {
      final snapshots = await Future.wait([
        transaction.get(registrationRef),
        transaction.get(eventRef),
        transaction.get(attendanceRef),
      ]);
      final registrationSnapshot = snapshots[0];
      final eventSnapshot = snapshots[1];
      final attendanceSnapshot = snapshots[2];
      if (!registrationSnapshot.exists) {
        throw StateError('Invalid QR code.');
      }
      if (!eventSnapshot.exists) {
        throw StateError('Event not found.');
      }

      final registration = Registration.fromDoc(registrationSnapshot);
      final event = Event.fromDoc(eventSnapshot);
      if (registration.qrCode != qrCode) {
        throw StateError('Invalid QR code.');
      }
      if (registration.eventId != eventId) {
        throw StateError('This pass belongs to a different event.');
      }
      if (event.status == EventStatus.cancelled) {
        throw StateError('This event has been cancelled.');
      }
      if (registration.status == RegistrationStatus.cancelled) {
        throw StateError('This registration was cancelled.');
      }
      if (registration.status == RegistrationStatus.attended ||
          attendanceSnapshot.exists) {
        throw StateError('Already checked in.');
      }
      if (registration.status != RegistrationStatus.registered) {
        throw StateError('This registration is not valid for check-in.');
      }

      transaction.update(registrationRef, {
        'status': RegistrationStatus.attended,
        'checkedInAt': FieldValue.serverTimestamp(),
      });
      transaction.set(attendanceRef, {
        'registrationId': registration.id,
        'eventId': registration.eventId,
        'userId': registration.userId,
        'attended': true,
        'checkedInAt': FieldValue.serverTimestamp(),
      });
    });

    return Registration.fromDoc(await registrationRef.get());
  }

  Stream<List<Registration>> byUser(String userId) => _regs
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Registration.fromDoc).toList());

  Stream<List<Registration>> byEvent(String eventId) => _regs
      .where('eventId', isEqualTo: eventId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Registration.fromDoc).toList());

  Stream<List<Registration>> allRegistrations() =>
      _regs.snapshots().map((snapshot) => snapshot.docs.map(Registration.fromDoc).toList());

  static String _registrationId(String eventId, String userId) => '${userId}_$eventId';

  void _requireCurrentUser(String userId) {
    if (_auth.currentUser?.uid != userId) {
      throw StateError('You can only manage your own registrations.');
    }
  }
}
