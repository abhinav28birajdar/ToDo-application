import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';

import '../widgets/todo_list_tile.dart';
import 'add_edit_todo_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({Key? key}) : super(key: key);

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
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshTasks() async {
    await Provider.of<TaskProvider>(context, listen: false).loadTasks();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchQuery = '';
        _searchController.clear();
        Provider.of<TaskProvider>(context, listen: false).setSearchQuery('');
      } else {
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    Provider.of<TaskProvider>(context, listen: false).setSearchQuery(query);
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
    Provider.of<TaskProvider>(context, listen: false).setSearchQuery('');
  }

  void _navigateToAddTaskScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const AddEditTodoScreen(), // No todo means adding new
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

  Widget _buildFilterChips() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final selectedFilter = taskProvider.filterOption;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                FilterChip(
                  label: Text('All (${taskProvider.totalTodos})'),
                  selected: selectedFilter == 'all',
                  onSelected: (_) => taskProvider.setFilterOption('all'),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: selectedFilter == 'all'
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('Active (${taskProvider.activeTodos})'),
                  selected: selectedFilter == 'active',
                  onSelected: (_) => taskProvider.setFilterOption('active'),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: selectedFilter == 'active'
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('Completed (${taskProvider.completedTodos})'),
                  selected: selectedFilter == 'completed',
                  onSelected: (_) => taskProvider.setFilterOption('completed'),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: selectedFilter == 'completed'
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('Overdue (${taskProvider.overdueTodos})'),
                  selected: selectedFilter == 'overdue',
                  onSelected: (_) => taskProvider.setFilterOption('overdue'),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: selectedFilter == 'overdue'
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('Today (${taskProvider.dueTodayTodos})'),
                  selected: selectedFilter == 'today',
                  onSelected: (_) => taskProvider.setFilterOption('today'),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: selectedFilter == 'today'
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilterChips() {
    return Consumer2<TaskProvider, CategoryProvider>(
      builder: (context, taskProvider, categoryProvider, child) {
        final selectedCategoryId = taskProvider.selectedCategoryId;
        final categories = categoryProvider.categories;

        if (categories.isEmpty) {
          return const SizedBox.shrink();
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                ...categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(category.name),
                      selected: category.id == selectedCategoryId,
                      onSelected: (_) {
                        if (category.id == selectedCategoryId) {
                          taskProvider.setCategoryFilter(null);
                        } else {
                          taskProvider.setCategoryFilter(category.id);
                        }
                      },
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      selectedColor: category.color,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: category.id == selectedCategoryId
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
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

  Widget _buildSortMenu() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return PopupMenuButton<String>(
          icon: const Icon(Icons.sort),
          tooltip: 'Sort tasks',
          onSelected: (value) {
            taskProvider.setSortOrder(value);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'due_date_asc',
              child: Text('Due Date (Earliest First)'),
            ),
            const PopupMenuItem(
              value: 'due_date_desc',
              child: Text('Due Date (Latest First)'),
            ),
            const PopupMenuItem(
              value: 'creation_date_asc',
              child: Text('Creation Date (Oldest First)'),
            ),
            const PopupMenuItem(
              value: 'creation_date_desc',
              child: Text('Creation Date (Newest First)'),
            ),
            const PopupMenuItem(
              value: 'priority',
              child: Text('Priority (High to Low)'),
            ),
            const PopupMenuItem(
              value: 'title',
              child: Text('Title (A-Z)'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: _isSearchVisible
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  ),
                ),
                autofocus: true,
                onChanged: _onSearchChanged,
              )
            : const Text('My Tasks'),
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.search_off : Icons.search),
            onPressed: _toggleSearch,
          ),
          _buildSortMenu(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'clear_completed':
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear Completed Tasks'),
                      content: const Text(
                          'Are you sure you want to delete all completed tasks?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Provider.of<TaskProvider>(context, listen: false)
                                .deleteCompletedTasks();
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  break;
                case 'mark_all_completed':
                  Provider.of<TaskProvider>(context, listen: false)
                      .markAllAsCompleted();
                  break;
                case 'clear_filters':
                  Provider.of<TaskProvider>(context, listen: false)
                      .clearFilters();
                  _clearSearch();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_completed',
                child: Text('Clear Completed Tasks'),
              ),
              const PopupMenuItem(
                value: 'mark_all_completed',
                child: Text('Mark All as Completed'),
              ),
              const PopupMenuItem(
                value: 'clear_filters',
                child: Text('Clear All Filters'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTasks,
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildFilterChips(),
            const SizedBox(height: 8),
            _buildCategoryFilterChips(),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer<TaskProvider>(
                builder: (context, taskProvider, child) {
                  final tasks = taskProvider.todos;
                  final isLoading = taskProvider.isLoading;

                  if (isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 80,
                            color: colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No tasks matching "${_searchQuery}"'
                                : taskProvider.filterOption != 'all'
                                    ? 'No ${taskProvider.filterOption} tasks'
                                    : 'No tasks yet',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add a new task to get started',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _navigateToAddTaskScreen,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Task'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final todo = tasks[index]; // tasks is now List<Todo>

                      return TodoListTile(
                        todo: todo,
                        onToggle: () {
                          taskProvider.toggleTodoStatus(todo);
                        },
                        onEdit: () => _navigateToEditTaskScreen(todo),
                        onDelete: () {
                          taskProvider.deleteTodo(todo.id);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTaskScreen,
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }
}
