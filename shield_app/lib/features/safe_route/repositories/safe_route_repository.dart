
import '../models/route_option.dart';

abstract class SafeRouteRepository {
  Future<List<RouteOption>> getRoutes({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  });
}
