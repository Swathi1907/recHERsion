import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../core/services/location_service.dart';
import 'dart:async';
import '../widgets/route_map_card.dart';
import '../repositories/api_safe_route_repository.dart';
import '../viewmodels/safe_route_viewmodel.dart';

class SafeRoutePage extends StatefulWidget {
  const SafeRoutePage({super.key});

  @override
  State<SafeRoutePage> createState() => _SafeRoutePageState();
}

class _SafeRoutePageState extends State<SafeRoutePage> {
  static const bg = Color(0xFF130B20);
  static const panel = Color(0xFF211532);
  static const teal = Color(0xFF14B8A6);
  static const coral = Color(0xFFFF4D6A);
  static const muted = Color(0xFFB9A9D0);

  static const baseUrl = 'http://172.22.21.254:3000';
final TextEditingController _destinationController =
    TextEditingController();

Timer? _searchDebounce;

bool _searchLoading = false;
String? _searchError;

List<Map<String, dynamic>> _destinationSuggestions = [];

Map<String, dynamic>? _selectedDestination;
  // Temporary coordinates; replace with phone GPS when ready.
  late final SafeRouteViewModel _viewModel;
String _currentLocationName = 'My Current Location';
  String _category = 'all';
  bool _placesLoading = false;
  String? _placesError;
  List<Map<String, dynamic>> _places = [];

  final Map<String, String> _categories = const {
    'all': 'All',
    'shops': 'Shops',
    'pharmacies': 'Pharmacies',
    'food': 'Food',
    'healthcare': 'Healthcare',
  };

  @override
  void initState() {
    super.initState();
    _viewModel = SafeRouteViewModel(
      ApiSafeRouteRepository(baseUrl: baseUrl),
    );
    
_loadNearbyPlaces();
  }

