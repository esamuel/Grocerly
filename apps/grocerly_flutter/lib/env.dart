// Environment placeholders for Supabase.
// Provide via --dart-define at build/run time, e.g.:
// flutter run \
//   --dart-define=SUPABASE_URL=https://xyz.supabase.co \
//   --dart-define=SUPABASE_ANON_KEY=your_anon_key

const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

// Deep linking configuration (scheme and host) for auth redirects.
// Example: grocerly://auth-callback
const String deepLinkScheme = String.fromEnvironment('DEEP_LINK_SCHEME', defaultValue: '');
const String deepLinkHost = String.fromEnvironment('DEEP_LINK_HOST', defaultValue: '');
