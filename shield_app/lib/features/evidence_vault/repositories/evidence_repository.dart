import '../models/evidence_item.dart';

abstract class EvidenceRepository {
  Future<List<EvidenceItem>> getEvidence();

  Future<void> addEvidence(EvidenceItem item);

  Future<void> uploadEvidenceFile({
    required String filePath,
    required String title,
    required EvidenceType type,
    String? description,
  });
}