import 'package:flutter/foundation.dart';

import '../models/route_option.dart';
import '../repositories/safe_route_repository.dart';

class SafeRouteViewModel extends ChangeNotifier {
  final SafeRouteRepository _repository;

  SafeRouteViewModel(this._repository);

  List<RouteOption> _routes = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedRouteId = 'route_1';

  List<RouteOption> get routes => List.unmodifiable(_routes);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedRouteId => _selectedRouteId;

  RouteOption? get selectedRoute {
    for (final route in _routes) {
      if (route.id == _selectedRouteId) return route;
    }
    return _routes.isEmpty ? null : _routes.first;
  }

  Future<void> loadRoutes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _routes = await _repository.getRoutes();
      if (!_routes.any((route) => route.id == _selectedRouteId)) {
        _selectedRouteId = _routes.isEmpty ? '' : _routes.first.id;
      }
    } catch (_) {
      _errorMessage = 'Could not load routes. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectRoute(String routeId) {
    if (!_routes.any((route) => route.id == routeId)) return;
    _selectedRouteId = routeId;
    notifyListeners();
  }
}
