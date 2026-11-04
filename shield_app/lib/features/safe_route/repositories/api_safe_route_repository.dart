
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/route_option.dart';
import 'safe_route_repository.dart';

class ApiSafeRouteRepository implements SafeRouteRepository {
  ApiSafeRouteRepository({required this.baseUrl});

  final String baseUrl;

  @override
  Future<List<RouteOption>> getRoutes({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  }) async {
    debugPrint('========== REPOSITORY DEBUG ==========');
    debugPrint('[Repository] Received start: $startLat, $startLon');
    debugPrint('[Repository] Received end: $endLat, $endLon');

    final uri = Uri.parse('$baseUrl/api/routes').replace(
      queryParameters: {
        'startLat': '$startLat',
        'startLon': '$startLon',
        'endLat': '$endLat',
        'endLon': '$endLon',
        'alternatives': 'true',
      },
    );

    debugPrint('[Repository] Request URL: $uri');

    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 20));

    debugPrint('[Repository] Status: ${response.statusCode}');
    debugPrint('[Repository] Response: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'Route API failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>? ?? [];

    debugPrint('[Repository] Routes received: ${routes.length}');

    return routes.map((item) {
      final route = item as Map<String, dynamic>;

      final distanceKm = (route['distanceKm'] as num).toDouble();
      final durationMinutes =
          (route['durationMinutes'] as num).toInt();

      final geometry = route['geometry'] as Map<String, dynamic>?;
      final rawCoordinates =
          geometry?['coordinates'] as List<dynamic>? ?? [];

      // OSRM returns [longitude, latitude].
      // Convert to [latitude, longitude].
      final coordinates = rawCoordinates.map<List<double>>((point) {
        final pair = point as List<dynamic>;

        return [
          (pair[1] as num).toDouble(),
          (pair[0] as num).toDouble(),
        ];
      }).toList();

      if (coordinates.isNotEmpty) {
        debugPrint(
          '[Repository] First coordinate: ${coordinates.first}',
        );
        debugPrint(
          '[Repository] Last coordinate: ${coordinates.last}',
        );
      }

      return RouteOption(
        id: route['id'] as String,
        title: 'Route ${route['id']}',
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        description:
            'Estimated driving route · ${distanceKm.toStringAsFixed(2)} km',
        coordinates: coordinates,
      );
    }).toList();
  }
}
