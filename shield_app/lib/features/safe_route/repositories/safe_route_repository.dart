import '../models/route_option.dart';

abstract class SafeRouteRepository {
  Future<List<RouteOption>> getRoutes();
}
