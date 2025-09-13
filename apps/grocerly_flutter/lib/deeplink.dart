import 'dart:async';
import 'package:uni_links/uni_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';
import 'supabase_safe.dart';

class DeepLinkAuthHandler {
  static final DeepLinkAuthHandler _instance = DeepLinkAuthHandler._();
  factory DeepLinkAuthHandler() => _instance;
  DeepLinkAuthHandler._();

  StreamSubscription? _sub;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || !supabaseConfigured) return;
    _initialized = true;

    // Handle initial link if app was launched via link.
    try {
      final initial = await getInitialUri();
      if (initial != null) {
        await _handle(initial);
      }
    } catch (_) {
      // Ignore malformed initial URIs.
    }

    // Handle subsequent links.
    _sub = uriLinkStream.listen((uri) async {
      if (uri != null) {
        await _handle(uri);
      }
    }, onError: (_) {});
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _initialized = false;
  }

  Future<void> _handle(Uri uri) async {
    if (!supabaseConfigured) return;
    // If scheme/host defined, filter to expected auth callback.
    if (deepLinkScheme.isNotEmpty && uri.scheme != deepLinkScheme) return;
    if (deepLinkHost.isNotEmpty && uri.host != deepLinkHost) return;
    try {
      // Let Supabase parse and set the session from the URL (hash or query).
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    } catch (_) {
      // No-op if the URL isn't an auth callback.
    }
  }
}

