import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../services/map_launcher_service.dart';

/// Embedded OpenStreetMap view for a single event venue (mandatory map
/// enhancement). No tile prefetching or bulk downloads are performed.
class EventMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String locationName;

  const EventMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  Future<void> _openDirections(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final maps = context.read<MapLauncherService>();
    try {
      await maps.openGoogleDirections(latitude, longitude);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(latitude, longitude);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 180,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: MapDefaults.venueZoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: MapDefaults.tileUrl,
                  userAgentPackageName: MapDefaults.userAgentPackageName,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_on,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'OpenStreetMap contributors',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _openDirections(context),
            icon: const Icon(Icons.directions_outlined),
            label: const Text('Get directions'),
          ),
        ),
      ],
    );
  }
}
