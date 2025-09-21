import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo.dart';
import '../providers/hybrid_task_provider.dart';
import '../providers/hybrid_category_provider.dart';
import '../services/theme_service.dart';
import '../widgets/todo_list_tile.dart';
import 'add_edit_todo_screen.dart';

class TasksScreen extends StatefulWidget {
  final String? filterType; // 'all', 'active', 'completed', 'overdue'

  const TasksScreen({Key? key, this.filterType}) : super(key: key);

  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearchVisible = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshTasks();
      // Set initial filter if provided
      if (widget.filterType != null) {
        context.read<HybridTaskProvider>().setFilterOption(widget.filterType!);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshTasks() async {
    try {
      await context.read<HybridTaskProvider>().loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tasks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchQuery = '';
        _searchController.clear();
        context.read<HybridTaskProvider>().setSearchQuery('');
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    context.read<HybridTaskProvider>().setSearchQuery(query);
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
    context.read<HybridTaskProvider>().setSearchQuery('');
  }

  void _navigateToAddTaskScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddEditTodoScreen(),
      ),
    );
  }

  void _navigateToEditTaskScreen(Todo todo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditTodoScreen(todo: todo),
      ),
    );
  }

  Widget _buildUnifiedCategoryHeader() {
    return Consumer<HybridTaskProvider>(
      builder: (context, taskProvider, child) {
        return Container(
          margin: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 6,
            shadowColor: Colors.black.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.category_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Task Categories',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total: ${taskProvider.totalTodos} tasks',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilterChips() {
    return Consumer2<HybridTaskProvider, HybridCategoryProvider>(
      builder: (context, taskProvider, categoryProvider, child) {
        final selectedCategoryId = taskProvider.selectedCategoryId;
        final categories = categoryProvider.categories;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
                child: Text(
                  'Filter by Category',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.8),
                      ),
                ),
              ),
              Container(
                height: 40,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // All Categories chip with improved design
                      Container(
                        margin: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(
                            'All Categories',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selectedCategoryId == null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: selectedCategoryId == null
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          selected: selectedCategoryId == null,
                          onSelected: (_) =>
                              taskProvider.setCategoryFilter(null),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          selectedColor: Theme.of(context).colorScheme.primary,
                          checkmarkColor: Colors.white,
                          side: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3),
                            width: 1.5,
                          ),
                          elevation: selectedCategoryId == null ? 2 : 0,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      // Category chips
                      ...categories.map((category) {
                        final isSelected = category.id == selectedCategoryId;
                        return Container(
                          margin: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(
                              category.name,
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.white : category.color,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) {
                              taskProvider.setCategoryFilter(
                                isSelected ? null : category.id,
                              );
                            },
                            backgroundColor: category.color.withOpacity(0.1),
                            selectedColor: category.color,
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: category.color.withOpacity(0.4),
                              width: 1.5,
                            ),
                            elevation: isSelected ? 2 : 0,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskList() {
    return Consumer<HybridTaskProvider>(
      builder: (context, taskProvider, child) {
        final tasks = taskProvider.todos;
        final isLoading = taskProvider.isLoading;

        if (isLoading) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(64.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading tasks...'),
                  ],
                ),
              ),
            ),
          );
        }

        if (tasks.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState(taskProvider),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final todo = tasks[index];
              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: index == tasks.length - 1
                      ? 100
                      : 8, // Extra padding for last item
                ),
                child: Card(
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TodoListTile(
                    todo: todo,
                    onToggle: () async {
                      await taskProvider.toggleTodoStatus(todo);
                    },
                    onEdit: () => _navigateToEditTaskScreen(todo),
                    onDelete: () async {
                      final confirmed =
                          await _showDeleteConfirmation(todo.title);
                      if (confirmed) {
                        await taskProvider.deleteTodo(todo.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Task deleted successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              );
            },
            childCount: tasks.length,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(HybridTaskProvider taskProvider) {
    String message;
    String subtitle;
    IconData icon;

    if (_searchQuery.isNotEmpty) {
      message = 'No tasks found';
      subtitle = 'Try adjusting your search terms';
      icon = Icons.search_off;
    } else if (taskProvider.filterOption != 'all') {
      message = 'No ${taskProvider.filterOption} tasks';
      subtitle = 'Create a new task or change your filter';
      icon = Icons.filter_list_off;
    } else {
      message = 'No tasks yet';
      subtitle = 'Create your first task to get started';
      icon = Icons.task_alt;
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(
              icon,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToAddTaskScreen,
              icon: const Icon(Icons.add),
              label: const Text('Add New Task'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 60), // Extra space at bottom
          ],
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(String taskTitle) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: Text('Are you sure you want to delete "$taskTitle"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Todo App',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        actions: [
          Consumer<ThemeService>(
            builder: (context, themeService, child) {
              return IconButton(
                icon: Icon(
                  themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () => themeService.toggleTheme(),
                tooltip: themeService.isDarkMode
                    ? 'Switch to Light Mode'
                    : 'Switch to Dark Mode',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Implement menu functionality
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTasks,
        child: CustomScrollView(
          slivers: [
            // Unified Category Header
            SliverToBoxAdapter(
              child: _buildUnifiedCategoryHeader(),
            ),

            // Category Filters Section
            SliverToBoxAdapter(
              child: _buildCategoryFilterChips(),
            ),

            // Search Bar (if visible)
            if (_isSearchVisible)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    autofocus: true,
                    onChanged: _onSearchChanged,
                  ),
                ),
              ),

            // Task List
            _buildTaskList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTaskScreen,
        child: const Icon(Icons.add),
      ),
    );
  }
}
