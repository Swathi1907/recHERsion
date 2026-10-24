import '../models/route_option.dart';
import 'safe_route_repository.dart';

class DemoSafeRouteRepository implements SafeRouteRepository {
  @override
  Future<List<RouteOption>> getRoutes() async {
    // Temporary demonstration data, not real navigation results.
    return const [
      RouteOption(
        id: 'route_1',
        title: 'Route A',
        distanceKm: 1.9,
        durationMinutes: 22,
        description: 'Demonstration route',
      ),
      RouteOption(
        id: 'route_2',
        title: 'Route B',
        distanceKm: 1.6,
        durationMinutes: 17,
        description: 'Demonstration alternative',
      ),
    ];
  }
}
