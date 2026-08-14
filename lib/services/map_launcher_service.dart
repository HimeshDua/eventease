import 'package:url_launcher/url_launcher.dart';

/// Opens external Google Maps directions for an event location.
class MapLauncherService {
  Uri googleDirectionsUri(double latitude, double longitude) => Uri.https(
        'www.google.com',
        '/maps/dir/',
        <String, String>{
          'api': '1',
          'destination': '$latitude,$longitude',
        },
      );

  Future<void> openGoogleDirections(double latitude, double longitude) async {
    try {
      final launched = await launchUrl(
        googleDirectionsUri(latitude, longitude),
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (_) {
      // The user-facing error below intentionally hides platform details.
    }

    throw Exception('Could not open Google Maps. Please try again.');
  }
}