  @override
void dispose() {
  _searchDebounce?.cancel();
  _destinationController.dispose();
  _viewModel.dispose();
  super.dispose();
}
void _onDestinationChanged(String value) {
  _searchDebounce?.cancel();

  setState(() {
    _selectedDestination = null;
    _destinationSuggestions = [];
    _searchError = null;
  });

  if (value.trim().length < 3) return;

  _searchDebounce = Timer(
    const Duration(seconds: 1),
    () => _searchDestinations(value.trim()),
  );
}

Future<void> _searchDestinations(String query) async {
  setState(() {
    _searchLoading = true;
    _searchError = null;
  });

  try {
    final uri = Uri.parse('$baseUrl/api/routes/search').replace(
      queryParameters: {'query': query},
    );

    final response = await http.get(uri).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode != 200) {
      throw Exception('Search failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['destinations'] as List<dynamic>? ?? [];

    if (!mounted) return;

    setState(() {
      _destinationSuggestions = results
          .whereType<Map<String, dynamic>>()
          .toList();
    });
  } catch (error) {
    if (!mounted) return;

    setState(() {
      _searchError = 'Could not search destinations. Please try again.';
    });

    debugPrint('[Destination Search] Error: $error');
  } finally {
    if (mounted) {
      setState(() => _searchLoading = false);
    }
  }
}
void _selectDestination(Map<String, dynamic> destination) {
  FocusScope.of(context).unfocus();

  setState(() {
    _selectedDestination = destination;
    _destinationSuggestions = [];
    _destinationController.text =
        destination['name']?.toString() ?? '';
  });

  _loadRoutes(destination: destination);
}
 Future<void> _loadNearbyPlaces({String? category}) async {
    final requestedCategory = category ?? _category;

    setState(() {
      _placesLoading = true;
      _placesError = null;
    });

    try {
      // Use the phone's actual GPS location.
      final position = await LocationService().getCurrentLocation();
      final latitude = position.latitude;
      final longitude = position.longitude;
      const radiusMeters = 1000;

      final uri = Uri.parse('$baseUrl/api/places/nearby').replace(
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'radiusMeters': radiusMeters.toString(),
          'category': requestedCategory,
        },
      );

      debugPrint('========== NEARBY PLACES DEBUG ==========');
      debugPrint('[Nearby] Request URL: $uri');
      debugPrint('[Nearby] Actual GPS coordinates: $latitude, $longitude');
      debugPrint('[Nearby] Radius: $radiusMeters metres');
      debugPrint('[Nearby] Category: $requestedCategory');

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      debugPrint('[Nearby] HTTP status: ${response.statusCode}');
      debugPrint('[Nearby] Raw response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'Nearby API failed: HTTP ${response.statusCode} - ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['places'] as List<dynamic>? ?? [];
      final places = results
          .whereType<Map<String, dynamic>>()
          .toList();

      debugPrint('[Nearby] Places received: ${places.length}');
      if (places.isNotEmpty) {
        debugPrint('[Nearby] First place: ${places.first['name']}');
        debugPrint('[Nearby] First address: ${places.first['address']}');
      }
      debugPrint('=========================================');

      if (!mounted) return;

      setState(() {
        _category = requestedCategory;
        _places = places;
      });
    } catch (error, stackTrace) {
      debugPrint('[Nearby] ERROR: $error');
      debugPrint('[Nearby] STACK TRACE: $stackTrace');

      if (!mounted) return;

      setState(() {
        _placesError =
            'Could not load nearby places. Check your connection and retry.';
      });
    } finally {
      if (mounted) {
        setState(() => _placesLoading = false);
      }
    }
  }

 Future<void> _loadRoutes({
  Map<String, dynamic>? destination,
}) async {
    try {
      // Use the phone's actual GPS location as the route origin.
      final position = await LocationService().getCurrentLocation();
      if (!mounted) return;

      final startLat = position.latitude;
      final startLon = position.longitude;

      // Current fixed destination: Bank More, Dhanbad.
      // Replace these with user-selected destination coordinates when
      // destination search is implemented.
      if (destination == null) {
  _showMessage('Please select a destination first.');
  return;
}

final endLat = (destination['latitude'] as num).toDouble();
final endLon = (destination['longitude'] as num).toDouble();

      debugPrint('\\n========== SAFEROUTE DEBUG ==========');
      debugPrint('[SafeRoute] API base URL: $baseUrl');
      debugPrint('[SafeRoute] Actual GPS start: $startLat, $startLon');
     debugPrint(
  '[SafeRoute] Destination: ${destination['name']} '
  '($endLat, $endLon)',
);
      debugPrint('[SafeRoute] Calling ViewModel.loadRoutes...');

      await _viewModel.loadRoutes(
        startLat: startLat,
        startLon: startLon,
        endLat: endLat,
        endLon: endLon,
      );

      debugPrint('[SafeRoute] ViewModel call completed.');
      debugPrint('[SafeRoute] Error: ${_viewModel.errorMessage}');
      debugPrint('[SafeRoute] Routes received: ${_viewModel.routes.length}');

      for (final route in _viewModel.routes) {
        debugPrint(
          '[SafeRoute] Route ${route.id}: '
          '${route.distanceKm} km, ${route.durationMinutes} min',
        );
        debugPrint(
          '[SafeRoute] ${route.id} coordinate count: '
          '${route.coordinates.length}',
        );
        if (route.coordinates.isNotEmpty) {
          debugPrint(
            '[SafeRoute] ${route.id} FIRST coordinate [lat, lon]: '
            '${route.coordinates.first}',
          );
          debugPrint(
            '[SafeRoute] ${route.id} LAST coordinate [lat, lon]: '
            '${route.coordinates.last}',
          );
        }
      }

      debugPrint('====================================\\n');
    } catch (error, stackTrace) {
      debugPrint('[SafeRoute] ERROR: $error');
      debugPrint('[SafeRoute] STACK TRACE: $stackTrace');

      if (mounted) {
        _showMessage('Could not load route: $error');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: panel,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _categoryIcon(String category) {
    final value = category.toLowerCase();

    if (value.contains('pharmacy') || value.contains('medical')) {
      return Icons.local_pharmacy_outlined;
    }
    if (value.contains('hospital') || value.contains('health')) {
      return Icons.local_hospital_outlined;
    }
    if (value.contains('food') ||
        value.contains('restaurant') ||
        value.contains('cafe') ||
        value.contains('tea')) {
      return Icons.restaurant_outlined;
    }
    return Icons.storefront_outlined;
  }
Widget _buildDestinationSearch() {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFF493263)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Where do you want to go?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        TextField(
          controller: _destinationController,
          onChanged: _onDestinationChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search destination...',
            hintStyle: const TextStyle(color: muted),
            prefixIcon: const Icon(
              Icons.search,
              color: teal,
            ),
            suffixIcon: _destinationController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: muted),
                    onPressed: () {
                      _destinationController.clear();
                      setState(() {
                        _selectedDestination = null;
                        _destinationSuggestions = [];
                        _searchError = null;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        if (_searchLoading) ...[
          const SizedBox(height: 10),
          const LinearProgressIndicator(color: teal),
        ],

        if (_searchError != null) ...[
          const SizedBox(height: 8),
          Text(
            _searchError!,
            style: const TextStyle(color: coral, fontSize: 12),
          ),
        ],

        if (_destinationSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          ..._destinationSuggestions.map((destination) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.location_on_outlined,
                color: teal,
              ),
              title: Text(
                destination['name']?.toString() ?? 'Unknown place',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                destination['address']?.toString() ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: muted, fontSize: 11),
              ),
              onTap: () => _selectDestination(destination),
            );
          }),
        ],

        if (_selectedDestination != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle, color: teal, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Destination selected: '
                  '${_selectedDestination!['name']}',
                  style: const TextStyle(color: teal, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}
  Widget _buildNearbyPlaces() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFF493263)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nearby places',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Places found within 1 km',
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: _categories.entries.map((entry) {
              final selected = _category == entry.key;
              return ChoiceChip(
                label: Text(entry.value),
                selected: selected,
                onSelected: _placesLoading
                    ? null
                    : (_) => _loadNearbyPlaces(category: entry.key),
                selectedColor: teal,
                backgroundColor: bg,
                labelStyle: TextStyle(
                  color: selected ? bg : Colors.white,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (_placesLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: teal),
              ),
            )
          else if (_placesError != null)
            Column(
              children: [
                Text(
                  _placesError!,
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _loadNearbyPlaces(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            )
          else if (_places.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No places found in this search.',
                style: TextStyle(color: muted),
              ),
            )
          else ...[
            Text(
              '${_places.length} places found',
              style: const TextStyle(
                color: teal,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            ..._places.map((place) {
              final name = place['name']?.toString() ?? 'Unnamed place';
              final address =
                  place['address']?.toString() ?? 'Address unavailable';
              final distance = place['distance'];
              final categories = place['categories'];

              final distanceText = distance is num
                  ? distance >= 1000
                      ? '${(distance / 1000).toStringAsFixed(1)} km away'
                      : '${distance.round()} m away'
                  : 'Distance unavailable';

              final categoryText = categories is List
                  ? categories.map((e) => e.toString()).join(', ')
                  : 'Place';

              final phone = place['phone']?.toString();
              final website = place['website']?.toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _categoryIcon(categoryText),
                      color: teal,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            categoryText,
                            style: const TextStyle(
                              color: teal,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            distanceText,
                            style: const TextStyle(
                              color: muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            address,
                            style: const TextStyle(
                              color: muted,
                              fontSize: 11,
                            ),
                          ),
                          if (phone != null &&
                              phone.isNotEmpty &&
                              phone != 'null') ...[
                            const SizedBox(height: 5),
                            Text(
                              'Phone: $phone',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          if (website != null &&
                              website.isNotEmpty &&
                              website != 'null') ...[
                            const SizedBox(height: 3),
                            Text(
                              'Website: $website',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: teal,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

 
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: bg,
    appBar: AppBar(
      backgroundColor: bg,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text('Safe Route'),
    ),
    body: AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        final routes = _viewModel.routes;
        final selected = _viewModel.selectedRoute;

        final routePoints = selected?.coordinates
                .map((point) => LatLng(point[0], point[1]))
                .toList() ??
            <LatLng>[];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildDestinationSearch(),
            const SizedBox(height: 16),

            if (_viewModel.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: teal),
                ),
              ),

            if (_viewModel.errorMessage != null)
              Text(
                _viewModel.errorMessage!,
                style: const TextStyle(color: coral),
              ),

            if (!_viewModel.isLoading &&
                routes.isEmpty &&
                _selectedDestination == null)
              const Text(
                'Search and select a destination to find a route.',
                style: TextStyle(color: muted),
              ),

            if (routes.isNotEmpty && selected != null) ...[
              const Text(
                'Route options',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: routes.map((route) {
                  final isSelected = route.id == selected.id;
                  return ChoiceChip(
                    label: Text(
                      '${route.title} · ${route.durationMinutes} min',
                    ),
                    selected: isSelected,
                    onSelected: (_) => _viewModel.selectRoute(route.id),
                    selectedColor: teal,
                    backgroundColor: panel,
                    labelStyle: TextStyle(
                      color: isSelected ? bg : Colors.white,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              RouteMapCard(
                fastest: false,
                points: routePoints,
              ),

              const SizedBox(height: 12),

              Text(
                '${selected.durationMinutes} min · '
                '${selected.distanceKm.toStringAsFixed(2)} km',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),
              Text(
                selected.description,
                style: const TextStyle(color: muted),
              ),
            ],

            const SizedBox(height: 16),
            _buildNearbyPlaces(),
          ],
        );
      },
    ),
  );
}

}
