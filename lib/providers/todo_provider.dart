import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/todo.dart';
import '../services/notification_service.dart';

class TodoProvider extends ChangeNotifier {
  // Define constants for Hive box names from environment
  static String get _todoBoxName => dotenv.env['HIVE_BOX_NAME'] ?? 'todos';

  late Box<Todo> _todoBox;
  List<Todo> _todos = [];
  List<Todo> _filteredTodos = [];
  String _searchQuery = '';
  String _filterOption = 'all'; // 'all', 'active', 'completed'
  String _sortOrder = 'creation_date_desc';
  String? _selectedCategoryId;

  // Getters
  List<Todo> get todos => _filteredTodos;
  List<Todo> get allTodos => _todos;
  String get searchQuery => _searchQuery;
  String get filterOption => _filterOption;
  String get sortOrder => _sortOrder;
  String? get selectedCategoryId => _selectedCategoryId;

  // Statistics
  int get totalTodos => _todos.length;
  int get completedTodos => _todos.where((todo) => todo.isCompleted).length;
  int get activeTodos => _todos.where((todo) => !todo.isCompleted).length;
  int get overdueTodos => _todos.where((todo) => todo.isOverdue).length;
  int get dueTodayTodos => _todos.where((todo) => todo.isDueToday).length;

  TodoProvider() {
    _initHive();
  }

  // Initialize Hive box and load existing todos
  Future<void> _initHive() async {
    try {
      // Open the box, making sure it's not already open
      if (!Hive.isBoxOpen(_todoBoxName)) {
        _todoBox = await Hive.openBox<Todo>(_todoBoxName);
      } else {
        _todoBox = Hive.box<Todo>(_todoBoxName);
      }

      // Load todos from the box into our private list
      _todos = _todoBox.values.toList();
      _applyFiltersAndSort();
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing Todo Hive box: $e');
    }
  }

  // Apply current filters and sorting
  void _applyFiltersAndSort() {
    List<Todo> filtered = List.from(_todos);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((todo) {
        return todo.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            todo.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            todo.tags.any((tag) =>
                tag.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }

    // Apply completion filter
    switch (_filterOption) {
      case 'active':
        filtered = filtered.where((todo) => !todo.isCompleted).toList();
        break;
      case 'completed':
        filtered = filtered.where((todo) => todo.isCompleted).toList();
        break;
      case 'overdue':
        filtered = filtered.where((todo) => todo.isOverdue).toList();
        break;
      case 'due_today':
        filtered = filtered.where((todo) => todo.isDueToday).toList();
        break;
      case 'all':
      default:
        // No filter needed
        break;
    }

    // Apply category filter
    if (_selectedCategoryId != null) {
      filtered = filtered
          .where((todo) => todo.categoryId == _selectedCategoryId)
          .toList();
    }

    // Apply sorting
    switch (_sortOrder) {
      case 'creation_date_asc':
        filtered.sort((a, b) => a.creationDate.compareTo(b.creationDate));
        break;
      case 'creation_date_desc':
        filtered.sort((a, b) => b.creationDate.compareTo(a.creationDate));
        break;
      case 'due_date_asc':
        filtered.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case 'due_date_desc':
        filtered.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return b.dueDate!.compareTo(a.dueDate!);
        });
        break;
      case 'priority':
        filtered.sort((a, b) => a.priority.compareTo(b.priority));
        break;
      case 'title':
        filtered.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      default:
        filtered.sort((a, b) => b.creationDate.compareTo(a.creationDate));
        break;
    }

    _filteredTodos = filtered;
  }

  // Add a new todo item
  Future<void> addTodo(
    String title, {
    String description = '',
    DateTime? dueDate,
    String? categoryId,
    int priority = 2,
    List<String> tags = const [],
    bool hasNotification = false,
    DateTime? notificationTime,
    String? notes,
  }) async {
    try {
      const uuid = Uuid();
      final newTodo = Todo(
        id: uuid.v4(),
        title: title,
        description: description,
        creationDate: DateTime.now(),
        dueDate: dueDate,
        categoryId: categoryId,
        priority: priority,
        tags: tags,
        hasNotification: hasNotification,
        notificationTime: notificationTime,
        notes: notes,
      );

      // Add to Hive box
      await _todoBox.put(newTodo.id, newTodo);
      _todos.add(newTodo);

      // Schedule notification if requested
      if (hasNotification && notificationTime != null) {
        await NotificationService.scheduleNotification(newTodo);
      }

      _applyFiltersAndSort();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding todo: $e');
      rethrow;
    }
  }

