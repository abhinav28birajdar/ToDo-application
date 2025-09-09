import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';
import '../models/todo.dart';

/// Task Provider for managing task state using Supabase
/// Version: 2.0.0 (September 8, 2025)
class TaskProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _filterOption = 'all';
  String _sortOrder = 'creation_date_desc';
  String? _selectedCategoryId;

  // Getters
  List<Map<String, dynamic>> get tasks => _tasks;

  List<Todo> get todos {
    List<Map<String, dynamic>> filteredTasks = List.from(_tasks);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredTasks = filteredTasks.where((task) {
        final title = task['title']?.toString().toLowerCase() ?? '';
        final description = task['description']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || description.contains(query);
      }).toList();
    }

    // Apply category filter
    if (_selectedCategoryId != null) {
      filteredTasks = filteredTasks.where((task) {
        return task['category_id'] == _selectedCategoryId;
      }).toList();
    }

    // Apply status filter
    switch (_filterOption) {
      case 'active':
        filteredTasks = filteredTasks
            .where((task) => !(task['is_completed'] ?? false))
            .toList();
        break;
      case 'completed':
        filteredTasks = filteredTasks
            .where((task) => task['is_completed'] ?? false)
            .toList();
        break;
      case 'overdue':
        final now = DateTime.now();
        filteredTasks = filteredTasks.where((task) {
          final dueDate = task['due_date'];
          if (dueDate == null) return false;
          final due = DateTime.tryParse(dueDate.toString());
          return due != null &&
              due.isBefore(now) &&
              !(task['is_completed'] ?? false);
        }).toList();
        break;
      case 'today':
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        filteredTasks = filteredTasks.where((task) {
          final dueDate = task['due_date'];
          if (dueDate == null) return false;
          final due = DateTime.tryParse(dueDate.toString());
          return due != null &&
              due.isAfter(startOfDay) &&
              due.isBefore(endOfDay) &&
              !(task['is_completed'] ?? false);
        }).toList();
        break;
      // 'all' - no additional filtering
    }

    // Apply sorting
    filteredTasks.sort((a, b) {
      switch (_sortOrder) {
        case 'title_asc':
          return (a['title'] ?? '')
              .toString()
              .compareTo((b['title'] ?? '').toString());
        case 'title_desc':
          return (b['title'] ?? '')
              .toString()
              .compareTo((a['title'] ?? '').toString());
        case 'due_date_asc':
          final aDate = a['due_date'] != null
              ? DateTime.tryParse(a['due_date'].toString())
              : null;
          final bDate = b['due_date'] != null
              ? DateTime.tryParse(b['due_date'].toString())
              : null;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return aDate.compareTo(bDate);
        case 'due_date_desc':
          final aDate = a['due_date'] != null
              ? DateTime.tryParse(a['due_date'].toString())
              : null;
          final bDate = b['due_date'] != null
              ? DateTime.tryParse(b['due_date'].toString())
              : null;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        case 'priority_asc':
          return (a['priority'] ?? 2).compareTo(b['priority'] ?? 2);
        case 'priority_desc':
          return (b['priority'] ?? 2).compareTo(a['priority'] ?? 2);
        case 'creation_date_desc':
        default:
          final aDate = a['created_at'] != null
              ? DateTime.tryParse(a['created_at'].toString())
              : DateTime.now();
          final bDate = b['created_at'] != null
              ? DateTime.tryParse(b['created_at'].toString())
              : DateTime.now();
          return bDate!.compareTo(aDate!);
      }
    });

    return filteredTasks.map((task) => taskToTodo(task)).toList();
  }

  List<Todo> get allTodos => _tasks
      .map((task) => taskToTodo(task))
      .toList(); // Alias for compatibility
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get filterOption => _filterOption;
  String get sortOrder => _sortOrder;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get errorMessage => _error;

  // Count getters for compatibility
  int get totalTodos => _tasks.length;
  int get activeTodos =>
      _tasks.where((task) => !(task['is_completed'] ?? false)).length;
  int get completedTodos =>
      _tasks.where((task) => task['is_completed'] ?? false).length;
  int get overdueTodos {
    final now = DateTime.now();
    return _tasks.where((task) {
      final dueDate = task['due_date'];
      if (dueDate == null) return false;
      final due = DateTime.tryParse(dueDate.toString());
      return due != null &&
          due.isBefore(now) &&
          !(task['is_completed'] ?? false);
    }).length;
  }

  int get dueTodayTodos {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _tasks.where((task) {
      final dueDate = task['due_date'];
      if (dueDate == null) return false;
      final due = DateTime.tryParse(dueDate.toString());
      return due != null &&
          due.isAfter(startOfDay) &&
          due.isBefore(endOfDay) &&
          !(task['is_completed'] ?? false);
    }).length;
  }

  // Get tasks with filters
  List<Map<String, dynamic>> getFilteredTasks({
    bool? isCompleted,
    String? categoryId,
    int? priority,
  }) {
    return _tasks.where((task) {
      if (isCompleted != null && task['is_completed'] != isCompleted) {
        return false;
      }
      if (categoryId != null && task['category_id'] != categoryId) {
        return false;
      }
      if (priority != null && task['priority'] != priority) {
        return false;
      }
      return true;
    }).toList();
  }

  // Load tasks from Supabase
  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _supabaseService.getTasks();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _tasks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new task
  Future<bool> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    DateTime? notificationTime,
    int priority = 2,
    String? categoryId,
    List<String>? tags,
    String? location,
  }) async {
    try {
      final newTask = await _supabaseService.createTask(
        title: title,
        description: description,
        dueDate: dueDate,
        notificationTime: notificationTime,
        priority: priority,
        categoryId: categoryId,
        tags: tags,
        location: location,
      );

      _tasks.insert(0, newTask);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update an existing task
  Future<bool> updateTask({
    required String taskId,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? dueDate,
    DateTime? notificationTime,
    int? priority,
    String? categoryId,
    List<String>? tags,
    String? location,
  }) async {
    try {
      final updatedTask = await _supabaseService.updateTask(
        taskId: taskId,
        title: title,
        description: description,
        isCompleted: isCompleted,
        dueDate: dueDate,
        notificationTime: notificationTime,
        priority: priority,
        categoryId: categoryId,
        tags: tags,
        location: location,
      );

      final index = _tasks.indexWhere((task) => task['id'] == taskId);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Toggle task completion
  Future<bool> toggleTaskCompletion(String taskId) async {
    final task = _tasks.firstWhere((t) => t['id'] == taskId);
    return await updateTask(
      taskId: taskId,
      isCompleted: !task['is_completed'],
    );
  }

  // Delete a task
  Future<bool> deleteTask(String taskId) async {
    try {
      await _supabaseService.deleteTask(taskId);
      _tasks.removeWhere((task) => task['id'] == taskId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Additional methods for compatibility with TodoProvider interface

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Set filter option
  void setFilterOption(String filter) {
    _filterOption = filter;
    notifyListeners();
  }

  /// Set sort order
  void setSortOrder(String order) {
    _sortOrder = order;
    notifyListeners();
  }

  /// Set category filter
  void setCategoryFilter(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _filterOption = 'all';
    _selectedCategoryId = null;
    notifyListeners();
  }

  /// Convert task to todo for compatibility
  Todo taskToTodo(Map<String, dynamic> task) {
    return Todo(
      id: task['id'] ?? '',
      title: task['title'] ?? '',
      description: task['description'] ?? '',
      isCompleted: task['is_completed'] ?? false,
      creationDate: task['created_at'] != null
          ? DateTime.tryParse(task['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      dueDate: task['due_date'] != null
          ? DateTime.tryParse(task['due_date'].toString())
          : null,
      priority: task['priority'] ?? 2,
      categoryId: task['category_id'],
      tags: [],
      hasNotification: false,
      notificationTime: null,
      completionDate: task['is_completed'] == true ? DateTime.now() : null,
      notes: task['description'] ?? '',
    );
  }

  /// Toggle todo status (alias for updateTask)
  Future<void> toggleTodoStatus(Todo todo) async {
    final isCompleted = !todo.isCompleted;
    await updateTask(
      taskId: todo.id,
      isCompleted: isCompleted,
    );
  }

  /// Delete todo (alias for deleteTask)
  Future<void> deleteTodo(String todoId) async {
    await deleteTask(todoId);
  }

  /// Fetch tasks (alias for loadTasks)
  Future<void> fetchTasks() async {
    await loadTasks();
  }

  /// Add task method for compatibility
  Future<void> addTodo(Todo todo) async {
    await createTask(
      title: todo.title,
      description: todo.description,
      dueDate: todo.dueDate,
      priority: todo.priority,
      categoryId: todo.categoryId,
    );
    // Reload tasks after adding
    await loadTasks();
  }

  /// Update todo method for compatibility
  Future<void> updateTodo(Todo todo) async {
    await updateTask(
      taskId: todo.id,
      title: todo.title,
      description: todo.description,
      dueDate: todo.dueDate,
      priority: todo.priority,
      categoryId: todo.categoryId,
      isCompleted: todo.isCompleted,
    );
  }

  /// Delete completed tasks
  Future<void> deleteCompletedTasks() async {
    final completedTasks =
        _tasks.where((task) => task['is_completed'] == true).toList();
    for (final task in completedTasks) {
      await deleteTask(task['id']);
    }
  }

  /// Mark all tasks as completed
  Future<void> markAllAsCompleted() async {
    for (final task in _tasks) {
      if (task['is_completed'] != true) {
        await updateTask(taskId: task['id'], isCompleted: true);
      }
    }
  }

  /// Get todos by category (compatibility method)
  List<Todo> getTodosByCategory(String categoryId) {
    final filteredTasks =
        _tasks.where((task) => task['category_id'] == categoryId).toList();
    return filteredTasks.map((task) => taskToTodo(task)).toList();
  }
}
