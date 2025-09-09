/// Demo Mode Configuration
///
/// This allows you to test the app offline without Supabase
/// Set enableDemoMode to true to use local storage instead of Supabase

class DemoConfig {
  // Set to true to enable demo mode (no internet required)
  static const bool enableDemoMode = false;

  // Demo user credentials for testing
  static const String demoEmail = 'demo@example.com';
  static const String demoPassword = 'demo123';
  static const String demoUserName = 'Demo User';

  // Demo data
  static const List<Map<String, dynamic>> demoTasks = [
    {
      'id': '1',
      'title': 'Welcome to Pro Organizer!',
      'description': 'This is a demo task to show how the app works.',
      'isCompleted': false,
      'priority': 1,
      'createdAt': '2024-01-01T10:00:00Z',
    },
    {
      'id': '2',
      'title': 'Configure Supabase',
      'description':
          'Follow the SUPABASE_SETUP.md guide to connect to your database.',
      'isCompleted': false,
      'priority': 2,
      'createdAt': '2024-01-01T11:00:00Z',
    },
  ];

  static const List<Map<String, dynamic>> demoCategories = [
    {
      'id': '1',
      'name': 'Personal',
      'color': '#FF6B6B',
      'icon': 'person',
    },
    {
      'id': '2',
      'name': 'Work',
      'color': '#4ECDC4',
      'icon': 'work',
    },
  ];
}
