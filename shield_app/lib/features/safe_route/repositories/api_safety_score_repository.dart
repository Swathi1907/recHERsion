
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../repositories/api_safety_score_repository.dart';
import '../viewmodels/safety_score_viewmodel.dart';
import '../models/safety_score.dart';
import 'safety_score_repository.dart';

class ApiSafetyScoreRepository implements SafetyScoreRepository {
  ApiSafetyScoreRepository({required this.baseUrl});

  final String baseUrl;

  @override
  Future<SafetyScore> getSafetyScore() async {
    final uri = Uri.parse('$baseUrl/api/safety/score');

    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
        'Safety score API failed (${response.statusCode}): '
        '${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return SafetyScore.fromJson(data);
  }
}
