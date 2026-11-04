
import 'package:flutter/material.dart';

import '../repositories/api_trusted_contacts_repository.dart';
import '../../../core/services/invitation_link_service.dart';
import '../../auth/authenticated_home.dart';

class AcceptInvitationPage extends StatefulWidget {
  const AcceptInvitationPage({
    super.key,
    required this.token,
  });

  final String token;

  @override
  State<AcceptInvitationPage> createState() =>
      _AcceptInvitationPageState();
}

class _AcceptInvitationPageState
    extends State<AcceptInvitationPage> {
  late final ApiTrustedContactsRepository _repository;

  bool _loading = false;
  bool _accepted = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _repository = ApiTrustedContactsRepository(
      baseUrl: 'http://172.22.21.254:3000',
    );
  }

  Future<void> _acceptInvitation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _repository.acceptInvitation(widget.token);

      // Clear the token only after successful acceptance.
      InvitationLinkService.consumePendingToken();

      if (!mounted) return;

      setState(() {
        _accepted = true;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }
void _continueToHome() {
  InvitationLinkService.consumePendingToken();

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => const AuthenticatedHome(),
    ),
    (route) => false,
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SHIELD Invitation'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _accepted
                    ? Icons.verified_user_rounded
                    : Icons.shield_rounded,
                size: 64,
                color: _accepted
                    ? Colors.green
                    : const Color(0xFF6C3FC5),
              ),
              const SizedBox(height: 20),
              Text(
                _accepted
                    ? 'Invitation accepted!'
                    : 'You are invited to SHIELD',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _accepted
                    ? 'You are now linked as a trusted contact.'
                    : 'Accept this invitation to join the sender’s trusted safety circle.',
                textAlign: TextAlign.center,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              if (!_accepted)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _acceptInvitation,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Accept invitation'),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _continueToHome,
                    child: const Text('Continue'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
