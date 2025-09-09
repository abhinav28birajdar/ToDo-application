import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../services/supabase/supabase_service.dart';
import '../providers/todo_provider.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';

final GetIt serviceLocator = GetIt.instance;

/// Setup all service dependencies
Future<void> setupServiceLocator() async {
  // Services
  final supabaseService = SupabaseService();
  serviceLocator.registerSingleton<SupabaseService>(supabaseService);

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  serviceLocator.registerSingleton<FlutterLocalNotificationsPlugin>(
      flutterLocalNotificationsPlugin);

  final notificationService = NotificationService();
  await notificationService.initializeNotifications();
  serviceLocator.registerSingleton<NotificationService>(notificationService);

  // Shared Preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  serviceLocator.registerSingleton<SharedPreferences>(sharedPreferences);

  // Providers
  serviceLocator.registerFactory<TodoProvider>(() => TodoProvider(
        supabaseService: serviceLocator<SupabaseService>(),
        notificationService: serviceLocator<NotificationService>(),
      ));

  serviceLocator.registerFactory<CategoryProvider>(() => CategoryProvider());

  serviceLocator.registerFactory<SettingsProvider>(() => SettingsProvider(
        serviceLocator<SharedPreferences>(),
      ));
}
