import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../config/supabase_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Supabase client
  SupabaseClient get client => Supabase.instance.client;

  // Auth helpers
  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  String? get userId => currentUser?.id;

  // Connection status
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize Supabase with your project credentials
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    try {
      debugPrint('🔄 Initializing Supabase with URL: $url');

      // Check if the URL is reachable before attempting to initialize
      try {
        // Extract the domain from the Supabase URL
        final uri = Uri.parse(url);
        final domain = uri.host;

        debugPrint('Checking connectivity to Supabase host: $domain');

        // Try to resolve the domain
        final lookupResult = await InternetAddress.lookup(domain)
            .timeout(const Duration(seconds: 5));

        if (lookupResult.isEmpty || lookupResult[0].rawAddress.isEmpty) {
          throw Exception('Could not resolve Supabase host: $domain');
        }

        debugPrint('✅ Supabase host is reachable');
      } catch (e) {
        debugPrint('❌ Could not reach Supabase host: $e');
        throw Exception(
            'Could not connect to Supabase. Please check your internet connection and Supabase URL.');
      }

      // Initialize Supabase
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: SupabaseConfig.debugMode,
        authOptions: const AuthClientOptions(
          autoRefreshToken: true,
          persistSession: true,
        ),
      );

      // Test the connection with a simple ping
      try {
        // A simple query to verify the connection works
        final testResult = await Supabase.instance.client
            .from('profiles')
            .select('count')
            .limit(1)
            .count()
            .timeout(const Duration(seconds: 5));

        debugPrint('✅ Supabase connection verified successfully');
        _instance._isInitialized = true;
      } catch (e) {
        debugPrint('⚠️ Supabase connection test failed: $e');
        // We continue anyway since the initialization succeeded
        // The connection might be working for other operations
        _instance._isInitialized = true;
      }

      debugPrint('✅ Supabase initialized successfully');
    } catch (e) {
      debugPrint('❌ Supabase initialization failed: $e');
      _instance._isInitialized = false;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('host lookup') ||
          e.toString().contains('No address associated with hostname') ||
          e.toString().contains('internet connection')) {
        throw Exception(
            'Network error: Cannot connect to Supabase. Please check your internet connection and try again.');
      } else {
        throw Exception('Failed to initialize Supabase: $e');
      }
    }
  }

  // Rest of your SupabaseService implementation...
  // (Keep all the existing methods from the original file)
}
