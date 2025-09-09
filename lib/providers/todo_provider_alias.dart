// Temporary alias for TodoProvider to use TaskProvider
// This is a quick fix to resolve provider mismatch issues

import 'task_provider.dart';

// For now, TodoProvider is just an alias for TaskProvider
typedef TodoProvider = TaskProvider;

// Helper methods to make TodoProvider interface compatible
extension TodoProviderExtension on TaskProvider {
  // Add any methods that screens expect from TodoProvider
  List<Map<String, dynamic>> get todos => tasks;
  List<Map<String, dynamic>> get allTodos => tasks;

  int get totalTodos => tasks.length;
  int get activeTodos =>
      tasks.where((task) => !(task['is_completed'] ?? false)).length;
  int get completedTodos =>
      tasks.where((task) => task['is_completed'] ?? false).length;
  int get overdueTodos {
    final now = DateTime.now();
    return tasks.where((task) {
      final dueDate = task['due_date'];
      if (dueDate == null) return false;
      final due = DateTime.tryParse(dueDate);
      return due != null &&
          due.isBefore(now) &&
          !(task['is_completed'] ?? false);
    }).length;
  }

  int get dueTodayTodos {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return tasks.where((task) {
      final dueDate = task['due_date'];
      if (dueDate == null) return false;
      final due = DateTime.tryParse(dueDate);
      return due != null &&
          due.isAfter(startOfDay) &&
          due.isBefore(endOfDay) &&
          !(task['is_completed'] ?? false);
    }).length;
  }

  String get searchQuery => '';
  String get filterOption => 'all';
  String get sortOrder => 'creation_date_desc';
  String? get selectedCategoryId => null;
  String? get errorMessage => error;

  // Mock methods that screens might call
  Future<void> fetchTasks() async {
    await loadTasks();
  }

  void setSearchQuery(String query) {
    // Implementation would go here
  }

  void setFilterOption(String filter) {
    // Implementation would go here
  }

  void setCategoryFilter(String? categoryId) {
    // Implementation would go here
  }

  Future<void> addTask(dynamic task) async {
    // Implementation would go here
  }

  Future<void> updateTask(dynamic task) async {
    // Implementation would go here
  }

  Future<void> deleteTask(String taskId) async {
    // Implementation would go here
  }

  Future<void> toggleTask(String taskId) async {
    // Implementation would go here
  }
}
