import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/hybrid_task_provider.dart';
import '../providers/hybrid_category_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/filter_chip_widget.dart';
import 'add_edit_todo_screen.dart';
import 'settings_screen.dart';
import 'categories_screen.dart';
import 'tasks_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    // Initialize data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final taskProvider =
          Provider.of<HybridTaskProvider>(context, listen: false);
      await taskProvider.loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: null, // Remove the appBar with tabs
      drawer: _buildDrawer(context),
      body: Consumer3<HybridTaskProvider, HybridCategoryProvider,
          SettingsProvider>(
        builder:
            (context, taskProvider, categoryProvider, settingsProvider, child) {
          return Column(
            children: [
              // Search and Filter Section
              if (taskProvider.searchQuery.isNotEmpty ||
                  taskProvider.filterOption != 'all' ||
                  taskProvider.selectedCategoryId != null)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 8.0,
                    children: [
                      if (taskProvider.searchQuery.isNotEmpty)
                        FilterChipWidget(
                          label: 'Search: ${taskProvider.searchQuery}',
                          onDeleted: () => taskProvider.setSearchQuery(''),
                        ),
                      if (taskProvider.filterOption != 'all')
                        FilterChipWidget(
                          label: 'Filter: ${taskProvider.filterOption}',
                          onDeleted: () => taskProvider.setFilterOption('all'),
                        ),
                      if (taskProvider.selectedCategoryId != null)
                        FilterChipWidget(
                          label:
                              'Category: ${_getCategoryName(categoryProvider, taskProvider.selectedCategoryId!)}',
                          onDeleted: () => taskProvider.setCategoryFilter(null),
                        ),
                      TextButton(
                        onPressed: () => taskProvider.clearFilters(),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                ),

              // Todo List
              const Expanded(
                child: TasksScreen(), // Single unified view
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddTodo(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Todo'),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Todo App',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Stay organized, stay productive',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('Categories'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CategoriesScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  settingsProvider.isDarkMode
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                title: Text(
                  settingsProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                ),
                onTap: () => settingsProvider.toggleTheme(),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Backup & Restore'),
                onTap: () => _showBackupDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                onTap: () => _showAboutDialog(context),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getCategoryName(
      HybridCategoryProvider categoryProvider, String categoryId) {
    final category = categoryProvider.getCategoryById(categoryId);
    return category?.name ?? 'Unknown Category';
  }

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup & Restore'),
        content: const Text(
            'Backup and restore functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Todo App',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.check_circle, size: 48),
      children: [
        const Text(
            'A complete Flutter Todo application with Provider and Hive persistence.'),
        const SizedBox(height: 16),
        const Text('Features:'),
        const Text('• Add, edit, and delete todos'),
        const Text('• Categories and tags'),
        const Text('• Priority levels'),
        const Text('• Due dates and notifications'),
        const Text('• Search and filtering'),
        const Text('• Dark/Light theme'),
        const Text('• Backup and restore'),
      ],
    );
  }

  void _navigateToAddTodo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditTodoScreen(),
      ),
    );
  }
}
