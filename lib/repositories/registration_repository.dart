import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../models/event.dart';
import '../models/registration.dart';

/// Registration, QR pass, and attendance logic (SRS 1.6.6, 1.6.10).
/// The hard invariants (capacity, no duplicates, no double check-in) all
/// live here inside Firestore transactions — screens just call and catch.
class RegistrationRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _regs => _db.collection(Col.registrations);

  /// Registers [userId] for [eventId]. Throws with a readable message on
  /// closed registration, full capacity, or duplicate registration.
  /// Returns the created Registration (contains the QR code string).
  Future<Registration> register(String eventId, String userId) async {
    // Duplicate check first (query not allowed inside a transaction).
    final dup = await _regs
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: [
          RegistrationStatus.registered,
          RegistrationStatus.attended,
        ])
        .limit(1)
        .get();
    if (dup.docs.isNotEmpty) {
      throw Exception('You are already registered for this event.');
    }

    final qrCode = const Uuid().v4();
    final regRef = _regs.doc();

    await _db.runTransaction((tx) async {
      final eventRef = _db.collection(Col.events).doc(eventId);
      final eventSnap = await tx.get(eventRef);
      if (!eventSnap.exists) throw Exception('Event not found.');
      final event = Event.fromDoc(eventSnap);

      if (event.status != EventStatus.approved) {
        throw Exception('Registration is not open for this event.');
      }
      if (event.hasStarted) {
        throw Exception('This event has already started.');
      }
      if (event.isFull) {
        throw Exception('This event is full.');
      }

      tx.set(regRef, {
        'eventId': eventId,
        'userId': userId,
        'status': RegistrationStatus.registered,
        'qrCode': qrCode,
        'registeredAt': FieldValue.serverTimestamp(),
        'checkedInAt': null,
      });
      tx.update(eventRef, {'registeredCount': FieldValue.increment(1)});
    });

    final doc = await regRef.get();
    return Registration.fromDoc(doc);
  }

  Future<void> cancel(Registration reg) async {
    await _db.runTransaction((tx) async {
      tx.update(_regs.doc(reg.id), {'status': RegistrationStatus.cancelled});
      tx.update(_db.collection(Col.events).doc(reg.eventId),
          {'registeredCount': FieldValue.increment(-1)});
    });
  }

  /// Organizer scans a QR code. Marks the registration attended.
  /// Throws readable errors for unknown QR, wrong event, or duplicate check-in.
  Future<Registration> checkInByQr(String qrCode, String eventId) async {
    final snap =
        await _regs.where('qrCode', isEqualTo: qrCode).limit(1).get();
    if (snap.docs.isEmpty) throw Exception('Invalid QR code.');

    final reg = Registration.fromDoc(snap.docs.first);
    if (reg.eventId != eventId) {
      throw Exception('This pass belongs to a different event.');
    }

    await _db.runTransaction((tx) async {
      final ref = _regs.doc(reg.id);
      final fresh = Registration.fromDoc(await tx.get(ref));
      if (fresh.status == RegistrationStatus.attended) {
        throw Exception('Already checked in.');
      }
      if (fresh.status == RegistrationStatus.cancelled) {
        throw Exception('This registration was cancelled.');
      }
      tx.update(ref, {
        'status': RegistrationStatus.attended,
        'checkedInAt': FieldValue.serverTimestamp(),
      });
      // Attendance record (SRS entity) — kept simple: one doc per check-in.
      tx.set(_db.collection(Col.attendance).doc(), {
        'registrationId': reg.id,
        'eventId': reg.eventId,
        'userId': reg.userId,
        'attended': true,
        'checkedInAt': FieldValue.serverTimestamp(),
      });
    });

    return reg;
  }

  Stream<List<Registration>> byUser(String userId) => _regs
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((s) => s.docs.map(Registration.fromDoc).toList());

  Stream<List<Registration>> byEvent(String eventId) => _regs
      .where('eventId', isEqualTo: eventId)
      .snapshots()
      .map((s) => s.docs.map(Registration.fromDoc).toList());
}
