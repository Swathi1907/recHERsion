
enum EvidenceType {
  audio,
  video,
  photo,
  note,
}

class EvidenceItem {
  const EvidenceItem({
    required this.id,
    required this.title,
    required this.type,
    required this.createdAt,
    this.sha256,
    this.isVerified = false,
  });

  final String id;
  final String title;
  final EvidenceType type;
  final DateTime createdAt;
  final String? sha256;
  final bool isVerified;
}
