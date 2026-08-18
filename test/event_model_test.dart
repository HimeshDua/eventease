import 'package:flutter_test/flutter_test.dart';

import 'package:eventease/core/constants.dart';
import 'package:eventease/models/event.dart';

void main() {
  group('Event model derived state', () {
    test('availableSeats is max minus registered', () {
      final event = Event(
        id: '1',
        organizerId: 'org1',
        title: 'Test',
        description: 'Desc',
        category: EventCategories.all.first,
        location: 'Location',
        rules: '',
        contactInfo: '',
        startTime: DateTime.now().add(const Duration(days: 1)),
        endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        maxParticipants: 100,
        registeredCount: 30,
        status: EventStatus.approved,
      );
      expect(event.availableSeats, 70);
      expect(event.isFull, isFalse);
    });

    test('isFull when registered equals max', () {
      final event = Event(
        id: '2',
        organizerId: 'org1',
        title: 'Full',
        description: 'Desc',
        category: EventCategories.all.first,
        location: 'Location',
        rules: '',
        contactInfo: '',
        startTime: DateTime.now().add(const Duration(days: 1)),
        endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        maxParticipants: 50,
        registeredCount: 50,
        status: EventStatus.approved,
      );
      expect(event.isFull, isTrue);
      expect(event.availableSeats, 0);
    });

    test('hasStarted returns true for past start time', () {
      final event = Event(
        id: '3',
        organizerId: 'org1',
        title: 'Past',
        description: 'Desc',
        category: EventCategories.all.first,
        location: 'Location',
        rules: '',
        contactInfo: '',
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        maxParticipants: 10,
        status: EventStatus.approved,
      );
      expect(event.hasStarted, isTrue);
      expect(event.hasEnded, isFalse);
    });

    test('hasEnded returns true for past end time', () {
      final event = Event(
        id: '4',
        organizerId: 'org1',
        title: 'Ended',
        description: 'Desc',
        category: EventCategories.all.first,
        location: 'Location',
        rules: '',
        contactInfo: '',
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now().subtract(const Duration(hours: 1)),
        maxParticipants: 10,
        status: EventStatus.approved,
      );
      expect(event.hasEnded, isTrue);
      expect(event.isCompleted, isTrue);
    });

    test('isCompleted is true when status is completed', () {
      final event = Event(
        id: '5',
        organizerId: 'org1',
        title: 'Completed',
        description: 'Desc',
        category: EventCategories.all.first,
        location: 'Location',
        rules: '',
        contactInfo: '',
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now().subtract(const Duration(hours: 1)),
        maxParticipants: 10,
        status: EventStatus.completed,
      );
      expect(event.isCompleted, isTrue);
    });
  });
}
