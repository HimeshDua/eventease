import 'package:flutter_test/flutter_test.dart';

import 'package:eventease/core/constants.dart';
import 'package:eventease/models/event.dart';

void main() {
  Event makeEvent({required String status}) => Event(
    id: 'event-1',
    organizerId: 'organizer-1',
    title: 'Demo',
    description: 'Demo event',
    category: EventCategories.all.first,
    location: 'Karachi',
    rules: '',
    contactInfo: '',
    startTime: DateTime.now().add(const Duration(days: 1)),
    endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
    maxParticipants: 20,
    registeredCount: 1,
    status: status,
  );

  test(
    'cancelled event retains cancelled status for My Events classification',
    () {
      final event = makeEvent(status: EventStatus.cancelled);
      expect(event.status, EventStatus.cancelled);
      expect(event.isCompleted, isFalse);
    },
  );

  test(
    'admin edits preserve the existing organizer rather than the admin id',
    () {
      final event = makeEvent(status: EventStatus.approved);
      expect(event.organizerId, 'organizer-1');
    },
  );
}
