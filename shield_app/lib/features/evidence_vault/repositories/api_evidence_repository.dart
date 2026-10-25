
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http_parser/http_parser.dart';
import '../models/evidence_item.dart';
import 'evidence_repository.dart';

class ApiEvidenceRepository implements EvidenceRepository {
  ApiEvidenceRepository({required this.baseUrl});

  final String baseUrl;

  Future<Map<String, String>> _headers() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      throw Exception('Please log in to access your evidence.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${session.accessToken}',
    };
  }

  @override
  Future<List<EvidenceItem>> getEvidence() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/evidence'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load evidence: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> rows;

    if (decoded is List) {
      rows = decoded;
    } else if (decoded is Map<String, dynamic> &&
        decoded['data'] is List) {
      rows = decoded['data'] as List<dynamic>;
    } else if (decoded is Map<String, dynamic> &&
        decoded['items'] is List) {
      rows = decoded['items'] as List<dynamic>;
    } else {
      throw FormatException(
        'Unexpected evidence API response: ${response.body}',
      );
    }

    return rows
        .map(
          (row) => EvidenceItem.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  @override
  Future<void> addEvidence(EvidenceItem item) async {
    debugPrint('EVIDENCE API: Saving ${item.type.name}');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/evidence'),
        headers: await _headers(),
        body: jsonEncode({
          'title': item.title,
          'evidence_type': item.type.name,
          'description': item.description,
          'sha256': item.sha256,
          'captured_at': item.createdAt.toUtc().toIso8601String(),
        }),
      );

      debugPrint('EVIDENCE API: Status ${response.statusCode}');

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          'Failed to save evidence: '
          '${response.statusCode} ${response.body}',
        );
      }

      debugPrint('EVIDENCE API: Save successful');
    } catch (error, stackTrace) {
      debugPrint('EVIDENCE API SAVE ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> uploadEvidenceFile({
    required String filePath,
    required String title,
    required EvidenceType type,
    String? description,
  }) async {
    if (type == EvidenceType.note) {
      throw ArgumentError('Use addEvidence() for notes.');
    }

    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw ArgumentError('Please enter a title.');
    }

    debugPrint('EVIDENCE UPLOAD: Starting ${type.name}');

    try {
      final session = Supabase.instance.client.auth.currentSession;

      if (session == null) {
        throw Exception('Please log in to upload evidence.');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/evidence/upload'),
      );

      request.headers['Authorization'] =
          'Bearer ${session.accessToken}';

      request.fields['title'] = cleanTitle;

      if (description != null && description.trim().isNotEmpty) {
        request.fields['description'] = description.trim();
      }

      // The backend expects the multipart field to be named "file".
    final extension = filePath.split('.').last.toLowerCase();

final mimeType = switch (extension) {
  'jpg' || 'jpeg' => 'image/jpeg',
  'png' => 'image/png',
  'webp' => 'image/webp',
  'mp4' => 'video/mp4',
  'webm' => type == EvidenceType.audio
      ? 'audio/webm'
      : 'video/webm',
  'mov' => 'video/quicktime',
  'mp3' => 'audio/mpeg',
  'wav' => 'audio/wav',
  'm4a' => 'audio/mp4',
  _ => 'application/octet-stream',
};

request.files.add(
  await http.MultipartFile.fromPath(
    'file',
    filePath,
    contentType: MediaType.parse(mimeType),
  ),
);

      debugPrint('EVIDENCE UPLOAD: Sending request');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('EVIDENCE UPLOAD: Status ${response.statusCode}');
      debugPrint('EVIDENCE UPLOAD: Response ${response.body}');

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          'Upload failed: ${response.statusCode} ${response.body}',
        );
      }

      debugPrint('EVIDENCE UPLOAD: Successful');
    } catch (error, stackTrace) {
      debugPrint('EVIDENCE UPLOAD ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
