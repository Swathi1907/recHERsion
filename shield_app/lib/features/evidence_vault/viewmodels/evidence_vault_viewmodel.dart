
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
      debugPrint('EVIDENCE VM: Loading evidence...');
      _items = await _repository.getEvidence();
      debugPrint('EVIDENCE VM: Loaded ${_items.length} items');
    } catch (error, stackTrace) {
      _errorMessage = error.toString();
      debugPrint('EVIDENCE VM LOAD ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleDisguiseMode(bool enabled) {
    _disguiseMode = enabled;
    notifyListeners();
  }
Future<void> uploadEvidenceFile({
  required String filePath,
  required String title,
  required EvidenceType type,
  String? description,
}) async {
  await _repository.uploadEvidenceFile(
    filePath: filePath,
    title: title,
    type: type,
    description: description,
  );

  await loadEvidence();

  if (_errorMessage != null) {
    throw Exception(
      'Upload succeeded, but evidence list refresh failed: $_errorMessage',
    );
  }
}
  Future<void> addNote(String title, String content) async {
    final cleanTitle = title.trim();
    final cleanContent = content.trim();

    if (cleanTitle.isEmpty || cleanContent.isEmpty) {
      throw ArgumentError('Please enter both a title and a note.');
    }

    final item = EvidenceItem(
      id: '',
      title: cleanTitle,
      type: EvidenceType.note,
      createdAt: DateTime.now(),
      description: cleanContent,
    );

    try {
      debugPrint('EVIDENCE VM: Saving note "$cleanTitle"');
      await _repository.addEvidence(item);
      debugPrint('EVIDENCE VM: Note saved. Reloading evidence...');
      await loadEvidence();

      if (_errorMessage != null) {
        throw Exception(
          'Note was saved, but the list could not refresh: $_errorMessage',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('EVIDENCE VM SAVE ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
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
