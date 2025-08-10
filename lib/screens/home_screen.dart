import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/todo_provider.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../models/todo.dart';
import '../widgets/todo_list_tile.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/statistics_card.dart';
import 'add_edit_todo_screen.dart';
import 'settings_screen.dart';
import 'categories_screen.dart';

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
            Consumer<TodoProvider>(
              builder: (context, todoProvider, child) => Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('All'),
                    Text(
                      '${todoProvider.totalTodos}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            Consumer<TodoProvider>(
              builder: (context, todoProvider, child) => Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Active'),
                    Text(
                      '${todoProvider.activeTodos}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            Consumer<TodoProvider>(
              builder: (context, todoProvider, child) => Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Completed'),
                    Text(
                      '${todoProvider.completedTodos}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            Consumer<TodoProvider>(
              builder: (context, todoProvider, child) => Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Overdue'),
                    Text(
                      '${todoProvider.overdueTodos}',
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
      body: Consumer3<TodoProvider, CategoryProvider, SettingsProvider>(
        builder:
            (context, todoProvider, categoryProvider, settingsProvider, child) {
          return Column(
            children: [
              // Search and Filter Section
              if (todoProvider.searchQuery.isNotEmpty ||
                  todoProvider.filterOption != 'all' ||
                  todoProvider.selectedCategoryId != null)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 8.0,
                    children: [
                      if (todoProvider.searchQuery.isNotEmpty)
                        FilterChipWidget(
                          label: 'Search: ${todoProvider.searchQuery}',
                          onDeleted: () => todoProvider.setSearchQuery(''),
                        ),
                      if (todoProvider.filterOption != 'all')
                        FilterChipWidget(
                          label: 'Filter: ${todoProvider.filterOption}',
                          onDeleted: () => todoProvider.setFilterOption('all'),
                        ),
                      if (todoProvider.selectedCategoryId != null)
                        FilterChipWidget(
                          label:
                              'Category: ${_getCategoryName(categoryProvider, todoProvider.selectedCategoryId!)}',
                          onDeleted: () => todoProvider.setCategoryFilter(null),
                        ),
                      TextButton(
                        onPressed: () => todoProvider.clearFilters(),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                ),

              // Statistics Cards
              if (todoProvider.totalTodos > 0)
                Container(
                  height: 120,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatisticsCard(
                          title: 'Total',
                          value: todoProvider.totalTodos.toString(),
                          icon: Icons.list,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatisticsCard(
                          title: 'Completed',
                          value: todoProvider.completedTodos.toString(),
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatisticsCard(
                          title: 'Overdue',
                          value: todoProvider.overdueTodos.toString(),
                          icon: Icons.warning,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatisticsCard(
                          title: 'Due Today',
                          value: todoProvider.dueTodayTodos.toString(),
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
                  children: [
                    _buildTodoList(todoProvider, 'all'),
                    _buildTodoList(todoProvider, 'active'),
                    _buildTodoList(todoProvider, 'completed'),
                    _buildTodoList(todoProvider, 'overdue'),
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

  Widget _buildTodoList(TodoProvider todoProvider, String filter) {
    // Apply the appropriate filter
    List<Todo> filteredTodos;
    switch (filter) {
      case 'active':
        filteredTodos =
            todoProvider.allTodos.where((todo) => !todo.isCompleted).toList();
        break;
      case 'completed':
        filteredTodos =
            todoProvider.allTodos.where((todo) => todo.isCompleted).toList();
        break;
      case 'overdue':
        filteredTodos =
            todoProvider.allTodos.where((todo) => todo.isOverdue).toList();
        break;
      case 'all':
      default:
        filteredTodos = todoProvider.todos;
        break;
    }

    if (filteredTodos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyStateIcon(filter),
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyStateMessage(filter),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyStateSubtitle(filter),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh functionality could be implemented here
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: filteredTodos.length,
        itemBuilder: (context, index) {
          final todo = filteredTodos[index];
          return TodoListTile(
            todo: todo,
            onToggle: () => todoProvider.toggleTodoStatus(todo),
            onEdit: () => _navigateToEditTodo(context, todo),
            onDelete: () =>
                _showDeleteConfirmation(context, todo, todoProvider),
          );
        },
      ),
    );
  }

  IconData _getEmptyStateIcon(String filter) {
    switch (filter) {
      case 'active':
        return Icons.assignment_turned_in;
      case 'completed':
        return Icons.check_circle_outline;
      case 'overdue':
        return Icons.schedule;
      default:
        return Icons.list_alt;
    }
  }

  String _getEmptyStateMessage(String filter) {
    switch (filter) {
      case 'active':
        return 'No active todos';
      case 'completed':
        return 'No completed todos';
      case 'overdue':
        return 'No overdue todos';
      default:
        return 'No todos yet';
    }
  }

  String _getEmptyStateSubtitle(String filter) {
    switch (filter) {
      case 'active':
        return 'All your todos are completed! 🎉';
      case 'completed':
        return 'Complete some todos to see them here';
      case 'overdue':
        return 'Great! You\'re up to date';
      default:
        return 'Add your first todo to get started';
    }
  }

  String _getCategoryName(
      CategoryProvider categoryProvider, String categoryId) {
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
            context.read<TodoProvider>().setSearchQuery(query);
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
    final todoProvider = context.read<TodoProvider>();

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
              groupValue: todoProvider.sortOrder,
              onChanged: (value) {
                todoProvider.setSortOrder(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Creation Date (Oldest)'),
              value: 'creation_date_asc',
              groupValue: todoProvider.sortOrder,
              onChanged: (value) {
                todoProvider.setSortOrder(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Due Date (Earliest)'),
              value: 'due_date_asc',
              groupValue: todoProvider.sortOrder,
              onChanged: (value) {
                todoProvider.setSortOrder(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Priority'),
              value: 'priority',
              groupValue: todoProvider.sortOrder,
              onChanged: (value) {
                todoProvider.setSortOrder(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Title (A-Z)'),
              value: 'title',
              groupValue: todoProvider.sortOrder,
              onChanged: (value) {
                todoProvider.setSortOrder(value!);
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
    final todoProvider = context.read<TodoProvider>();
    final categoryProvider = context.read<CategoryProvider>();

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
                groupValue: todoProvider.filterOption,
                onChanged: (value) => todoProvider.setFilterOption(value!),
              ),
              RadioListTile<String>(
                title: const Text('Active'),
                value: 'active',
                groupValue: todoProvider.filterOption,
                onChanged: (value) => todoProvider.setFilterOption(value!),
              ),
              RadioListTile<String>(
                title: const Text('Completed'),
                value: 'completed',
                groupValue: todoProvider.filterOption,
                onChanged: (value) => todoProvider.setFilterOption(value!),
              ),
              RadioListTile<String>(
                title: const Text('Overdue'),
                value: 'overdue',
                groupValue: todoProvider.filterOption,
                onChanged: (value) => todoProvider.setFilterOption(value!),
              ),
              const SizedBox(height: 16),
              const Text('Category:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              RadioListTile<String?>(
                title: const Text('All Categories'),
                value: null,
                groupValue: todoProvider.selectedCategoryId,
                onChanged: (value) => todoProvider.setCategoryFilter(value),
              ),
              ...categoryProvider.categories.map(
                (category) => RadioListTile<String?>(
                  title: Text(category.name),
                  value: category.id,
                  groupValue: todoProvider.selectedCategoryId,
                  onChanged: (value) => todoProvider.setCategoryFilter(value),
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
    final todoProvider = context.read<TodoProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Total Todos:', todoProvider.totalTodos.toString()),
            _buildStatRow('Completed:', todoProvider.completedTodos.toString()),
            _buildStatRow('Active:', todoProvider.activeTodos.toString()),
            _buildStatRow('Overdue:', todoProvider.overdueTodos.toString()),
            _buildStatRow('Due Today:', todoProvider.dueTodayTodos.toString()),
            const Divider(),
            _buildStatRow(
              'Completion Rate:',
              todoProvider.totalTodos > 0
                  ? '${((todoProvider.completedTodos / todoProvider.totalTodos) * 100).toStringAsFixed(1)}%'
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

  void _navigateToEditTodo(BuildContext context, Todo todo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTodoScreen(todo: todo),
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, Todo todo, TodoProvider todoProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo?'),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              todoProvider.deleteTodo(todo.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${todo.title}" deleted'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      // TODO: Implement undo functionality
                    },
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
