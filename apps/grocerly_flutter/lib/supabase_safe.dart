import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

bool get supabaseConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

SupabaseClient? get supaClientOrNull => supabaseConfigured ? Supabase.instance.client : null;

