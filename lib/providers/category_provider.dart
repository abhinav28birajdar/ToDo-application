import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  static String get _categoryBoxName =>
      dotenv.env['CATEGORIES_BOX_NAME'] ?? 'categories';

  late Box<Category> _categoryBox;
  List<Category> _categories = [];

  List<Category> get categories => _categories;
  List<Category> get defaultCategories =>
      _categories.where((cat) => cat.isDefault).toList();
  List<Category> get userCategories =>
      _categories.where((cat) => !cat.isDefault).toList();

  CategoryProvider() {
    _initHive();
  }

  Future<void> _initHive() async {
    try {
      if (!Hive.isBoxOpen(_categoryBoxName)) {
        _categoryBox = await Hive.openBox<Category>(_categoryBoxName);
      } else {
        _categoryBox = Hive.box<Category>(_categoryBoxName);
      }

      _categories = _categoryBox.values.toList();
      _categories.sort((a, b) => a.name.compareTo(b.name));

      // Create default categories if none exist
      if (_categories.isEmpty) {
        await _createDefaultCategories();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing Category Hive box: $e');
    }
  }

  Future<void> _createDefaultCategories() async {
    const uuid = Uuid();

    final defaultCategories = [
      Category(
        id: uuid.v4(),
        name: 'Personal',
        description: 'Personal tasks and activities',
        colorValue: Colors.blue.value,
        iconData: Icons.person,
        creationDate: DateTime.now(),
        isDefault: true,
      ),
      Category(
        id: uuid.v4(),
        name: 'Work',
        description: 'Work-related tasks',
        colorValue: Colors.orange.value,
        iconData: Icons.work,
        creationDate: DateTime.now(),
        isDefault: true,
      ),
      Category(
        id: uuid.v4(),
        name: 'Shopping',
        description: 'Shopping lists and purchases',
        colorValue: Colors.green.value,
        iconData: Icons.shopping_cart,
        creationDate: DateTime.now(),
        isDefault: true,
      ),
      Category(
        id: uuid.v4(),
        name: 'Health',
        description: 'Health and fitness related tasks',
        colorValue: Colors.red.value,
        iconData: Icons.favorite,
        creationDate: DateTime.now(),
        isDefault: true,
      ),
      Category(
        id: uuid.v4(),
        name: 'Education',
        description: 'Learning and educational tasks',
        colorValue: Colors.purple.value,
        iconData: Icons.school,
        creationDate: DateTime.now(),
        isDefault: true,
      ),
    ];

    for (final category in defaultCategories) {
      await _categoryBox.put(category.id, category);
      _categories.add(category);
    }

    _categories.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> addCategory(
    String name, {
    String description = '',
    required Color color,
    required IconData iconData,
  }) async {
    try {
      const uuid = Uuid();
      final newCategory = Category(
        id: uuid.v4(),
        name: name,
        description: description,
        colorValue: color.value,
        iconData: iconData,
        creationDate: DateTime.now(),
        isDefault: false,
      );

      await _categoryBox.put(newCategory.id, newCategory);
      _categories.add(newCategory);
      _categories.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding category: $e');
      rethrow;
    }
  }

  Future<void> updateCategory(Category updatedCategory) async {
    try {
      final index =
          _categories.indexWhere((cat) => cat.id == updatedCategory.id);
      if (index != -1) {
        _categories[index] = updatedCategory;
        await _categoryBox.put(updatedCategory.id, updatedCategory);
        _categories.sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      // Don't allow deletion of default categories
      final category = getCategoryById(id);
      if (category?.isDefault == true) {
        throw Exception('Cannot delete default categories');
      }

      await _categoryBox.delete(id);
      _categories.removeWhere((cat) => cat.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    }
  }

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  Category? getCategoryByName(String name) {
    try {
      return _categories
          .firstWhere((cat) => cat.name.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> exportCategories() async {
    try {
      final categoriesJson = _categories
          .map((category) => {
                'id': category.id,
                'name': category.name,
                'description': category.description,
                'colorValue': category.colorValue,
                'iconData': category.iconData.codePoint,
                'creationDate': category.creationDate.toIso8601String(),
                'isDefault': category.isDefault,
              })
          .toList();

      return {
        'version': '1.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'categoriesCount': _categories.length,
        'categories': categoriesJson,
      };
    } catch (e) {
      debugPrint('Error exporting categories: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _categoryBox.close();
    super.dispose();
  }
}
