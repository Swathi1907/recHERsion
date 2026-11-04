
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../authenticated_home.dart';
import 'login_page.dart';
import '../../trusted_contacts/views/accept_invitation_page.dart';
import '../../../core/services/invitation_link_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;

        if (session == null) {
          return const LoginPage();
        }

        return ValueListenableBuilder<String?>(
          valueListenable: InvitationLinkService.pendingToken,
          builder: (context, token, child) {
            if (token != null && token.isNotEmpty) {
              return AcceptInvitationPage(token: token);
            }

            return const AuthenticatedHome();
          },
        );
      },
    );
  }
}
