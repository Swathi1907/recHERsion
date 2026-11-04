
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class InvitationLinkService {
  static const _channel = MethodChannel('shield/invitation_links');

  static final ValueNotifier<String?> pendingToken =
      ValueNotifier<String?>(null);

  static void savePendingToken(String token) {
    pendingToken.value = token;
  }

  static String? consumePendingToken() {
    final token = pendingToken.value;
    pendingToken.value = null;
    return token;
  }

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
        final token = tokenFromLink(link);

        if (token != null) {
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
