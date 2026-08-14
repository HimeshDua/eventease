import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/event.dart';

/// All reads/writes for events. Screens must use this, never Firestore directly.
class EventRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _events => _db.collection(Col.events);

  /// Approved upcoming events for Discover (SRS 1.6.3).
  Stream<List<Event>> approvedUpcoming() => _events
      .where('status', isEqualTo: EventStatus.approved)
      .orderBy('startTime')
      .snapshots()
      .map((s) => s.docs.map(Event.fromDoc).toList());

  Stream<List<Event>> byOrganizer(String organizerId) => _events
      .where('organizerId', isEqualTo: organizerId)
      .snapshots()
      .map((s) => s.docs.map(Event.fromDoc).toList());

  /// Admin: everything, pending first is done client-side.
  Stream<List<Event>> all() =>
      _events.snapshots().map((s) => s.docs.map(Event.fromDoc).toList());

  Stream<Event> watch(String eventId) =>
      _events.doc(eventId).snapshots().map(Event.fromDoc);

  /// Creates an event in Pending Approval status (SRS 1.6.11).
  Future<String> create(Event event) async {
    final doc = await _events.add({
      ...event.toMap(),
      'status': EventStatus.pending,
      'registeredCount': 0,
    });
    return doc.id;
  }

  Future<void> update(String eventId, Map<String, dynamic> changes) =>
      _events.doc(eventId).update(changes);

  Future<void> setStatus(String eventId, String status) =>
      _events.doc(eventId).update({'status': status});

  /// Client-side search/filter helper (SRS 1.6.4) — fine for student scale.
  static List<Event> filter(
    List<Event> events, {
    String query = '',
    String? category,
    DateTime? date,
    bool onlyAvailable = false,
  }) {
    return events.where((e) {
      final q = query.trim().toLowerCase();
      if (q.isNotEmpty &&
          !e.title.toLowerCase().contains(q) &&
          !e.description.toLowerCase().contains(q) &&
          !e.location.toLowerCase().contains(q)) {
        return false;
      }
      if (category != null && category.isNotEmpty && e.category != category) {
        return false;
      }
      if (date != null &&
          !(e.startTime.year == date.year &&
              e.startTime.month == date.month &&
              e.startTime.day == date.day)) {
        return false;
      }
      if (onlyAvailable && e.isFull) return false;
      return true;
    }).toList();
  }
}
