import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/category.dart' as CategoryModel;

/// Hybrid Category Provider for managing category state with local storage and optional cloud sync
/// Version: 3.0.0 (September 9, 2025)
class HybridCategoryProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<CategoryModel.Category> _categories = [];
  bool _isLoading = false;
  String? _error;
  bool _cloudSyncEnabled = false;

  // Hive box for local storage
  Box<CategoryModel.Category>? _categoryBox;

  // Initialize
  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if cloud sync is enabled
      _cloudSyncEnabled = dotenv.env['ENABLE_CLOUD_SYNC'] == 'true';

      // Initialize Hive box
      try {
        _categoryBox = await Hive.openBox<CategoryModel.Category>(
            dotenv.env['CATEGORIES_BOX_NAME'] ?? 'categories');
      } catch (e) {
        debugPrint('Error opening Hive category box: $e');
        _categoryBox = await Hive.openBox<CategoryModel.Category>('categories');
      }

      // Load categories from local storage first
      await _loadFromLocal();

      // If no categories exist, create default ones
      if (_categories.isEmpty) {
        await _createDefaultCategories();
      }

      // If cloud sync is enabled and user is authenticated, sync with cloud
      if (_cloudSyncEnabled && _supabaseService.isAuthenticated) {
        await _syncWithCloud();
      }
    } catch (e) {
      _error = 'Failed to initialize categories: $e';
      debugPrint('CategoryProvider initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Getters
  List<CategoryModel.Category> get categories => _categories;
  
  List<CategoryModel.Category> get defaultCategories =>
      _categories.where((category) => category.isDefault).toList();
  
  List<CategoryModel.Category> get userCategories =>
      _categories.where((category) => !category.isDefault).toList();  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load categories from local Hive storage
  Future<void> _loadFromLocal() async {
    if (_categoryBox == null) return;

    try {
      _categories = _categoryBox!.values.toList();
      debugPrint('Loaded ${_categories.length} categories from local storage');
    } catch (e) {
      debugPrint('Error loading categories from local storage: $e');
      _categories = [];
    }
  }

  // Save category to local storage
  Future<void> _saveToLocal(CategoryModel.Category category) async {
    if (_categoryBox == null) return;

    try {
      await _categoryBox!.put(category.id, category);
      debugPrint('Saved category ${category.id} to local storage');
    } catch (e) {
      debugPrint('Error saving category to local storage: $e');
    }
  }

  // Delete category from local storage
  Future<void> _deleteFromLocal(String categoryId) async {
    if (_categoryBox == null) return;

    try {
      await _categoryBox!.delete(categoryId);
      debugPrint('Deleted category $categoryId from local storage');
    } catch (e) {
      debugPrint('Error deleting category from local storage: $e');
    }
  }

  // Create default categories
  Future<void> _createDefaultCategories() async {
    final defaultCats = [
      CategoryModel.Category.withColor(
        id: 'default_work',
        name: 'Work',
        description: 'Work-related tasks and projects',
        color: Colors.blue,
        iconData: Icons.work,
        isDefault: true,
      ),
      CategoryModel.Category.withColor(
        id: 'default_personal',
        name: 'Personal',
        description: 'Personal tasks and activities',
        color: Colors.green,
        iconData: Icons.home,
        isDefault: true,
      ),
      CategoryModel.Category.withColor(
        id: 'default_shopping',
        name: 'Shopping',
        description: 'Shopping lists and errands',
        color: Colors.orange,
        iconData: Icons.shopping_cart,
        isDefault: true,
      ),
      CategoryModel.Category.withColor(
        id: 'default_health',
        name: 'Health',
        description: 'Health and fitness activities',
        color: Colors.red,
        iconData: Icons.local_hospital,
        isDefault: true,
      ),
      CategoryModel.Category.withColor(
        id: 'default_education',
        name: 'Education',
        description: 'Learning and educational tasks',
        color: Colors.purple,
        iconData: Icons.school,
        isDefault: true,
      ),
    ];

    for (final category in defaultCats) {
      await _saveToLocal(category);
      _categories.add(category);
    }

    debugPrint('Created ${defaultCats.length} default categories');
  }

  // Sync with cloud (if enabled and authenticated)
  Future<void> _syncWithCloud() async {
    if (!_cloudSyncEnabled || !_supabaseService.isAuthenticated) return;

    try {
      debugPrint('Syncing categories with cloud...');

      // Get cloud categories
      final cloudCategories = await _supabaseService.getCategories();

      // Merge with local categories (cloud takes precedence for conflicts)
      final Map<String, CategoryModel.Category> categoryMap = {};

      // Add local categories first
      for (final category in _categories) {
        categoryMap[category.id] = category;
      }

      // Override with cloud categories
      for (final cloudCategory in cloudCategories) {
        final category = CategoryModel.Category.fromJson(cloudCategory);
        categoryMap[category.id] = category;
        await _saveToLocal(category); // Save to local storage
      }

      _categories = categoryMap.values.toList();
      debugPrint(
          'Category cloud sync completed. Total categories: ${_categories.length}');
    } catch (e) {
      debugPrint('Error syncing categories with cloud: $e');
      // Continue with local data if cloud sync fails
    }
  }

  // Add new category
  Future<void> addCategory(
    String name, {
    String description = '',
    Color color = Colors.blue,
    IconData iconData = Icons.category,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final category = CategoryModel.Category.withColor(
        id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: description,
        color: color,
        iconData: iconData,
        isDefault: false,
      );

      // Add to local list immediately
      _categories.add(category);

      // Save to local storage
      await _saveToLocal(category);

      // If cloud sync is enabled, try to save to cloud
      if (_cloudSyncEnabled && _supabaseService.isAuthenticated) {
        try {
          await _supabaseService.createCategory(
            name: name,
            description: description,
            color: color.toARGB32().toRadixString(16),
            icon: iconData.codePoint.toString(),
          );
          debugPrint('Category ${category.id} saved to cloud');
        } catch (e) {
          debugPrint('Failed to save category to cloud: $e');
          // Continue with local save
        }
      }

      debugPrint('Category added successfully: $name');
    } catch (e) {
      _error = 'Failed to add category: $e';
      debugPrint('Error adding category: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update existing category
  Future<void> updateCategory(CategoryModel.Category category) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Update in local list
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;

        // Save to local storage
        await _saveToLocal(category);

        // If cloud sync is enabled, try to update in cloud
        if (_cloudSyncEnabled && _supabaseService.isAuthenticated) {
          try {
            // TODO: Add updateCategory method to SupabaseService
            // await _supabaseService.updateCategory(
            //   categoryId: category.id,
            //   name: category.name,
            //   description: category.description,
            //   color: category.color.toARGB32().toRadixString(16),
            //   icon: category.iconData.codePoint.toString(),
            // );
            debugPrint('Category ${category.id} cloud update skipped - method not implemented');
          } catch (e) {
            debugPrint('Failed to update category in cloud: $e');
            // Continue with local update
          }
        }

        debugPrint('Category updated successfully: ${category.name}');
      }
    } catch (e) {
      _error = 'Failed to update category: $e';
      debugPrint('Error updating category: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Find the category
      final category = _categories.firstWhere((c) => c.id == categoryId);

      // Don't allow deletion of default categories
      if (category.isDefault) {
        _error = 'Cannot delete default categories';
        return;
      }

      // Remove from local list
      _categories.removeWhere((c) => c.id == categoryId);

      // Delete from local storage
      await _deleteFromLocal(categoryId);

      // If cloud sync is enabled, try to delete from cloud
      if (_cloudSyncEnabled && _supabaseService.isAuthenticated) {
        try {
          // TODO: Add deleteCategory method to SupabaseService
          // await _supabaseService.deleteCategory(categoryId);
          debugPrint('Category $categoryId cloud delete skipped - method not implemented');
        } catch (e) {
          debugPrint('Failed to delete category from cloud: $e');
          // Continue with local delete
        }
      }

      debugPrint('Category deleted successfully: $categoryId');
    } catch (e) {
      _error = 'Failed to delete category: $e';
      debugPrint('Error deleting category: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get category by ID
  CategoryModel.Category? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  // Get category by name
  CategoryModel.Category? getCategoryByName(String name) {
    try {
      return _categories.firstWhere((c) => c.name == name);
    } catch (e) {
      return null;
    }
  }

  // Force refresh
  Future<void> refresh() async {
    await initialize();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _categoryBox?.close();
    super.dispose();
  }
}
