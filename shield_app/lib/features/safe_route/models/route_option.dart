
class RouteOption {
  final String id;
  final String title;
  final double distanceKm;
  final int durationMinutes;
  final String description;

  // Real route points stored as [latitude, longitude].
  final List<List<double>> coordinates;

  const RouteOption({
    required this.id,
    required this.title,
    required this.distanceKm,
    required this.durationMinutes,
    required this.description,
    this.coordinates = const [],
  });
}
