
class SafetyScore {
  final int? score;
  final String status;
  final int coveragePercent;
  final String message;

  const SafetyScore({
    required this.score,
    required this.status,
    required this.coveragePercent,
    required this.message,
  });

  factory SafetyScore.fromJson(Map<String, dynamic> json) {
    return SafetyScore(
      score: (json['score'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'unknown',
      coveragePercent:
          (json['coveragePercent'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ??
          'Insufficient verified safety data.',
    );
  }

  bool get hasScore => score != null;
}
