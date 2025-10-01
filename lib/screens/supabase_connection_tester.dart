import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/supabase_config.dart';
import '../services/supabase_service.dart';

class SupabaseConnectionTester extends StatelessWidget {
  const SupabaseConnectionTester({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Connection Test'),
      ),
      body: FutureBuilder<String>(
        future: testSupabaseConnection(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Testing Supabase Connection...'),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Connection Failed',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildDiagnosticInfo(),
                  ],
                ),
              ),
            );
          } else {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Connection Successful',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      snapshot.data!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildDiagnosticInfo(),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildDiagnosticInfo() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Diagnostic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('Supabase URL: ${SupabaseConfig.supabaseUrl}'),
            const SizedBox(height: 8),
            Text('API Key: ${_maskApiKey(SupabaseConfig.supabaseAnonKey)}'),
            const SizedBox(height: 8),
            Text('.env loaded: ${dotenv.env['SUPABASE_URL'] != null}'),
            const SizedBox(height: 16),
            const Text(
              'Troubleshooting Tips:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('1. Check your internet connection'),
            const Text('2. Verify your Supabase project is active'),
            const Text('3. Confirm API credentials are correct'),
            const Text('4. Check if Supabase is experiencing outages'),
          ],
        ),
      ),
    );
  }

  String _maskApiKey(String key) {
    if (key.length > 12) {
      return '${key.substring(0, 6)}...${key.substring(key.length - 6)}';
    }
    return 'Invalid Key';
  }

  Future<String> testSupabaseConnection() async {
    try {
      // Step 1: Check if .env file is loaded properly
      final supabaseUrl = SupabaseConfig.supabaseUrl;
      final supabaseAnonKey = SupabaseConfig.supabaseAnonKey;

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw Exception('Supabase credentials are missing or empty');
      }

      // Step 2: Check if Supabase URL is reachable
      try {
        final uri = Uri.parse(supabaseUrl);
        final domain = uri.host;

        final lookupResult = await InternetAddress.lookup(domain)
            .timeout(const Duration(seconds: 5));

        if (lookupResult.isEmpty || lookupResult[0].rawAddress.isEmpty) {
          throw Exception('Could not resolve Supabase host: $domain');
        }
      } catch (e) {
        throw Exception('Could not reach Supabase server: $e');
      }

      // Step 3: Try to initialize Supabase
      try {
        // Only initialize if not already initialized
        if (Supabase.instance.client.auth.currentSession == null) {
          await SupabaseService.initialize(
            url: supabaseUrl,
            anonKey: supabaseAnonKey,
          );
        }
      } catch (e) {
        throw Exception('Supabase initialization failed: $e');
      }

      // Step 4: Test the connection with a simple query
      try {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('count')
            .limit(1)
            .count();

        return 'Successfully connected to Supabase!\n'
            'Your database appears to be working correctly.';
      } catch (e) {
        throw Exception('Database query failed: $e');
      }
    } catch (e) {
      throw Exception('Connection test failed: $e');
    }
  }
}
