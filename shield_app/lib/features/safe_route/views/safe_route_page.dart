
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../widgets/route_map_card.dart';
import '../repositories/api_safe_route_repository.dart';
import '../repositories/api_safety_score_repository.dart';
import '../viewmodels/safe_route_viewmodel.dart';
import '../viewmodels/safety_score_viewmodel.dart';

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

  static const baseUrl = 'http://172.22.20.117:3000';

  // Temporary coordinates: replace with phone GPS in the next step.
  static const double latitude = 23.7957;
  static const double longitude = 86.4304;

  late final SafeRouteViewModel _viewModel;
  late final SafetyScoreViewModel _safetyViewModel;

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

    _safetyViewModel = SafetyScoreViewModel(
      ApiSafetyScoreRepository(baseUrl: baseUrl),
    );

    _viewModel.loadRoutes();
    _safetyViewModel.loadSafetyScore();
    _loadNearbyPlaces();
  }

  @override
  void dispose() {
    _safetyViewModel.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _loadNearbyPlaces({String? category}) async {
    final requestedCategory = category ?? _category;

    setState(() {
      _placesLoading = true;
      _placesError = null;
    });

    try {
      final uri = Uri.parse('$baseUrl/api/places/nearby').replace(
        queryParameters: {
          'latitude': '$latitude',
          'longitude': '$longitude',
          'radiusMeters': '1000',
          'category': requestedCategory,
        },
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Request failed (${response.statusCode})');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['places'] as List<dynamic>? ?? [];

      final places = results
          .whereType<Map<String, dynamic>>()
          .toList();

      if (!mounted) return;

      setState(() {
        _category = requestedCategory;
        _places = places;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _placesError =
            'Could not load nearby places. Check your connection and retry.';
      });

      debugPrint('[Nearby Places] $error');
    } finally {
      if (mounted) {
        setState(() => _placesLoading = false);
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
              final openNow = place['openNow'] as bool?;
              final hoursDisplay = place['hoursDisplay']?.toString();

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
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(
                                openNow == true
                                    ? Icons.check_circle
                                    : openNow == false
                                        ? Icons.cancel
                                        : Icons.access_time,
                                size: 15,
                                color: openNow == true
                                    ? Colors.greenAccent
                                    : openNow == false
                                        ? coral
                                        : muted,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  openNow == true
                                      ? 'Open now'
                                      : openNow == false
                                          ? 'Closed now'
                                          : 'Hours unavailable',
                                  style: TextStyle(
                                    color: openNow == true
                                        ? Colors.greenAccent
                                        : openNow == false
                                            ? coral
                                            : muted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (hoursDisplay != null &&
                              hoursDisplay.isNotEmpty &&
                              hoursDisplay != 'null') ...[
                            const SizedBox(height: 3),
                            Text(
                              hoursDisplay,
                              style: const TextStyle(
                                color: muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
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
          if (_viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: teal),
            );
          }

          if (_viewModel.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _viewModel.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _viewModel.loadRoutes,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final routes = _viewModel.routes;
          final selected = _viewModel.selectedRoute;

          if (routes.isEmpty || selected == null) {
            return const Center(
              child: Text(
                'No routes available',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final routePoints = selected.coordinates
              .map((point) => LatLng(point[0], point[1]))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Route options',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Hirapur Bus Stand → Bank More',
                style: TextStyle(color: muted, fontSize: 12),
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

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: const Color(0xFF493263)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selected.durationMinutes} min · '
                      '${selected.distanceKm.toStringAsFixed(2)} km',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selected.description,
                      style: const TextStyle(color: muted, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    AnimatedBuilder(
                      animation: _safetyViewModel,
                      builder: (context, child) {
                        if (_safetyViewModel.isLoading) {
                          return const Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: teal,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Loading safety information...',
                                style: TextStyle(color: muted, fontSize: 12),
                              ),
                            ],
                          );
                        }

                        if (_safetyViewModel.errorMessage != null) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Safety information unavailable',
                                style: TextStyle(
                                  color: coral,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _safetyViewModel.errorMessage!,
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 11,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _safetyViewModel.loadSafetyScore,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Retry'),
                                style: TextButton.styleFrom(
                                  foregroundColor: teal,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          );
                        }

                        final safety = _safetyViewModel.safetyScore;

                        if (safety == null || !safety.hasScore) {
                          return const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Safety score unavailable',
                                style: TextStyle(
                                  color: coral,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Verified safety indicators are not available '
                                'yet. This route is not safety-rated.',
                                style: TextStyle(color: muted, fontSize: 11),
                              ),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Provisional safety indicator score: '
                              '${safety.score}/100',
                              style: const TextStyle(
                                color: teal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${safety.coveragePercent}% indicator coverage. '
                              '${safety.message}',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _buildNearbyPlaces(),

              const SizedBox(height: 12),

              FilledButton.icon(
                onPressed: () => _showMessage(
                  'Live location sharing is not implemented yet.',
                ),
                icon: const Icon(Icons.share_location_rounded),
                label: const Text('Start live share'),
                style: FilledButton.styleFrom(
                  backgroundColor: teal,
                  foregroundColor: bg,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
              const SizedBox(height: 8),

              OutlinedButton.icon(
                onPressed: () => _showMessage(
                  'Reporting is not connected yet.',
                ),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Report'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: coral,
                  side: const BorderSide(color: coral),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
              const SizedBox(height: 10),

              const Text(
                'Estimated driving route · Not emergency navigation',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 10),
              ),
            ],
          );
        },
      ),
    );
  }
}
