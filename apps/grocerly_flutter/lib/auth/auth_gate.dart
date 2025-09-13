import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_safe.dart';
import 'auth_screen.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    // Rebuild on auth state changes.
    if (supabaseConfigured) {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!supabaseConfigured) {
      // Guest mode when Supabase isn’t configured.
      return Banner(
        message: 'Supabase not configured',
        location: BannerLocation.topEnd,
        child: widget.child,
      );
    }
    final session = Supabase.instance.client.auth.currentSession;
    return session == null ? const AuthScreen() : widget.child;
  }
}
