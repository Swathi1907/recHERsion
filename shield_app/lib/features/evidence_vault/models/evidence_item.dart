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
    this.description,
    this.sha256,
    this.isVerified = false,
  });

  final String id;
  final String title;
  final EvidenceType type;
  final DateTime createdAt;
  final String? description;
  final String? sha256;
  final bool isVerified;

  factory EvidenceItem.fromJson(Map<String, dynamic> json) {
    return EvidenceItem(
      id: json['id'].toString(),
      title: json['title'] as String,
      type: EvidenceType.values.firstWhere(
        (type) => type.name == json['evidence_type'],
        orElse: () => EvidenceType.note,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      description: json['description'] as String?,
      sha256: json['sha256'] as String?,
      isVerified: json['verification_status'] == 'verified',
    );
  }
}