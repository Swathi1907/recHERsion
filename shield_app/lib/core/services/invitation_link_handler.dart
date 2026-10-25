
import 'package:flutter/material.dart';

import 'invitation_link_service.dart';

class InvitationLinkHandler extends StatefulWidget {
  const InvitationLinkHandler({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<InvitationLinkHandler> createState() =>
      _InvitationLinkHandlerState();
}

class _InvitationLinkHandlerState
    extends State<InvitationLinkHandler> {
  @override
  void initState() {
    super.initState();

    InvitationLinkService.listen(
      onInvitationToken: _handleToken,
    );

    _checkInitialLink();
  }

  Future<void> _checkInitialLink() async {
    final link = await InvitationLinkService.getInitialLink();
    final token = InvitationLinkService.tokenFromLink(link);

    if (token != null) {
      _handleToken(token);
    }
  }

  void _handleToken(String token) {
    if (!mounted) return;

    // Temporary confirmation. Next, we'll pass the token
    // to the authenticated invitation-acceptance screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitation link received by SHIELD.'),
        ),
      );

      debugPrint('SHIELD: Invitation token received');
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
