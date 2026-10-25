
class EmergencyAlert {
  final String id;
  final String senderName;
  final String senderPhone;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  final String? message;

  const EmergencyAlert({
    required this.id,
    required this.senderName,
    required this.senderPhone,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.message,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      id: json['id'] as String,
      senderName: json['sender_name'] as String,
      senderPhone: json['sender_phone'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      message: json['message'] as String?,
    );
  }
}