  // Update an existing todo item
  Future<void> updateTodo(Todo updatedTodo) async {
    try {
      final index = _todos.indexWhere((todo) => todo.id == updatedTodo.id);
      if (index != -1) {
        final oldTodo = _todos[index];
        _todos[index] = updatedTodo;
        await _todoBox.put(updatedTodo.id, updatedTodo);

        // Handle notification updates
        if (oldTodo.hasNotification && !updatedTodo.hasNotification) {
          await NotificationService.cancelNotification(updatedTodo.id);
        } else if (updatedTodo.hasNotification &&
            updatedTodo.notificationTime != null) {
          await NotificationService.scheduleNotification(updatedTodo);
        }

        _applyFiltersAndSort();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating todo: $e');
      rethrow;
    }
  }

  // Toggle the completion status of a todo item
  Future<void> toggleTodoStatus(Todo todo) async {
    try {
      final now = DateTime.now();
      final updatedTodo = todo.copyWith(
        isCompleted: !todo.isCompleted,
        completionDate: !todo.isCompleted ? now : null,
      );

      // Cancel notification if todo is completed
      if (updatedTodo.isCompleted && todo.hasNotification) {
        await NotificationService.cancelNotification(todo.id);
      }

      await updateTodo(updatedTodo);
    } catch (e) {
      debugPrint('Error toggling todo status: $e');
      rethrow;
    }
  }

  // Delete a todo item
  Future<void> deleteTodo(String id) async {
    try {
      // Cancel any scheduled notification
      await NotificationService.cancelNotification(id);

      // Remove from Hive box
      await _todoBox.delete(id);

      // Remove from in-memory list
      _todos.removeWhere((todo) => todo.id == id);

      _applyFiltersAndSort();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting todo: $e');
      rethrow;
    }
  }

  // Batch operations
  Future<void> deleteCompletedTodos() async {
    try {
      final completedTodos = _todos.where((todo) => todo.isCompleted).toList();

      for (final todo in completedTodos) {
        await NotificationService.cancelNotification(todo.id);
        await _todoBox.delete(todo.id);
      }

      _todos.removeWhere((todo) => todo.isCompleted);
      _applyFiltersAndSort();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting completed todos: $e');
      rethrow;
    }
  }

  Future<void> markAllAsCompleted() async {
    try {
      final activeTodos = _todos.where((todo) => !todo.isCompleted).toList();
      final now = DateTime.now();

      for (final todo in activeTodos) {
        final updatedTodo = todo.copyWith(
          isCompleted: true,
          completionDate: now,
        );
        await _todoBox.put(updatedTodo.id, updatedTodo);
        await NotificationService.cancelNotification(todo.id);

        final index = _todos.indexWhere((t) => t.id == todo.id);
        if (index != -1) {
          _todos[index] = updatedTodo;
        }
      }

      _applyFiltersAndSort();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all todos as completed: $e');
      rethrow;
    }
  }

  // Search and filter methods
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setFilterOption(String filter) {
    _filterOption = filter;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setSortOrder(String order) {
    _sortOrder = order;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setCategoryFilter(String? categoryId) {
    _selectedCategoryId = categoryId;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterOption = 'all';
    _selectedCategoryId = null;
    _applyFiltersAndSort();
    notifyListeners();
  }

  // Get todos by category
  List<Todo> getTodosByCategory(String categoryId) {
    return _todos.where((todo) => todo.categoryId == categoryId).toList();
  }

  // Get todos by priority
  List<Todo> getTodosByPriority(int priority) {
    return _todos.where((todo) => todo.priority == priority).toList();
  }

  // Get todo by ID
  Todo? getTodoById(String id) {
    try {
      return _todos.firstWhere((todo) => todo.id == id);
    } catch (e) {
      return null;
    }
  }

  // Backup and restore
  Future<Map<String, dynamic>> exportTodos() async {
    try {
      final todosJson = _todos
          .map((todo) => {
                'id': todo.id,
                'title': todo.title,
                'description': todo.description,
                'isCompleted': todo.isCompleted,
                'creationDate': todo.creationDate.toIso8601String(),
                'dueDate': todo.dueDate?.toIso8601String(),
                'categoryId': todo.categoryId,
                'priority': todo.priority,
                'tags': todo.tags,
                'hasNotification': todo.hasNotification,
                'notificationTime': todo.notificationTime?.toIso8601String(),
                'completionDate': todo.completionDate?.toIso8601String(),
                'notes': todo.notes,
              })
          .toList();

      return {
        'version': '1.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'todosCount': _todos.length,
        'todos': todosJson,
      };
    } catch (e) {
      debugPrint('Error exporting todos: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _todoBox.close();
    super.dispose();
  }
}
