
import 'package:flutter/foundation.dart';

import '../models/safety_score.dart';
import '../repositories/safety_score_repository.dart';

class SafetyScoreViewModel extends ChangeNotifier {
  final SafetyScoreRepository _repository;

  SafetyScoreViewModel(this._repository);

  SafetyScore? _safetyScore;
  bool _isLoading = false;
  String? _errorMessage;

  SafetyScore? get safetyScore => _safetyScore;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSafetyScore() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _safetyScore = await _repository.getSafetyScore();
    } catch (error) {
      _errorMessage = 'Could not load safety information.';
      debugPrint('[SafetyScoreViewModel] $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
