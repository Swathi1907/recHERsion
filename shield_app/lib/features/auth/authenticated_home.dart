
import 'package:flutter/material.dart';

import '../../../main.dart';
import '../sos/services/fcm_registration_service.dart';

class AuthenticatedHome extends StatefulWidget {
  const AuthenticatedHome({super.key});

  @override
  State<AuthenticatedHome> createState() => _AuthenticatedHomeState();
}

class _AuthenticatedHomeState extends State<AuthenticatedHome> {
  @override
  void initState() {
    super.initState();
    _registerFcmToken();
  }

  Future<void> _registerFcmToken() async {
    try {
      await FcmRegistrationService.registerDevice();
    } catch (error, stackTrace) {
      debugPrint('SHIELD: FCM registration failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const ShieldHomePage();
  }
}
