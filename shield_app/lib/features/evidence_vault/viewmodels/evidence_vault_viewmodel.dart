
import 'package:flutter/foundation.dart';

import '../models/evidence_item.dart';
import '../repositories/evidence_repository.dart';

class EvidenceVaultViewModel extends ChangeNotifier {
  EvidenceVaultViewModel(this._repository);

  final EvidenceRepository _repository;

  List<EvidenceItem> _items = [];
  bool _isLoading = false;
  bool _disguiseMode = false;
  String? _errorMessage;

  List<EvidenceItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get disguiseMode => _disguiseMode;
  String? get errorMessage => _errorMessage;

  Future<void> loadEvidence() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _repository.getEvidence();
    } catch (error, stackTrace) {
      _errorMessage = 'Could not load evidence. Please try again.';
      debugPrint('Evidence loading failed: $error\n$stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleDisguiseMode(bool enabled) {
    _disguiseMode = enabled;
    notifyListeners();
  }

  Future<void> addNote(String title, String content) async {
    final cleanTitle = title.trim();
    final cleanContent = content.trim();

    if (cleanTitle.isEmpty || cleanContent.isEmpty) {
      throw ArgumentError('Please enter both a title and a note.');
    }

    // This demo only retains metadata, not the note body.
    final item = EvidenceItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: cleanTitle,
      type: EvidenceType.note,
      createdAt: DateTime.now(),
    );

    await _repository.addEvidence(item);
    await loadEvidence();
  }

  String buildCasePackPreview() {
    final buffer = StringBuffer()
      ..writeln('SHIELD — CASE PACK PREVIEW')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln('Evidence items: ${_items.length}')
      ..writeln();

    for (final item in _items) {
      buffer
        ..writeln('Title: ${item.title}')
        ..writeln('Type: ${item.type.name}')
        ..writeln('Date: ${item.createdAt.toIso8601String()}')
        ..writeln('SHA-256: ${item.sha256 ?? "Not available"}')
        ..writeln(
          'Integrity: ${item.isVerified ? "Verified" : "Not verified"}',
        )
        ..writeln();
    }

    return buffer.toString();
  }
}
