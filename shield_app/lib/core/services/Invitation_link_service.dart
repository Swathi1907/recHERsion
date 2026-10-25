
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class InvitationLinkService {
  static const _channel = MethodChannel('shield/invitation_links');

  static Future<String?> getInitialLink() async {
    try {
      return await _channel.invokeMethod<String>('getInitialLink');
    } on PlatformException catch (error) {
      debugPrint('Could not read invitation link: ${error.message}');
      return null;
    }
  }

  static void listen({
    required void Function(String token) onInvitationToken,
  }) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onInvitationLink') {
        final link = call.arguments as String?;
        if (link == null) return;

        final uri = Uri.tryParse(link);
        final token = uri?.queryParameters['token'];

        if (uri?.scheme == 'shield' &&
            uri?.host == 'invite' &&
            token != null &&
            token.isNotEmpty) {
          onInvitationToken(token);
        }
      }
    });
  }

  static String? tokenFromLink(String? link) {
    if (link == null) return null;

    final uri = Uri.tryParse(link);
    if (uri?.scheme != 'shield' || uri?.host != 'invite') {
      return null;
    }

    final token = uri?.queryParameters['token'];
    return token == null || token.isEmpty ? null : token;
  }
}
