import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'models.dart';

/// Change this to wherever maps  start.
const LatLng kStartCenter = LatLng(43.038902, -87.906471);
const double kStartZoom = 12;

///  Mapbox public token (starts with "pk."). Pass it at run time:
///   flutter run --dart-define=MAPBOX_TOKEN=pk.token_here
/// With no token, the app falls back to OpenStreetMap tiles.
const String _mapboxToken = String.fromEnvironment('MAPBOX_TOKEN');

/// Any classic Mapbox style works, e.g. streets-v12, light-v11, dark-v11.
const String _mapboxStyle = 'streets-v12';

final bool useMapbox = _mapboxToken.isNotEmpty;
final String _tileUrl = useMapbox
    ? 'https://api.mapbox.com/styles/v1/mapbox/$_mapboxStyle/tiles/256/{z}/{x}/{y}@2x?access_token=$_mapboxToken'
    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

TileLayer buildTileLayer() => TileLayer(
      urlTemplate: _tileUrl,
      userAgentPackageName: 'com.example.canvassing',
      maxNativeZoom: useMapbox ? 22 : 19,
    );

/// Map credit, shown at the top-left because the bottom of the screen is
/// covered by the draggable sheet. Mapbox and OpenStreetMap require credit.
class MapCredit extends StatelessWidget {
  const MapCredit({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(200),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                useMapbox
                    ? '© Mapbox © OpenStreetMap contributors'
                    : '© OpenStreetMap contributors (no Mapbox token)',
                style: const TextStyle(fontSize: 10, color: Colors.black87),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round numbered pin used for stops.
class NumberedPin extends StatelessWidget {
  final int number;
  final Color color;
  final double size;

  const NumberedPin({
    super.key,
    required this.number,
    required this.color,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black38,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}

/// Pin color by outcome: blue = not visited, green = surveyed,
/// orange = not home, gray = declined.
Color statusColor(BuildContext context, StopOutcome? outcome) {
  if (outcome == null) return Theme.of(context).colorScheme.primary;
  if (outcome == StopOutcome.completed) return Colors.green.shade600;
  if (outcome == StopOutcome.notHome) return Colors.orange.shade700;
  return Colors.grey.shade600;
}

/// Straight lines connecting the stops in order. This shows visiting order,
/// not walking directions.
PolylineLayer routeLine(List<LatLng> stops, Color color) {
  return PolylineLayer(
    polylines: [
      Polyline(points: stops, strokeWidth: 4, color: color.withAlpha(160)),
    ],
  );
}

/// Starts the map zoomed to fit all of a route's stops.
MapOptions routeMapOptions(List<LatLng> stops) {
  if (stops.length >= 2) {
    return MapOptions(
      initialCameraFit: CameraFit.coordinates(
        coordinates: stops,
        padding: const EdgeInsets.fromLTRB(48, 48, 48, 260),
        maxZoom: 17,
      ),
    );
  }
  return MapOptions(
    initialCenter: stops.isEmpty ? kStartCenter : stops.first,
    initialZoom: stops.isEmpty ? kStartZoom : 16,
  );
}
