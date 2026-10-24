
import '../models/safety_score.dart';

abstract class SafetyScoreRepository {
  Future<SafetyScore> getSafetyScore();
}
