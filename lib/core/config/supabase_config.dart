class SupabaseConfig {
    // Pass these via --dart-define or --dart-define-from-file=secrets.local.json
    static const String supabaseUrl = String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: '',
    );
    static const String supabaseAnonKey = String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: '',
    );
  // Deep link configuration for OAuth callback
  // For Android: com.example.thespace://login-callback/
  // For iOS: com.example.thespace://login-callback/
  // static const String redirectUrl = 'com.example.thespace://login-callback/';
  // Google Web Client ID (required for native sign-in to get ID token)
  // This is the SAME Web Client ID you entered in Supabase Dashboard
  // Get it from: Google Cloud Console > Credentials > OAuth 2.0 Client IDs > Web client
    static const String googleWebClientId = String.fromEnvironment(
        'GOOGLE_WEB_CLIENT_ID',
        defaultValue: '',
    );

    static void validate() {
        if (supabaseUrl.isEmpty ||
                supabaseAnonKey.isEmpty ||
                googleWebClientId.isEmpty) {
            throw StateError(
                'Missing required secrets. Provide SUPABASE_URL, SUPABASE_ANON_KEY, '
                'and GOOGLE_WEB_CLIENT_ID using --dart-define or '
                '--dart-define-from-file=secrets.local.json.',
            );
        }
    }
}
