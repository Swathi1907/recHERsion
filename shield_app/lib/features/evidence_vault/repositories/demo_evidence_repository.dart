
import '../models/evidence_item.dart';
import 'evidence_repository.dart';

class DemoEvidenceRepository implements EvidenceRepository {
  final List<EvidenceItem> _items = [
    EvidenceItem(
      id: 'demo-1',
      title: 'Threatening chat',
      type: EvidenceType.photo,
      createdAt: DateTime(2026, 10, 23, 21, 12),
    ),
    EvidenceItem(
      id: 'demo-2',
      title: 'Audio – bus stop',
      type: EvidenceType.audio,
      createdAt: DateTime(2026, 10, 21, 19, 48),
    ),
  ];

  @override
  Future<List<EvidenceItem>> getEvidence() async {
    return List.unmodifiable(_items);
  }

  @override
  Future<void> addEvidence(EvidenceItem item) async {
    _items.insert(0, item);
  }
    @override
  Future<void> uploadEvidenceFile({
    required String filePath,
    required String title,
    required EvidenceType type,
    String? description,
  }) async {
    throw UnimplementedError(
      'File uploads require ApiEvidenceRepository.',
    );
  }

}
