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

import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Your actual Supabase project credentials from environment
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://sgbrkvaphpimvgeyrxhd.supabase.co';
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ??
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNnYnJrdmFwaHBpbXZnZXlyeGhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc0Mzc3MjksImV4cCI6MjA3MzAxMzcyOX0.RpoxbzINEL66M9NPeVorL0NeLOspRuM-rM-HeARoooA';

  // Service role secret (only use server-side, never in client apps)
  static String get supabaseServiceRoleSecret =>
      dotenv.env['SUPABASE_SERVICE_ROLE_SECRET'] ??
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNnYnJrdmFwaHBpbXZnZXlyeGhkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzQzNzcyOSwiZXhwIjoyMDczMDEzNzI5fQ.rXSvp3kVR3dDwZ8xMRc3B-MtCerYa_TqTpRN2HL-0_8';

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
