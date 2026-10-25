
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/trusted_contact.dart';

class ApiTrustedContactsRepository {
  ApiTrustedContactsRepository({required this.baseUrl});

  final String baseUrl;

  Map<String, String> _headers() {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      throw Exception('Please log in to manage trusted contacts.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${session.accessToken}',
    };
  }

  Future<List<TrustedContact>> getContacts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/trusted-contacts'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Could not load contacts (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);
    final rows = decoded['data'] as List<dynamic>;

    return rows
        .map(
          (row) => TrustedContact.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<TrustedContact> addContact({
    required String name,
    required String phone,
    required String relationship,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/trusted-contacts'),
      headers: _headers(),
      body: jsonEncode({
        'name': name.trim(),
        'phone': phone.trim(),
        'relationship': relationship.trim(),
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Could not save contact (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    return TrustedContact.fromJson(
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }

  Future<void> deleteContact(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/trusted-contacts/$id'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Could not delete contact (${response.statusCode}).');
    }
  }
}
