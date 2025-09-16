import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo.dart';
import '../providers/hybrid_task_provider.dart';
import '../providers/hybrid_category_provider.dart';
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

  Widget _buildQuickStats() {
    return Consumer<HybridTaskProvider>(
      builder: (context, taskProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  '${taskProvider.totalTodos}',
                  Icons.list_alt,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatCard(
                  'Active',
                  '${taskProvider.activeTodos}',
                  Icons.pending_actions,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatCard(
                  'Done',
                  '${taskProvider.completedTodos}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatCard(
                  'Overdue',
                  '${taskProvider.overdueTodos}',
                  Icons.warning,
                  Colors.red,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Consumer<HybridTaskProvider>(
      builder: (context, taskProvider, child) {
        final selectedFilter = taskProvider.filterOption;

        return Container(
          height: 40,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                _buildFilterChip(
                  'All (${taskProvider.totalTodos})',
                  'all',
                  selectedFilter,
                  taskProvider,
                  Colors.grey,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  'Active (${taskProvider.activeTodos})',
                  'active',
                  selectedFilter,
                  taskProvider,
                  Colors.blue,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  'Completed (${taskProvider.completedTodos})',
                  'completed',
                  selectedFilter,
                  taskProvider,
                  Colors.green,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  'Overdue (${taskProvider.overdueTodos})',
                  'overdue',
                  selectedFilter,
                  taskProvider,
                  Colors.red,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  'Today (${taskProvider.todayTodos})',
                  'today',
                  selectedFilter,
                  taskProvider,
                  Colors.orange,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String selectedFilter,
    HybridTaskProvider taskProvider,
    Color color,
  ) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => taskProvider.setFilterOption(value),
      backgroundColor: color.withOpacity(0.1),
      selectedColor: color,
      checkmarkColor: Colors.white,
      side: BorderSide(color: color.withOpacity(0.3)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildCategoryFilterChips() {
    return Consumer2<HybridTaskProvider, HybridCategoryProvider>(
      builder: (context, taskProvider, categoryProvider, child) {
        final selectedCategoryId = taskProvider.selectedCategoryId;
        final categories = categoryProvider.categories;

        if (categories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 40,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Categories',
                      style: TextStyle(fontSize: 12)),
                  selected: selectedCategoryId == null,
                  onSelected: (_) => taskProvider.setCategoryFilter(null),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 6),
                ...categories.map((category) {
                  final isSelected = category.id == selectedCategoryId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: FilterChip(
                      label: Text(
                        category.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontSize: 12,
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
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }).toList(),
              ],
            ),
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
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading tasks...'),
              ],
            ),
          );
        }

        if (tasks.isEmpty) {
          return _buildEmptyState(taskProvider);
        }

        return ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final todo = tasks[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: TodoListTile(
                todo: todo,
                onToggle: () async {
                  await taskProvider.toggleTodoStatus(todo);
                },
                onEdit: () => _navigateToEditTaskScreen(todo),
                onDelete: () async {
                  final confirmed = await _showDeleteConfirmation(todo.title);
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
            );
          },
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

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToAddTaskScreen,
            icon: const Icon(Icons.add),
            label: const Text('Add New Task'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
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
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title: const Text(
          'Todo App',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // TODO: Implement menu functionality
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTasks,
        child: Column(
          children: [
            // Quick Stats
            _buildQuickStats(),

            // Filter Chips
            _buildFilterChips(),
            const SizedBox(height: 4),

            // Category Filters
            _buildCategoryFilterChips(),
            const SizedBox(height: 4),

            // Search Bar (if visible)
            if (_isSearchVisible)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  autofocus: true,
                  onChanged: _onSearchChanged,
                ),
              ),

            if (_isSearchVisible) const SizedBox(height: 8),

            // Task List
            Expanded(child: _buildTaskList()),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "add",
            onPressed: _navigateToAddTaskScreen,
            backgroundColor: const Color(0xFF8B5CF6),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
