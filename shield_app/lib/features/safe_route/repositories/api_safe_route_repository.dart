
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/route_option.dart';
import 'safe_route_repository.dart';

class ApiSafeRouteRepository implements SafeRouteRepository {
  ApiSafeRouteRepository({required this.baseUrl});

  final String baseUrl;

  @override
  Future<List<RouteOption>> getRoutes() async {
    const startLat = 23.7957;
    const startLon = 86.4304;
    const endLat = 23.8103;
    const endLon = 86.4412;

    final uri = Uri.parse('$baseUrl/api/routes').replace(
      queryParameters: {
        'startLat': '$startLat',
        'startLon': '$startLon',
        'endLat': '$endLat',
        'endLon': '$endLon',
        'alternatives': 'true',
      },
    );

    final response =
    await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        'Route API failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>? ?? [];

    return routes.map((item) {
      final route = item as Map<String, dynamic>;
      final distanceKm = (route['distanceKm'] as num).toDouble();
      final durationMinutes = (route['durationMinutes'] as num).toInt();

      final geometry = route['geometry'] as Map<String, dynamic>?;
      final rawCoordinates =
          geometry?['coordinates'] as List<dynamic>? ?? [];

      // OSRM returns [longitude, latitude].
      // Store each point as [latitude, longitude].
      final coordinates = rawCoordinates.map<List<double>>((point) {
        final pair = point as List<dynamic>;
        return [
          (pair[1] as num).toDouble(),
          (pair[0] as num).toDouble(),
        ];
      }).toList();

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
