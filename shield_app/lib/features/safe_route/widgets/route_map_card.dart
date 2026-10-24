import 'package:flutter/material.dart';

class RouteMapCard extends StatelessWidget {
  final bool fastest;

  const RouteMapCard({
    super.key,
    required this.fastest,
  });

  static const _background = Color(0xFF0E0817);
  static const _road = Color(0xFF443064);
  static const _teal = Color(0xFF12C6B0);
  static const _amber = Color(0xFFFFB547);
  static const _violet = Color(0xFF8955E8);
  static const _coral = Color(0xFFFF4D6A);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF493263)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RouteMapPainter(
                fastest: fastest,
                roadColor: _road,
                routeColor: fastest ? _amber : _teal,
                startColor: _violet,
                endColor: _coral,
              ),
            ),
          ),
          const Positioned(
            top: 44,
            left: 34,
            child: _MapMarker(
              label: 'Dark zone',
              color: _coral,
            ),
          ),
          const Positioned(
            right: 34,
            bottom: 48,
            child: _MapMarker(
              label: 'Busy market',
              color: _teal,
            ),
          ),
          Positioned(
            left: 12,
            bottom: 10,
            child: Text(
              'ILLUSTRATIVE MAP · NOT LIVE',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 9,
                letterSpacing: 0.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final String label;
  final Color color;

  const _MapMarker({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  final bool fastest;
  final Color roadColor;
  final Color routeColor;
  final Color startColor;
  final Color endColor;

  _RouteMapPainter({
    required this.fastest,
    required this.roadColor,
    required this.routeColor,
    required this.startColor,
    required this.endColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = roadColor
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    // Decorative streets.
    for (final x in [0.18, 0.49, 0.80]) {
      canvas.drawLine(
        Offset(size.width * x, 8),
        Offset(size.width * x, size.height - 8),
        roadPaint,
      );
    }

    for (final y in [0.16, 0.43, 0.72]) {
      canvas.drawLine(
        Offset(8, size.height * y),
        Offset(size.width - 8, size.height * y),
        roadPaint,
      );
    }

    // Main route.
    final routePaint = Paint()
      ..color = routeColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final route = Path()
      ..moveTo(size.width * 0.18, size.height * 0.84);

    if (fastest) {
      route
        ..lineTo(size.width * 0.18, size.height * 0.43)
        ..lineTo(size.width * 0.80, size.height * 0.43)
        ..lineTo(size.width * 0.80, size.height * 0.16);
    } else {
      route
        ..lineTo(size.width * 0.49, size.height * 0.84)
        ..lineTo(size.width * 0.49, size.height * 0.43)
        ..lineTo(size.width * 0.80, size.height * 0.43)
        ..lineTo(size.width * 0.80, size.height * 0.16);
    }

    canvas.drawPath(route, routePaint);

    // Start and destination markers.
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.84),
      6,
      Paint()..color = startColor,
    );

    canvas.drawCircle(
      Offset(size.width * 0.80, size.height * 0.16),
      6,
      Paint()..color = endColor,
    );
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter oldDelegate) {
    return oldDelegate.fastest != fastest ||
        oldDelegate.routeColor != routeColor;
  }
}
