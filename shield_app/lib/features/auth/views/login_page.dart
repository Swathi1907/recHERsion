
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSignup = false;
  bool _loading = false;

 
Future<void> _submit() async {
  if (_email.text.trim().isEmpty || _password.text.isEmpty) {
    _message('Enter your email and password.');
    return;
  }

  FocusScope.of(context).unfocus();
  setState(() => _loading = true);

  try {
    debugPrint('SHIELD AUTH: Request started');
    final auth = Supabase.instance.client.auth;

    if (_isSignup) {
      debugPrint('SHIELD AUTH: Signup started');

      final response = await auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
         emailRedirectTo: 'shieldapp://login-callback/',
      ).timeout(const Duration(seconds: 20));

      debugPrint('SHIELD AUTH: Signup response received');

      if (response.session == null) {
        _message('Account created. Check your email to confirm, then log in.');
      } else {
        _message('Account created successfully.');
      }
    } else {
      debugPrint('SHIELD AUTH: Login started');

      await auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      ).timeout(const Duration(seconds: 20));

      debugPrint('SHIELD AUTH: Login response received');
      _message('Login successful.');
    }
  } on AuthException catch (e) {
    debugPrint('SHIELD AUTH ERROR: ${e.message}');
    _message(e.message);
  } catch (e, stackTrace) {
    debugPrint('SHIELD AUTH ERROR: $e');
    debugPrintStack(stackTrace: stackTrace);
    _message('Authentication failed: $e');
  } finally {
    if (mounted) {
      setState(() => _loading = false);
    }
  }
}


  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.shield_rounded, size: 64,
                    color: Color(0xFF6C3FC5)),
                const SizedBox(height: 16),
                const Text(
                  'SHIELD',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                Text(
                  _isSignup ? 'Create your account' : 'Welcome back',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: Text(_loading
                      ? 'Please wait...'
                      : _isSignup ? 'Sign up' : 'Log in'),
                ),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() => _isSignup = !_isSignup),
                  child: Text(_isSignup
                      ? 'Already have an account? Log in'
                      : 'New here? Create an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

