import 'package:flutter_test/flutter_test.dart';

import 'package:eventease/services/map_launcher_service.dart';

void main() {
  group('Google Maps directions URI', () {
    test('produces correct external navigation URI', () {
      final uri = MapLauncherService().googleDirectionsUri(24.8607, 67.0011);
      expect(
        uri.toString(),
        'https://www.google.com/maps/dir/?api=1&destination=24.8607%2C67.0011&dir_action=navigate',
      );
    });

    test('uses https scheme and google.com host', () {
      final uri = MapLauncherService().googleDirectionsUri(31.5204, 74.3587);
      expect(uri.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
    });

    test('encodes destination as a query parameter', () {
      final uri = MapLauncherService().googleDirectionsUri(0.0, 0.0);
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters['destination'], '0.0,0.0');
      expect(uri.queryParameters['dir_action'], 'navigate');
    });
  });
}
