import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/todo.dart';
import '../services/notification_service.dart';
import '../services/supabase/supabase_service.dart';

class TodoProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;
  final NotificationService _notificationService;

  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];
  String _searchQuery = '';
  String _filterOption =
      'all'; // 'all', 'active', 'completed', 'overdue', 'today'
  String _sortOrder = 'due_date_asc';
  String? _selectedCategoryId;
  bool _isLoading = false;
  String? _errorMessage;

  TodoProvider({
    required SupabaseService supabaseService,
    required NotificationService notificationService,
  })  : _supabaseService = supabaseService,
        _notificationService = notificationService {
    _initialize();
  }

  // Getters
  List<Task> get todos => _filteredTasks;
  List<Task> get allTodos => _allTasks;
  String get searchQuery => _searchQuery;
  String get filterOption => _filterOption;
  String get sortOrder => _sortOrder;
  String? get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Convert Task to Todo for compatibility
  Todo taskToTodo(Task task) {
    return Todo(
      id: task.id,
      title: task.title,
      description: task.description,
      isCompleted: task.isCompleted,
      creationDate: task.createdAt,
      dueDate: task.dueDate,
      categoryId: task.categoryId,
      priority: task.priority,
      tags: [], // Task doesn't have tags
      hasNotification: task.notificationTime != null,
      notificationTime: task.notificationTime,
      completionDate: task.completedDate,
      notes: '', // Task doesn't have notes field
    );
  }

  // Statistics
  int get totalTodos => _allTasks.length;
  int get completedTodos => _allTasks.where((task) => task.isCompleted).length;
  int get activeTodos => _allTasks.where((task) => !task.isCompleted).length;
  int get overdueTodos => _allTasks.where((task) => task.isOverdue).length;
  int get dueTodayTodos => _allTasks.where((task) => task.isDueToday).length;

  // Initialize data
  Future<void> _initialize() async {
    await loadTasks();
  }

  // Load tasks from Supabase
  // Alias for loadTasks to make it more consistent with naming conventions
  Future<void> fetchTasks() async {
    return loadTasks();
  }

  Future<void> loadTasks() async {
    _setLoading(true);

    try {
      if (_supabaseService.currentUser == null) {
        _allTasks = [];
        _applyFiltersAndSort();
        _setLoading(false);
        return;
      }

      final tasksData = await _supabaseService.getTasks();
      _allTasks = tasksData.map((data) => Task.fromSupabase(data)).toList();

      // Schedule notifications for all active tasks
      for (var task in _allTasks
          .where((t) => !t.isCompleted && t.notificationTime != null)) {
        await _notificationService.scheduleTaskNotification(task);
      }

      _applyFiltersAndSort();
      _setLoading(false);
    } catch (e) {
      _setError('Error loading tasks: $e');
    }
  }

  // Apply current filters and sorting
  void _applyFiltersAndSort() {
    List<Task> filtered = List.from(_allTasks);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) {
        return task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            task.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply completion filter
    switch (_filterOption) {
      case 'active':
        filtered = filtered.where((task) => !task.isCompleted).toList();
        break;
      case 'completed':
        filtered = filtered.where((task) => task.isCompleted).toList();
        break;
      case 'overdue':
        filtered = filtered.where((task) => task.isOverdue).toList();
        break;
      case 'today':
        filtered = filtered.where((task) => task.isDueToday).toList();
        break;
      case 'all':
      default:
        // No filter needed
        break;
    }

    // Apply category filter
    if (_selectedCategoryId != null) {
      filtered = filtered
          .where((task) => task.categoryId == _selectedCategoryId)
          .toList();
    }

    // Apply sorting
    _sortTasks(filtered);

    _filteredTasks = filtered;
    notifyListeners();
  }

  // Create a new task
  Future<void> createTask(Task task) async {
    _setLoading(true);

    try {
      final newTask = task.copyWith(
        userId: _supabaseService.currentUser?.id,
      );

      final responseData =
          await _supabaseService.createTask(newTask.toSupabase());
      final createdTask = Task.fromSupabase(responseData);

      _allTasks.add(createdTask);

      // Schedule notification if needed
      if (createdTask.notificationTime != null) {
        await _notificationService.scheduleTaskNotification(createdTask);
      }

      _applyFiltersAndSort();
      _setLoading(false);
    } catch (e) {
      _setError('Error creating task: $e');
    }
  }

  // Add Todo method for compatibility with add_edit_todo_screen
  Future<void> addTodo(Todo todo) async {
    final task = Task(
      id: todo.id,
      title: todo.title,
      description: todo.description,
      isCompleted: todo.isCompleted,
      dueDate: todo.dueDate,
      completedDate: todo.completionDate,
      notificationTime: todo.hasNotification ? todo.notificationTime : null,
      priority: todo.priority,
      categoryId: todo.categoryId,
      userId: _supabaseService.currentUser?.id,
      recurrence: null, // Todo doesn't have recurrence
      createdAt: todo.creationDate,
      updatedAt: DateTime.now(),
    );

    await createTask(task);
  }

  // Update Todo method for compatibility with add_edit_todo_screen
  Future<void> updateTodo(Todo todo) async {
    final existingTaskIndex =
        _allTasks.indexWhere((task) => task.id == todo.id);
    if (existingTaskIndex >= 0) {
      final existingTask = _allTasks[existingTaskIndex];
      final updatedTask = existingTask.copyWith(
        title: todo.title,
        description: todo.description,
        isCompleted: todo.isCompleted,
        dueDate: todo.dueDate,
        completedDate: todo.completionDate,
        notificationTime: todo.hasNotification ? todo.notificationTime : null,
        priority: todo.priority,
        categoryId: todo.categoryId,
        updatedAt: DateTime.now(),
      );

      await updateTask(updatedTask);
    }
  }

  // Delete Todo method for compatibility
  Future<void> deleteTodo(String id) async {
    await deleteTask(id);
  }

  // Update an existing task
  Future<void> updateTask(Task task) async {
    _setLoading(true);

    try {
      final updatedTask = task.copyWith(
        updatedAt: DateTime.now(),
      );

      await _supabaseService.updateTask(task.id, updatedTask.toSupabase());

      final index = _allTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _allTasks[index] = updatedTask;

        // Cancel old notification and schedule new one if needed
        await _notificationService.cancelNotification(task.id);
        if (!updatedTask.isCompleted && updatedTask.notificationTime != null) {
          await _notificationService.scheduleTaskNotification(updatedTask);
        }
      }

      _applyFiltersAndSort();
      _setLoading(false);
    } catch (e) {
      _setError('Error updating task: $e');
    }
  }

  // Toggle task completion status
  Future<void> toggleTodoStatus(dynamic taskOrTodo) async {
    Task task;
    if (taskOrTodo is Todo) {
      // Find the equivalent Task from Todo
      task = _allTasks.firstWhere((t) => t.id == taskOrTodo.id);
    } else if (taskOrTodo is Task) {
      task = taskOrTodo;
    } else {
      throw ArgumentError('Expected Task or Todo type');
    }
    try {
      final now = DateTime.now();
      final updatedTask = task.copyWith(
        isCompleted: !task.isCompleted,
        completedDate: !task.isCompleted ? now : null,
      );

      // Cancel notification if task is completed
      if (updatedTask.isCompleted && updatedTask.notificationTime != null) {
        await _notificationService.cancelNotification(task.id);
      }

      await updateTask(updatedTask);
    } catch (e) {
      _setError('Error toggling task status: $e');
    }
  }

  // Delete a task
  Future<void> deleteTask(String id) async {
    _setLoading(true);

    try {
      await _supabaseService.deleteTask(id);

      // Cancel notification
      await _notificationService.cancelNotification(id);

      // Remove from in-memory list
      _allTasks.removeWhere((task) => task.id == id);
      _applyFiltersAndSort();
      _setLoading(false);
    } catch (e) {
      _setError('Error deleting task: $e');
    }
  }

  // Batch operations
  Future<void> deleteCompletedTasks() async {
    _setLoading(true);

    try {
      final completedTasks =
          _allTasks.where((task) => task.isCompleted).toList();

      for (final task in completedTasks) {
        await _supabaseService.deleteTask(task.id);
        await _notificationService.cancelNotification(task.id);
      }

      _allTasks.removeWhere((task) => task.isCompleted);
      _applyFiltersAndSort();
      _setLoading(false);
    } catch (e) {
      _setError('Error deleting completed tasks: $e');
    }
  }

  Future<void> markAllAsCompleted() async {
    _setLoading(true);

    try {
      final activeTasks = _allTasks.where((task) => !task.isCompleted).toList();
      final now = DateTime.now();

      for (final task in activeTasks) {
        final updatedTask = task.copyWith(
          isCompleted: true,
          completedDate: now,
        );

        await _supabaseService.updateTask(
            updatedTask.id, updatedTask.toSupabase());
        await _notificationService.cancelNotification(task.id);

        final index = _allTasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _allTasks[index] = updatedTask;
        }
      }

      _applyFiltersAndSort();
      _setLoading(false);
    } catch (e) {
      _setError('Error marking all tasks as completed: $e');
    }
  }

  // Search and filter methods
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
  }

  void setFilterOption(String filter) {
    _filterOption = filter;
    _applyFiltersAndSort();
  }

  void setSortOrder(String order) {
    _sortOrder = order;
    _applyFiltersAndSort();
  }

  void setCategoryFilter(String? categoryId) {
    _selectedCategoryId = categoryId;
    _applyFiltersAndSort();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterOption = 'all';
    _selectedCategoryId = null;
    _applyFiltersAndSort();
  }

  // Helper methods
  void _sortTasks(List<Task> tasks) {
    switch (_sortOrder) {
      case 'creation_date_asc':
        tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'creation_date_desc':
        tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'due_date_asc':
        tasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case 'due_date_desc':
        tasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return b.dueDate!.compareTo(a.dueDate!);
        });
        break;
      case 'priority':
        tasks.sort((a, b) => a.priority.compareTo(b.priority));
        break;
      case 'title':
        tasks.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      default:
        tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
  }

  // Get tasks by category
  List<Task> getTasksByCategory(String categoryId) {
    return _allTasks.where((task) => task.categoryId == categoryId).toList();
  }

  // Get todos by category (for compatibility)
  List<Todo> getTodosByCategory(String categoryId) {
    return _allTasks
        .where((task) => task.categoryId == categoryId)
        .map((task) => taskToTodo(task))
        .toList();
  }

  // Get tasks by priority
  List<Task> getTasksByPriority(int priority) {
    return _allTasks.where((task) => task.priority == priority).toList();
  }

  // Get task by ID
  Task? getTaskById(String id) {
    try {
      return _allTasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    debugPrint(error);
    notifyListeners();
  }

  // Export todos for backup
  Future<Map<String, dynamic>> exportTodos() async {
    try {
      final todosJson = _allTasks
          .map((task) => {
                'id': task.id,
                'title': task.title,
                'description': task.description,
                'isCompleted': task.isCompleted,
                'createdAt': task.createdAt.toIso8601String(),
                'dueDate': task.dueDate?.toIso8601String(),
                'categoryId': task.categoryId,
                'priority': task.priority,
                'notificationTime': task.notificationTime?.toIso8601String(),
                'completedDate': task.completedDate?.toIso8601String(),
                'userId': task.userId,
                'updatedAt': task.updatedAt.toIso8601String(),
              })
          .toList();

      return {
        'version': '1.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'tasksCount': _allTasks.length,
        'tasks': todosJson,
      };
    } catch (e) {
      debugPrint('Error exporting tasks: $e');
      rethrow;
    }
  }
}
