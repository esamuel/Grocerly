import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_safe.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMagicLink() async {
    setState(() => _loading = true);
    try {
      final email = _emailCtrl.text.trim();
      if (email.isEmpty) throw Exception('Enter your email');
      if (!supabaseConfigured) throw Exception('Supabase not configured');
      await Supabase.instance.client.auth.signInWithOtp(email: email);
      setState(() => _message = 'Magic link sent. Check your email.');
    } catch (e) {
      setState(() => _message = 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _message = 'Enter your email first.');
      return;
    }
    final codeCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter email code'),
        content: TextField(
          controller: codeCtrl,
          decoration: const InputDecoration(hintText: '6-digit code'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Verify')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _loading = true);
    try {
      if (!supabaseConfigured) throw Exception('Supabase not configured');
      await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: codeCtrl.text.trim(),
        type: OtpType.email,
      );
      setState(() => _message = 'Signed in.');
    } catch (e) {
      setState(() => _message = 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grocerly — Sign in')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _sendMagicLink,
                      icon: const Icon(Icons.mail_outline),
                      label: const Text('Send Magic Link'),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : _verifyCode,
                      child: const Text('I have a code'),
                    ),
                  ),
                ]),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(_message!, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
