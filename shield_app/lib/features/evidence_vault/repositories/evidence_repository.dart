
import '../models/evidence_item.dart';

abstract class EvidenceRepository {
  Future<List<EvidenceItem>> getEvidence();

  Future<void> addEvidence(EvidenceItem item);
}
