
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class SosService {
  static const String baseUrl = 'http://172.22.21.45:3000';

  static Future<Map<String, dynamic>> createAlert({
    required String senderName,
    String? senderPhone,
    double? latitude,
    double? longitude,
    String? message,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      throw Exception('Please log in before sending SOS.');
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/api/sos'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${session.accessToken}',
          },
          body: jsonEncode({
            'sender_name': senderName,
            'sender_phone': senderPhone,
            'latitude': latitude,
            'longitude': longitude,
            'message': message ?? 'Emergency! I need help.',
          }),
        )
        .timeout(const Duration(seconds: 15));

    final result = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201 || result['success'] != true) {
      throw Exception(
        result['error']?.toString() ?? 'SOS request failed.',
      );
    }

    return result;
  }
}
