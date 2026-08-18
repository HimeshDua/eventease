import 'package:flutter_test/flutter_test.dart';

import 'package:eventease/core/constants.dart';
import 'package:eventease/models/event.dart';
import 'package:eventease/repositories/event_repository.dart';

void main() {
  group('EventRepository.filter', () {
    final now = DateTime.now();
    final events = [
      Event(
        id: '1',
        organizerId: 'org1',
        title: 'Flutter Workshop',
        description: 'Learn Flutter',
        category: 'Technology',
        location: 'Karachi',
        rules: '',
        contactInfo: '',
        startTime: now.add(const Duration(days: 1)),
        endTime: now.add(const Duration(days: 1, hours: 3)),
        maxParticipants: 50,
        registeredCount: 10,
        status: EventStatus.approved,
      ),
      Event(
        id: '2',
        organizerId: 'org1',
        title: 'Music Concert',
        description: 'Live music',
        category: 'Music',
        location: 'Lahore',
        rules: '',
        contactInfo: '',
        startTime: now.add(const Duration(days: 2)),
        endTime: now.add(const Duration(days: 2, hours: 4)),
        maxParticipants: 200,
        registeredCount: 200,
        status: EventStatus.approved,
      ),
      Event(
        id: '3',
        organizerId: 'org1',
        title: 'Past Event',
        description: 'Already happened',
        category: 'Education',
        location: 'Islamabad',
        rules: '',
        contactInfo: '',
        startTime: now.subtract(const Duration(days: 2)),
        endTime: now.subtract(const Duration(days: 2, hours: 1)),
        maxParticipants: 30,
        registeredCount: 5,
        status: EventStatus.approved,
      ),
    ];

    test('filters by query keyword', () {
      final result = EventRepository.filter(events, query: 'flutter');
      expect(result.length, 1);
      expect(result.first.title, 'Flutter Workshop');
    });

    test('filters by category', () {
      final result = EventRepository.filter(events, category: 'Music');
      expect(result.length, 1);
      expect(result.first.title, 'Music Concert');
    });

    test('filters by date', () {
      final date = now.add(const Duration(days: 1));
      final result = EventRepository.filter(events, date: date);
      expect(result.length, 1);
      expect(result.first.title, 'Flutter Workshop');
    });

    test('filters by location (case-insensitive)', () {
      final result = EventRepository.filter(events, location: 'lahore');
      expect(result.length, 1);
      expect(result.first.title, 'Music Concert');
    });

    test('onlyAvailable excludes full events', () {
      final result = EventRepository.filter(events, onlyAvailable: true);
      expect(result.length, 1);
      expect(result.first.title, 'Flutter Workshop');
    });

    test('excludes ended events', () {
      final result = EventRepository.filter(events);
      expect(result.length, 2);
      expect(result.every((e) => !e.hasEnded), isTrue);
    });

    test('empty query returns all non-ended events', () {
      final result = EventRepository.filter(events);
      expect(result.length, 2);
    });

    test('clear resets by matching no filter criteria', () {
      final filtered = EventRepository.filter(events, category: 'Sports');
      expect(filtered, isEmpty);
      final cleared = EventRepository.filter(events);
      expect(cleared.length, 2);
    });
  });
}
