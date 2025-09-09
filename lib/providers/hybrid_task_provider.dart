import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/supabase_service.dart';
import '../models/todo.dart';

/// Hybrid Task Provider for managing task state with local storage and optional cloud sync
/// Version: 3.0.0 (September 9, 2025)
class HybridTaskProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<Todo> _todos = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _filterOption = 'all';
  String _sortOrder = 'creation_date_desc';
  String? _selectedCategoryId;
  bool _cloudSyncEnabled = false;

  // Hive box for local storage
  Box<Todo>? _todoBox;

  // Initialize
  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if cloud sync is enabled
      _cloudSyncEnabled = dotenv.env['ENABLE_CLOUD_SYNC'] == 'true';

      // Initialize Hive box
      try {
        _todoBox =
            await Hive.openBox<Todo>(dotenv.env['HIVE_BOX_NAME'] ?? 'todos');
      } catch (e) {
        debugPrint('Error opening Hive box: $e');
        _todoBox = await Hive.openBox<Todo>('todos');
      }

      // Load todos from local storage first
      await _loadFromLocal();

      // If cloud sync is enabled and user is authenticated, sync with cloud
      if (_cloudSyncEnabled && _supabaseService.isAuthenticated) {
        await _syncWithCloud();
      }
    } catch (e) {
      _error = 'Failed to initialize: $e';
      debugPrint('TaskProvider initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Getters
  List<Todo> get todos {
    List<Todo> filteredTodos = List.from(_todos);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredTodos = filteredTodos.where((todo) {
        final title = todo.title.toLowerCase();
        final description = todo.description.toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || description.contains(query);
      }).toList();
    }

    // Apply category filter
    if (_selectedCategoryId != null) {
      filteredTodos = filteredTodos.where((todo) {
        return todo.categoryId == _selectedCategoryId;
      }).toList();
    }

    // Apply status filter
    switch (_filterOption) {
      case 'active':
        filteredTodos =
            filteredTodos.where((todo) => !todo.isCompleted).toList();
        break;
      case 'completed':
        filteredTodos =
            filteredTodos.where((todo) => todo.isCompleted).toList();
        break;
      case 'today':
        final today = DateTime.now();
        filteredTodos = filteredTodos.where((todo) {
          if (todo.dueDate == null) return false;
          return todo.dueDate!.year == today.year &&
              todo.dueDate!.month == today.month &&
              todo.dueDate!.day == today.day;
        }).toList();
        break;
      case 'overdue':
        final now = DateTime.now();
        filteredTodos = filteredTodos.where((todo) {
          return todo.dueDate != null &&
              todo.dueDate!.isBefore(now) &&
              !todo.isCompleted;
        }).toList();
        break;
    }

    // Apply sorting
    switch (_sortOrder) {
      case 'due_date_asc':
        filteredTodos.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case 'due_date_desc':
        filteredTodos.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return b.dueDate!.compareTo(a.dueDate!);
        });
        break;
      case 'priority_desc':
        filteredTodos.sort((a, b) => b.priority.compareTo(a.priority));
        break;
      case 'title_asc':
        filteredTodos.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'creation_date_desc':
      default:
        filteredTodos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filteredTodos;
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get filterOption => _filterOption;
  String get sortOrder => _sortOrder;
  String? get selectedCategoryId => _selectedCategoryId;

  // Statistics
  int get totalTodos => _todos.length;
  int get completedTodos => _todos.where((todo) => todo.isCompleted).length;
  int get activeTodos => _todos.where((todo) => !todo.isCompleted).length;

  int get todayTodos {
    final today = DateTime.now();
    return _todos.where((todo) {
      if (todo.dueDate == null) return false;
      return todo.dueDate!.year == today.year &&
          todo.dueDate!.month == today.month &&
          todo.dueDate!.day == today.day;
    }).length;
  }

  int get overdueTodos {
    final now = DateTime.now();
    return _todos.where((todo) {
      return todo.dueDate != null &&
          todo.dueDate!.isBefore(now) &&
          !todo.isCompleted;
    }).length;
  }

  // Load todos from local Hive storage
  Future<void> _loadFromLocal() async {
    if (_todoBox == null) return;

    try {
      _todos = _todoBox!.values.toList();
      debugPrint('Loaded ${_todos.length} todos from local storage');
    } catch (e) {
      debugPrint('Error loading from local storage: $e');
      _todos = [];
    }
  }

  // Save todo to local storage
  Future<void> _saveToLocal(Todo todo) async {
    if (_todoBox == null) return;

    try {
      await _todoBox!.put(todo.id, todo);
      debugPrint('Saved todo ${todo.id} to local storage');
    } catch (e) {
      debugPrint('Error saving to local storage: $e');
    }
  }

  // Delete todo from local storage
  Future<void> _deleteFromLocal(String todoId) async {
    if (_todoBox == null) return;

    try {
      await _todoBox!.delete(todoId);
      debugPrint('Deleted todo $todoId from local storage');
    } catch (e) {
      debugPrint('Error deleting from local storage: $e');
    }
  }

  // Sync with cloud (if enabled and authenticated)
  Future<void> _syncWithCloud() async {
    if (!_cloudSyncEnabled || !_supabaseService.isAuthenticated) return;

    try {
      debugPrint('Syncing with cloud...');

      // Get cloud todos
      final cloudTodos = await _supabaseService.getTasks();

      // Merge with local todos (cloud takes precedence for conflicts)
      final Map<String, Todo> todoMap = {};

      // Add local todos first
      for (final todo in _todos) {
        todoMap[todo.id] = todo;
      }

      // Override with cloud todos
      for (final cloudTodo in cloudTodos) {
        final todo = Todo.fromJson(cloudTodo);
        todoMap[todo.id] = todo;
        await _saveToLocal(todo); // Save to local storage
      }

      _todos = todoMap.values.toList();
      debugPrint('Cloud sync completed. Total todos: ${_todos.length}');
    } catch (e) {
      debugPrint('Error syncing with cloud: $e');
      // Continue with local data if cloud sync fails
    }
  }

  // Add new todo
  Future<void> addTodo(Todo todo) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Add to local list immediately
      _todos.add(todo);

      // Save to local storage
      await _saveToLocal(todo);

      // If cloud sync is enabled, try to save to cloud
      if (_cloudSyncEnabled && _supabaseService.isAuthenticated) {
        try {
          await _supabaseService.createTask(
            title: todo.title,
            description: todo.description,
            dueDate: todo.dueDate,
            priority: todo.priority,
            categoryId: todo.categoryId,
          );
          debugPrint('Todo ${todo.id} saved to cloud');
        } catch (e) {
          debugPrint('Failed to save todo to cloud: $e');
          // Continue with local save
        }
      }

      debugPrint('Todo added successfully: ${todo.title}');
    } catch (e) {
      _error = 'Failed to add todo: $e';
      debugPrint('Error adding todo: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update existing todo
  Future<void> updateTodo(Todo todo) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Update in local list
      final index = _todos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        _todos[index] = todo;

        // Save to local storage
        await _saveToLocal(todo);

        // If cloud sync is enabled, try to update in cloud
        if (_cloudSyncEnabled && _supabaseService.isAuthenticated) {
          try {
            await _supabaseService.updateTask(
              taskId: todo.id,
              title: todo.title,
              description: todo.description,
              dueDate: todo.dueDate,
              priority: todo.priority,
              categoryId: todo.categoryId,
              isCompleted: todo.isCompleted,
            );
            debugPrint('Todo ${todo.id} updated in cloud');
          } catch (e) {
            debugPrint('Failed to update todo in cloud: $e');
            // Continue with local update
          }
        }

        debugPrint('Todo updated successfully: ${todo.title}');
      }
    } catch (e) {
      _error = 'Failed to update todo: $e';
      debugPrint('Error updating todo: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete todo
  Future<void> deleteTodo(String todoId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Remove from local list
      _todos.removeWhere((todo) => todo.id == todoId);

      // Delete from local storage
      await _deleteFromLocal(todoId);

      // If cloud sync is enabled, try to delete from cloud
      if (_cloudSyncEnabled && _supabaseService.isAuthenticated) {
        try {
          await _supabaseService.deleteTask(todoId);
          debugPrint('Todo $todoId deleted from cloud');
        } catch (e) {
          debugPrint('Failed to delete todo from cloud: $e');
          // Continue with local delete
        }
      }

      debugPrint('Todo deleted successfully: $todoId');
    } catch (e) {
      _error = 'Failed to delete todo: $e';
      debugPrint('Error deleting todo: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle completion status
  Future<void> toggleTodoCompletion(String todoId) async {
    final todo = _todos.firstWhere((t) => t.id == todoId);
    final updatedTodo = todo.copyWith(
      isCompleted: !todo.isCompleted,
      completionDate: !todo.isCompleted ? DateTime.now() : null,
    );
    await updateTodo(updatedTodo);
  }

  // Search and filter methods
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterOption(String filter) {
    _filterOption = filter;
    notifyListeners();
  }

  void setSortOrder(String order) {
    _sortOrder = order;
    notifyListeners();
  }

  void setCategoryFilter(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterOption = 'all';
    _selectedCategoryId = null;
    notifyListeners();
  }

  // Get todos by category
  List<Todo> getTodosByCategory(String categoryId) {
    return _todos.where((todo) => todo.categoryId == categoryId).toList();
  }

  // Force refresh
  Future<void> refresh() async {
    await initialize();
  }

  // Load tasks method for compatibility
  Future<void> loadTasks() async {
    await initialize();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _todoBox?.close();
    super.dispose();
  }
}
