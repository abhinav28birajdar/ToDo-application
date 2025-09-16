import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/hybrid_task_provider.dart';
import '../providers/hybrid_category_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/statistics_card.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

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
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Todo App'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sort',
                child: ListTile(
                  leading: Icon(Icons.sort),
                  title: Text('Sort'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'filter',
                child: ListTile(
                  leading: Icon(Icons.filter_list),
                  title: Text('Filter'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'categories',
                child: ListTile(
                  leading: Icon(Icons.category),
                  title: Text('Categories'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'stats',
                child: ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text('Statistics'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Consumer<HybridTaskProvider>(
              builder: (context, taskProvider, child) => Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('All'),
                    Text(
                      '${taskProvider.totalTodos}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            Consumer<HybridTaskProvider>(
              builder: (context, taskProvider, child) => Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Active'),
                    Text(
                      '${taskProvider.activeTodos}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            Consumer<HybridTaskProvider>(
              builder: (context, taskProvider, child) => Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Completed'),
                    Text(
                      '${taskProvider.completedTodos}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            Consumer<HybridTaskProvider>(
              builder: (context, taskProvider, child) => Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Overdue'),
                    Text(
                      '${taskProvider.overdueTodos}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

              // Statistics Cards
              if (taskProvider.totalTodos > 0)
                Container(
                  height: 120,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatisticsCard(
                          title: 'Total',
                          value: taskProvider.totalTodos.toString(),
                          icon: Icons.list,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatisticsCard(
                          title: 'Completed',
                          value: taskProvider.completedTodos.toString(),
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatisticsCard(
                          title: 'Overdue',
                          value: taskProvider.overdueTodos.toString(),
                          icon: Icons.warning,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatisticsCard(
                          title: 'Due Today',
                          value: taskProvider.todayTodos.toString(),
                          icon: Icons.today,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),

              // Todo List
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    TasksScreen(filterType: 'all'),
                    TasksScreen(filterType: 'active'),
                    TasksScreen(filterType: 'completed'),
                    TasksScreen(filterType: 'overdue'),
                  ],
                ),
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

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'sort':
        _showSortDialog(context);
        break;
      case 'filter':
        _showFilterDialog(context);
        break;
      case 'categories':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CategoriesScreen()),
        );
        break;
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
      case 'stats':
        _showStatsDialog(context);
        break;
    }
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Todos'),
        content: SearchBarWidget(
          onSearch: (query) {
            context.read<HybridTaskProvider>().setSearchQuery(query);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog(BuildContext context) {
    final taskProvider = context.read<HybridTaskProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Todos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Creation Date (Newest)'),
              value: 'creation_date_desc',
              groupValue: taskProvider.sortOrder,
              onChanged: (value) {
                taskProvider.setSortOrder(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Creation Date (Oldest)'),
              value: 'creation_date_asc',
              groupValue: taskProvider.sortOrder,
              onChanged: (value) {
                taskProvider.setSortOrder(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Due Date (Earliest)'),
              value: 'due_date_asc',
              groupValue: taskProvider.sortOrder,
              onChanged: (value) {
                taskProvider.setSortOrder(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Priority'),
              value: 'priority',
              groupValue: taskProvider.sortOrder,
              onChanged: (value) {
                taskProvider.setSortOrder(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Title (A-Z)'),
              value: 'title',
              groupValue: taskProvider.sortOrder,
              onChanged: (value) {
                taskProvider.setSortOrder(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final taskProvider = context.read<HybridTaskProvider>();
    final categoryProvider = context.read<HybridCategoryProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Todos'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              RadioListTile<String>(
                title: const Text('All'),
                value: 'all',
                groupValue: taskProvider.filterOption,
                onChanged: (value) => taskProvider.setFilterOption(value!),
              ),
              RadioListTile<String>(
                title: const Text('Active'),
                value: 'active',
                groupValue: taskProvider.filterOption,
                onChanged: (value) => taskProvider.setFilterOption(value!),
              ),
              RadioListTile<String>(
                title: const Text('Completed'),
                value: 'completed',
                groupValue: taskProvider.filterOption,
                onChanged: (value) => taskProvider.setFilterOption(value!),
              ),
              RadioListTile<String>(
                title: const Text('Overdue'),
                value: 'overdue',
                groupValue: taskProvider.filterOption,
                onChanged: (value) => taskProvider.setFilterOption(value!),
              ),
              const SizedBox(height: 16),
              const Text('Category:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              RadioListTile<String?>(
                title: const Text('All Categories'),
                value: null,
                groupValue: taskProvider.selectedCategoryId,
                onChanged: (value) => taskProvider.setCategoryFilter(value),
              ),
              ...categoryProvider.categories.map(
                (category) => RadioListTile<String?>(
                  title: Text(category.name),
                  value: category.id,
                  groupValue: taskProvider.selectedCategoryId,
                  onChanged: (value) => taskProvider.setCategoryFilter(value),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showStatsDialog(BuildContext context) {
    final taskProvider = context.read<HybridTaskProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Total Todos:', taskProvider.totalTodos.toString()),
            _buildStatRow('Completed:', taskProvider.completedTodos.toString()),
            _buildStatRow('Active:', taskProvider.activeTodos.toString()),
            _buildStatRow('Overdue:', taskProvider.overdueTodos.toString()),
            _buildStatRow('Due Today:', taskProvider.todayTodos.toString()),
            const Divider(),
            _buildStatRow(
              'Completion Rate:',
              taskProvider.totalTodos > 0
                  ? '${((taskProvider.completedTodos / taskProvider.totalTodos) * 100).toStringAsFixed(1)}%'
                  : '0%',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
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
