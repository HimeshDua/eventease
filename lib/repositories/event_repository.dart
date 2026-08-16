import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/constants.dart';
import '../models/event.dart';
import '../models/gallery_item.dart';
import '../services/storage_service.dart';

/// All reads and writes for events. Screens must use this, never Firestore
/// directly.
class EventRepository {
  EventRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storageService = StorageService(storage: storage);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final StorageService _storageService;

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection(Col.events);

  /// Allocates an event ID before an organizer uploads its cover image.
  String newId() => _events.doc().id;

  /// Approved, not-yet-ended events for discovery (SRS 1.6.3).
  Stream<List<Event>> approvedUpcoming() => _events
      .where('status', isEqualTo: EventStatus.approved)
      .orderBy('startTime')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(Event.fromDoc)
            .where((event) => !event.hasEnded)
            .toList(),
      );

  Stream<List<Event>> byOrganizer(String organizerId) => _events
      .where('organizerId', isEqualTo: organizerId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Event.fromDoc).toList());

  /// Admin: everything; display ordering belongs to the presentation layer.
  Stream<List<Event>> all() => _events.snapshots().map(
    (snapshot) => snapshot.docs.map(Event.fromDoc).toList(),
  );

  /// Admin approval queue: query only pending events instead of downloading
  /// and filtering the complete events collection in the presentation layer.
  Stream<List<Event>> watchPendingEvents() => _events
      .where('status', isEqualTo: EventStatus.pending)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Event.fromDoc).toList());

  /// Admin cancellation queue kept separate from normal event approval.
  Stream<List<Event>> watchCancellationRequests() => _events
      .where('cancellationRequested', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Event.fromDoc).toList());

  Stream<Event> watch(String eventId) =>
      _events.doc(eventId).snapshots().map(Event.fromDoc);

  /// Creates an event with server-controlled lifecycle values.
  Future<void> create(String eventId, Event event) async {
    final ownerId = _requireCurrentUserId();
    if (eventId.isEmpty) {
      throw ArgumentError.value(eventId, 'eventId', 'An event ID is required.');
    }
    if (event.organizerId != ownerId) {
      throw StateError('You can only create events for your own account.');
    }

    await _events.doc(eventId).set({
      ...event.toMap(),
      'organizerId': ownerId,
      'status': EventStatus.pending,
      'registeredCount': 0,
      'cancellationRequested': false,
      'cancellationReason': null,
      'changeReviewPending': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates an event owned by the signed-in organizer.
  Future<void> updateOwned(String eventId, Map<String, dynamic> changes) async {
    final ownerId = _requireCurrentUserId();
    const protectedFields = {
      'organizerId',
      'registeredCount',
      'status',
      'cancellationRequested',
      'cancellationReason',
      'changeReviewPending',
      'createdAt',
    };
    if (changes.keys.any(protectedFields.contains)) {
      throw ArgumentError(
        'This update contains server-controlled event fields.',
      );
    }

    await _db.runTransaction((transaction) async {
      final eventRef = _events.doc(eventId);
      final eventSnapshot = await transaction.get(eventRef);
      if (!eventSnapshot.exists) {
        throw StateError('Event not found.');
      }

      final event = Event.fromDoc(eventSnapshot);
      if (event.organizerId != ownerId) {
        throw StateError('You can only edit events that you own.');
      }
      if (event.hasStarted || event.status == EventStatus.cancelled) {
        throw StateError('Started or cancelled events cannot be edited.');
      }

      final update = <String, dynamic>{...changes};
      final requestedCapacity = changes['maxParticipants'];
      if (requestedCapacity is int && requestedCapacity < event.registeredCount) {
        throw StateError(
          'Capacity cannot be lower than the current registration count.',
        );
      }
      const criticalFields = {
        'startTime',
        'endTime',
        'location',
        'latitude',
        'longitude',
      };
      if (event.status == EventStatus.approved &&
          changes.keys.any(criticalFields.contains)) {
        update['status'] = EventStatus.pending;
        update['changeReviewPending'] = true;
      }
      update['updatedAt'] = FieldValue.serverTimestamp();
      transaction.update(eventRef, update);
    });
  }

  /// Admin lifecycle transition. Firestore rules enforce administrator access.
  Future<void> setStatus(
    String eventId,
    String status, {
    bool changeReviewPending = false,
  }) => _events.doc(eventId).update({
    'status': status,
    'changeReviewPending': changeReviewPending,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  /// An organizer can request cancellation but cannot cancel an event directly.
  Future<void> requestCancellation(String eventId, String reason) async {
    final ownerId = _requireCurrentUserId();
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw ArgumentError.value(
        reason,
        'reason',
        'A cancellation reason is required.',
      );
    }

    await _db.runTransaction((transaction) async {
      final eventRef = _events.doc(eventId);
      final eventSnapshot = await transaction.get(eventRef);
      if (!eventSnapshot.exists) {
        throw StateError('Event not found.');
      }
      final event = Event.fromDoc(eventSnapshot);
      if (event.organizerId != ownerId) {
        throw StateError(
          'You can only request cancellation for your own event.',
        );
      }
      if (event.status == EventStatus.cancelled || event.hasEnded) {
        throw StateError('This event can no longer be cancelled.');
      }

      transaction.update(eventRef, {
        'cancellationRequested': true,
        'cancellationReason': trimmedReason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Admin rejection of an organizer's cancellation request. Clears the
  /// request fields so the event continues as active.
  Future<void> rejectCancellation(String eventId) async {
    await _db.runTransaction((transaction) async {
      final eventRef = _events.doc(eventId);
      final eventSnapshot = await transaction.get(eventRef);
      if (!eventSnapshot.exists) {
        throw StateError('Event not found.');
      }
      final event = Event.fromDoc(eventSnapshot);
      if (!event.cancellationRequested) {
        throw StateError('This event has no pending cancellation request.');
      }

      transaction.update(eventRef, {
        'cancellationRequested': false,
        'cancellationReason': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Admin approval of an organizer's cancellation request.
  Future<void> approveCancellation(String eventId) async {
    await _db.runTransaction((transaction) async {
      final eventRef = _events.doc(eventId);
      final eventSnapshot = await transaction.get(eventRef);
      if (!eventSnapshot.exists) {
        throw StateError('Event not found.');
      }
      final event = Event.fromDoc(eventSnapshot);
      if (!event.cancellationRequested) {
        throw StateError('This event has no pending cancellation request.');
      }

      transaction.update(eventRef, {
        'status': EventStatus.cancelled,
        'cancellationRequested': false,
        'cancellationReason': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Admin deletes only a zero-registration event and all of its media.
  /// Events with registrations are preserved for history (SRS 1.6.17).
  Future<void> adminDelete(String eventId) async {
    final eventRef = _events.doc(eventId);
    final eventSnapshot = await eventRef.get();
    if (!eventSnapshot.exists) {
      throw StateError('Event not found.');
    }
    final event = Event.fromDoc(eventSnapshot);
    if (event.registeredCount > 0) {
      throw StateError(
        'Events with registrations cannot be deleted. They are kept for history.',
      );
    }

    // Remove gallery media documents and their Storage objects.
    final galleryDocs = await _db
        .collection(Col.gallery)
        .where('eventId', isEqualTo: eventId)
        .get();
    for (final doc in galleryDocs.docs) {
      final item = GalleryItem.fromDoc(doc);
      await _storageService.deleteByUrl(item.imageUrl);
    }
    for (final doc in galleryDocs.docs) {
      await doc.reference.delete();
    }

    // Remove the cover image object when present.
    final coverPath = event.imageUrl;
    if (coverPath != null && coverPath.isNotEmpty) {
      await _storageService.deleteByUrl(coverPath);
    }

    await eventRef.delete();
  }

  /// Client-side discovery filters (SRS 1.6.4).
  static List<Event> filter(
    List<Event> events, {
    String query = '',
    String? category,
    DateTime? date,
    String? location,
    bool onlyAvailable = false,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedLocation = location?.trim().toLowerCase() ?? '';
    return events.where((event) {
      if (event.hasEnded) return false;
      if (normalizedQuery.isNotEmpty &&
          !event.title.toLowerCase().contains(normalizedQuery) &&
          !event.description.toLowerCase().contains(normalizedQuery) &&
          !event.location.toLowerCase().contains(normalizedQuery)) {
        return false;
      }
      if (category != null &&
          category.isNotEmpty &&
          event.category != category) {
        return false;
      }
      if (date != null &&
          (event.startTime.year != date.year ||
              event.startTime.month != date.month ||
              event.startTime.day != date.day)) {
        return false;
      }
      if (normalizedLocation.isNotEmpty &&
          !event.location.toLowerCase().contains(normalizedLocation)) {
        return false;
      }
      return !onlyAvailable || !event.isFull;
    }).toList();
  }

  String _requireCurrentUserId() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw StateError('Please sign in to manage events.');
    }
    return userId;
  }
}
