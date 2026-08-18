import 'package:flutter_test/flutter_test.dart';

import 'package:eventease/repositories/misc_repositories.dart';

void main() {
  group('NotificationTypes', () {
    test('defines every notification type required by the SRS', () {
      expect(NotificationTypes.registration, 'registration');
      expect(NotificationTypes.reminder, 'reminder');
      expect(NotificationTypes.eventChanged, 'eventChanged');
      expect(NotificationTypes.cancelled, 'cancelled');
      expect(NotificationTypes.announcement, 'announcement');
      expect(NotificationTypes.feedbackRequest, 'feedbackRequest');
      expect(NotificationTypes.approval, 'approval');
      expect(NotificationTypes.rejection, 'rejection');
      expect(NotificationTypes.roleApproved, 'roleApproved');
    });
  });
}
