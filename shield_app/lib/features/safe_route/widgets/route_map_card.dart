
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RouteMapCard extends StatelessWidget {
  final bool fastest;
  final List<LatLng> points;

  const RouteMapCard({
    super.key,
    required this.fastest,
    required this.points,
  });

  static const background = Color(0xFF0E0817);
  static const teal = Color(0xFF12C6B0);
  static const amber = Color(0xFFFFB547);
  static const violet = Color(0xFF8955E8);
  static const coral = Color(0xFFFF4D6A);

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'No route geometry available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final routeColor = fastest ? amber : teal;

    final bounds = LatLngBounds.fromPoints(points);

    return Container(
      height: 260,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF493263)),
      ),
      child: FlutterMap(
        options: MapOptions(
          initialCameraFit: CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(42),
          ),
        ),
        children: [
          TileLayer(
            urlTemplate:
            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.shield_app',
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                strokeWidth: 8,
                color: routeColor.withValues(alpha: 0.25),
              ),
              Polyline(
                points: points,
                strokeWidth: 4,
                color: routeColor,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: points.first,
                width: 30,
                height: 30,
                child: const Icon(
                  Icons.location_on,
                  color: violet,
                  size: 30,
                ),
              ),
              Marker(
                point: points.last,
                width: 30,
                height: 30,
                child: const Icon(
                  Icons.location_on,
                  color: coral,
                  size: 30,
                ),
              ),
            ],
          ),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution('© OpenStreetMap contributors'),
            ],
          ),
        ],
      ),
    );
  }
}
