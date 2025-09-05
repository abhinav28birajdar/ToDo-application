import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'providers/todo_provider.dart';
import 'providers/category_provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'services/backup_service.dart';
import 'services/supabase/supabase_service.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'models/todo.dart';
import 'models/category.dart';
import 'models/app_settings.dart';
import 'utils/service_locator.dart';
import 'utils/app_theme.dart';
import 'utils/auth_handler.dart';

void main() async {
  // Ensure that Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables from .env file
    await dotenv.load(fileName: ".env");

    // Initialize service locator
    await setupServiceLocator();

    // Initialize Supabase
    await SupabaseService.initialize();

    // Get the application document directory for Hive storage
    final appDocumentDir =
        await path_provider.getApplicationDocumentsDirectory();

    // Initialize Hive and specify the storage directory
    await Hive.initFlutter(appDocumentDir.path);

    // Register Hive adapters
    Hive.registerAdapter(TodoAdapter());
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(AppSettingsAdapter());

    debugPrint('App initialization completed successfully');
  } catch (e) {
    debugPrint('Error during app initialization: $e');
  }

  // Run the application
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Register our services as providers
        ChangeNotifierProvider<SupabaseService>(
            create: (_) => serviceLocator<SupabaseService>()),
        Provider<NotificationService>(
            create: (_) => serviceLocator<NotificationService>()),
        Provider<BackupService>(
          create: (_) => BackupService(
            supabaseService: serviceLocator<SupabaseService>(),
          ),
        ),

        // Create state management providers in the correct order (dependencies matter)
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => CategoryProvider()),
        ChangeNotifierProvider(
            create: (context) => TodoProvider(
                  supabaseService: serviceLocator<SupabaseService>(),
                  notificationService: serviceLocator<NotificationService>(),
                )),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: dotenv.env['APP_NAME'] ?? 'Pro-Organizer',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
            // Error handling and auth session management
            builder: (context, widget) {
              // Handle potential errors in the widget tree
              ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                return _buildErrorWidget(errorDetails);
              };
              // Wrap the app with our auth handler to manage session expiration
              return AuthHandler(child: widget!);
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(FlutterErrorDetails errorDetails) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We encountered an unexpected error. Please restart the app.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true') ...[
                ExpansionTile(
                  title: const Text('Error Details'),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorDetails.exception.toString(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Simulate a bit of loading time to show the splash screen
    await Future.delayed(const Duration(seconds: 2));

    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final user = supabaseService.currentUser;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Navigate based on auth state
        if (user != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
      // Show error UI or fallback to auth screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/icon
            Icon(
              Icons.check_circle_outline,
              size: 100,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),

            // App name
            Text(
              'Pro-Organizer',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 8),
            Text(
              'Your Secure Task & Note Manager',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 48),

            // Loading indicator
            if (_isLoading)
              CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
