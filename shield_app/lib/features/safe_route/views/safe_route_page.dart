import 'package:flutter/material.dart';

import '../widgets/route_map_card.dart';
import '../repositories/demo_safe_route_repository.dart';
import '../viewmodels/safe_route_viewmodel.dart';

class SafeRoutePage extends StatefulWidget {
  const SafeRoutePage({super.key});

  @override
  State<SafeRoutePage> createState() => _SafeRoutePageState();
}

class _SafeRoutePageState extends State<SafeRoutePage> {
  static const bg = Color(0xFF130B20);
  static const panel = Color(0xFF211532);
  static const violet = Color(0xFF8955E8);
  static const teal = Color(0xFF14B8A6);
  static const coral = Color(0xFFFF4D6A);
  static const muted = Color(0xFFB9A9D0);

  late final SafeRouteViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SafeRouteViewModel(DemoSafeRouteRepository());
    _viewModel.loadRoutes();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
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
              child: Text(
                _viewModel.errorMessage!,
                style: const TextStyle(color: Colors.white),
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

          final fastest = selected.id == 'route_2';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Safe route',
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

              // Safest / Fastest selector.
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF090610),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    _routeChoice(
                      '♧  Safest',
                      selected: !fastest,
                      onTap: () => _viewModel.selectRoute('route_1'),
                    ),
                    _routeChoice(
                      'ϟ  Fastest',
                      selected: fastest,
                      onTap: () => _viewModel.selectRoute('route_2'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              RouteMapCard(fastest: fastest),
              const SizedBox(height: 12),

              // Route details.
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
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${selected.durationMinutes} min · '
                                '${selected.distanceKm} km',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selected.description,
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '—',
                              style: TextStyle(
                                color: teal,
                                fontSize: 27,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'safety score',
                              style: TextStyle(
                                color: muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Wrap(
                      spacing: 6,
                      runSpacing: 7,
                      children: [
                        _InfoChip('💡 Well lit'),
                        _InfoChip('🏪 Open shops'),
                        _InfoChip('▦ CCTV'),
                        _InfoChip('👥 Crowded'),
                        _InfoChip('✓ Community reports'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Illustrative labels only. Verified safety data '
                      'is not connected yet.',
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Demo actions; no location is shared and no report is sent.
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _showMessage(
                        'Demo only — live location is not being shared.',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: teal,
                        foregroundColor: bg,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: const Icon(Icons.share_location_rounded),
                      label: const Text('Start live share'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showMessage(
                      'Reporting is not connected yet.',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: coral,
                      side: const BorderSide(color: coral),
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                        horizontal: 10,
                      ),
                    ),
                    icon: const Icon(Icons.flag_outlined, size: 17),
                    label: const Text('Report'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Demo interface · No live navigation or emergency sharing.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 10),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _routeChoice(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2A1A40) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? const Color(0xFFB58BFF) : muted,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF30213F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFDCD0EC),
          fontSize: 10,
        ),
      ),
    );
  }
}
