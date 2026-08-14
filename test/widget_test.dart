import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eventease/core/constants.dart';
import 'package:eventease/models/event.dart';
import 'package:eventease/repositories/event_repository.dart';
import 'package:eventease/services/map_launcher_service.dart';

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
      expect(event.isFull, false);
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
      expect(event.isFull, true);
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
      expect(event.hasStarted, true);
      expect(event.hasEnded, false);
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
      expect(event.hasEnded, true);
      expect(event.isCompleted, true);
    });
  });

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
        status: EventStatus.approved,
      ),
    ];

    test('filters by query', () {
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

    test('filters by location', () {
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
      expect(result.every((e) => !e.hasEnded), true);
    });

    test('clear returns all non-ended events', () {
      final result = EventRepository.filter(events);
      expect(result.length, 2);
    });
  });

  group('Google Maps directions URI', () {
    test('produces correct URI', () {
      final uri = MapLauncherService().googleDirectionsUri(24.8607, 67.0011);
      expect(
        uri.toString(),
        'https://www.google.com/maps/dir/?api=1&destination=24.8607%2C67.0011&dir_action=navigate',
      );
    });
  });
}
