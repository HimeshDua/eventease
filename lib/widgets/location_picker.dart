import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants.dart';

/// OSM manual-pin location picker for the organizer event form (SRS map requirement).
/// The organizer taps the map to place a pin and must enter a readable address.
class LocationPicker extends StatefulWidget {
  final double latitude;
  final double longitude;
  final ValueChanged<double> onLatitudeChanged;
  final ValueChanged<double> onLongitudeChanged;

  const LocationPicker({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onLatitudeChanged,
    required this.onLongitudeChanged,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late double _latitude;
  late double _longitude;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _latitude = widget.latitude != 0
        ? widget.latitude
        : MapDefaults.karachiLatitude;
    _longitude = widget.longitude != 0
        ? widget.longitude
        : MapDefaults.karachiLongitude;
  }

  void _onTap(LatLng point) {
    setState(() {
      _latitude = point.latitude;
      _longitude = point.longitude;
    });
    widget.onLatitudeChanged(_latitude);
    widget.onLongitudeChanged(_longitude);
  }

  void _recenter() {
    _mapController.move(LatLng(_latitude, _longitude), MapDefaults.pickerZoom);
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(_latitude, _longitude);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 240,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: MapDefaults.pickerZoom,
                onTap: (_, point) => _onTap(point),
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
          'Tap the map to set the venue location • OpenStreetMap contributors',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Latitude: ${_latitude.toStringAsFixed(5)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: Text(
                'Longitude: ${_longitude.toStringAsFixed(5)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Recentre map',
              onPressed: _recenter,
              icon: const Icon(Icons.my_location),
            ),
          ],
        ),
      ],
    );
  }
}
