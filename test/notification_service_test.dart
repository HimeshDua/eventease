import 'package:flutter_test/flutter_test.dart';

import 'package:eventease/services/fcm_notification_service.dart';

void main() {
  test('notification payload builder preserves event context', () {
    final payload = FcmNotificationService.payloadFor(
      title: 'Event cancelled',
      body: 'The event was cancelled.',
      eventId: 'event-123',
      type: 'cancelled',
    );
    expect(payload['eventId'], 'event-123');
    expect(payload['type'], 'cancelled');
    expect(payload['title'], 'Event cancelled');
    expect(payload['body'], 'The event was cancelled.');
  });
}
