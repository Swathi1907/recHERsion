
class TrustedContact {
  const TrustedContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String relationship;
  final DateTime? createdAt;

  factory TrustedContact.fromJson(Map<String, dynamic> json) {
    return TrustedContact(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      relationship: json['relationship'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'relationship': relationship,
      };
}
