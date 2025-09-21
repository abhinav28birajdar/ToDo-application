import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

import 'config/supabase_config.dart';
import 'models/category.dart';
import 'models/todo.dart';
import 'models/icon_data_adapter.dart';
import 'providers/hybrid_task_provider.dart';
import 'providers/hybrid_category_provider.dart';
import 'providers/note_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/auth_screen.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'services/firebase_notification_service.dart';
import 'services/theme_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");

    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Set background message handler for Firebase
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize Hive
    await Hive.initFlutter();

    // Register Hive adapters
    if (!Hive.isAdapterRegistered(CategoryAdapter().typeId)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(TodoAdapter().typeId)) {
      Hive.registerAdapter(TodoAdapter());
    }
    if (!Hive.isAdapterRegistered(IconDataAdapter().typeId)) {
      Hive.registerAdapter(IconDataAdapter());
    }

    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // Initialize Notification Service
    final notificationService = NotificationService.instance;
    await notificationService.initializeNotifications();

    // Initialize Firebase Notification Service
    try {
      await FirebaseNotificationService.instance.initialize();
      debugPrint('🔔 Firebase Notification Service initialized');
    } catch (e) {
      debugPrint('❌ Firebase initialization failed: $e');
      // Continue without Firebase - app will still work with local notifications
    }

    // Initialize Supabase
    await SupabaseService.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );

    // Create and initialize providers
    final categoryProvider = HybridCategoryProvider();
    final taskProvider = HybridTaskProvider();
    final themeService = ThemeService();

    // Initialize providers
    await categoryProvider.initialize();
    await taskProvider.initialize();

    runApp(MyApp(
      prefs: prefs,
      categoryProvider: categoryProvider,
      taskProvider: taskProvider,
      notificationService: notificationService,
      themeService: themeService,
    ));
  } catch (e) {
    debugPrint('Error during app initialization: $e');
    runApp(const ErrorApp());
  }
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final HybridCategoryProvider categoryProvider;
  final HybridTaskProvider taskProvider;
  final NotificationService notificationService;
  final ThemeService themeService;

  const MyApp({
    super.key,
    required this.prefs,
    required this.categoryProvider,
    required this.taskProvider,
    required this.notificationService,
    required this.themeService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SupabaseService>(create: (_) => SupabaseService()),
        Provider<NotificationService>.value(value: notificationService),
        Provider<FirebaseNotificationService>.value(
          value: FirebaseNotificationService.instance,
        ),
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
        ChangeNotifierProvider.value(value: categoryProvider),
        ChangeNotifierProvider.value(value: taskProvider),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Pro Organizer',
            theme: ThemeService.lightTheme,
            darkTheme: ThemeService.darkTheme,
            themeMode: themeService.themeMode,
            home: const AuthWrapper(),
            debugShowCheckedModeBanner: false,
            builder: (context, widget) {
              // Handle potential errors in the widget tree
              ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                return _buildErrorWidget(errorDetails);
              };
              return widget!;
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
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pro Organizer',
      theme: ThemeService.lightTheme,
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                SizedBox(height: 16),
                Text(
                  'Initialization Failed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Failed to initialize the app. Please check your configuration and try again.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Show splash screen for a brief moment
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    }

    return Consumer2<HybridTaskProvider, HybridCategoryProvider>(
      builder: (context, taskProvider, categoryProvider, child) {
        return StreamBuilder<AuthState>(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            final session = snapshot.data?.session;

            if (session != null) {
              // User is authenticated - enable cloud sync
              WidgetsBinding.instance.addPostFrameCallback((_) {
                taskProvider.enableCloudSync();
                categoryProvider.enableCloudSync();
              });
              return const MainNavigationScreen();
            } else {
              // User is not authenticated - disable cloud sync
              WidgetsBinding.instance.addPostFrameCallback((_) {
                taskProvider.disableCloudSync();
                categoryProvider.disableCloudSync();
              });
              return const AuthScreen();
            }
          },
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
            Image.asset(
              'web/icons/Icon-512.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 24),

            // App name
            Text(
              'Pro Organizer',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 8),
            Text(
              'Your Ultimate Task & Note Manager',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 48),

            // Loading indicator
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
