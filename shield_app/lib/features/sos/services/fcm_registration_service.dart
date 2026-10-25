
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class FcmRegistrationService {
  static const String baseUrl = 'http://172.22.21.45:3000';

  static bool _listeningForToken = false;

  static Future<void> registerDevice() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    final settings =
        await FirebaseMessaging.instance.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('SHIELD: Notification permission denied');
      return;
    }

    if (!_listeningForToken) {
      _listeningForToken = true;

      FirebaseMessaging.instance.onRegistered.listen((event) async {
        final currentSession =
            Supabase.instance.client.auth.currentSession;

        if (currentSession == null) return;

        try {
          await _sendToken(event, currentSession.accessToken);
          debugPrint('SHIELD: FCM device token registered');
        } catch (error, stackTrace) {
          debugPrint('SHIELD: FCM registration failed: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      });
    }

    await FirebaseMessaging.instance.register();
  }

  static Future<void> _sendToken(
    String token,
    String accessToken,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/device-tokens'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'fcm_token': token,
        'platform': 'android',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'FCM registration failed: '
        '${response.statusCode} ${response.body}',
      );
    }

    debugPrint('SHIELD: Token accepted by backend');
  }
}
