/// Supabase Configuration
///
/// To set up your Supabase project:
/// 1. Go to https://supabase.com/dashboard
/// 2. Create a new project or select an existing one
/// 3. Go to Settings > API
/// 4. Copy your Project URL and anon public key
/// 5. Replace the values below with your actual credentials
///
/// ⚠️ IMPORTANT: Never commit real credentials to version control
/// Consider using environment variables or a .env file for production

class SupabaseConfig {
  // Your actual Supabase project credentials
  static const String supabaseUrl = 'https://cuksebxpzgagisxlpshs.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN1a3NlYnhwemdhZ2lzeGxwc2hzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTczNTMxOTEsImV4cCI6MjA3MjkyOTE5MX0.UOmxqRxh_Dtv_PpLGteNTMLJfqWvNOQYOtdf6ejm7Nw';

  // Service role secret (only use server-side, never in client apps)
  static const String supabaseServiceRoleSecret =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN1a3NlYnhwemdhZ2lzeGxwc2hzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzM1MzE5MSwiZXhwIjoyMDcyOTI5MTkxfQ.nL2ZuJ8pZo2H6Nri_D0ShW7BOA6yonAI5xdkJKJd03U';

  // Optional: Enable debug mode for development
  static const bool debugMode = true;

  // App-specific configuration
  static const String appName = 'Pro Organizer';
  static const String appVersion = '2.0.0';

  // Deep link configuration for auth callbacks
  static const String authCallbackUrl =
      'io.supabase.flutterquickstart://login-callback/';
  static const String resetPasswordCallbackUrl =
      'io.supabase.flutterquickstart://reset-password-callback/';
}

/// Example of what your actual configuration should look like:
///
/// ```dart
/// class SupabaseConfig {
///   static const String supabaseUrl = 'https://abcdefghijklmnop.supabase.co';
///   static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
/// }
/// ```
