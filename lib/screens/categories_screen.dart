import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/hybrid_category_provider.dart';
import '../providers/hybrid_task_provider.dart';
import '../models/category.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(context),
          ),
        ],
      ),
      body: Consumer2<HybridCategoryProvider, HybridTaskProvider>(
        builder: (context, categoryProvider, taskProvider, child) {
          if (categoryProvider.categories.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No categories yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add categories to organize your todos',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Default Categories Section
              if (categoryProvider.defaultCategories.isNotEmpty) ...[
                _buildSectionHeader('Default Categories'),
                const SizedBox(height: 8),
                ...categoryProvider.defaultCategories.map(
                  (category) => _buildCategoryTile(
                      context, category, categoryProvider, taskProvider),
                ),
                const SizedBox(height: 24),
              ],

              // User Categories Section
              if (categoryProvider.userCategories.isNotEmpty) ...[
                _buildSectionHeader('My Categories'),
                const SizedBox(height: 8),
                ...categoryProvider.userCategories.map(
                  (category) => _buildCategoryTile(
                      context, category, categoryProvider, taskProvider),
                ),
              ],

              // Add Category Button
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showAddCategoryDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add New Category'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    Category category,
    HybridCategoryProvider categoryProvider,
    HybridTaskProvider taskProvider,
  ) {
    final todosInCategory = taskProvider.getTodosByCategory(category.id);
    final completedCount =
        todosInCategory.where((todo) => todo.isCompleted).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category.color,
          child: Icon(
            category.iconData,
            color: Colors.white,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category.description.isNotEmpty) Text(category.description),
            const SizedBox(height: 4),
            Text(
              '${todosInCategory.length} todos, $completedCount completed',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleCategoryAction(
            context,
            value,
            category,
            categoryProvider,
            taskProvider,
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('View Todos'),
                dense: true,
              ),
            ),
            if (!category.isDefault)
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit'),
                  dense: true,
                ),
              ),
            if (!category.isDefault)
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  dense: true,
                ),
              ),
          ],
        ),
        onTap: () => _viewCategoryTodos(context, category, taskProvider),
      ),
    );
  }

  void _handleCategoryAction(
    BuildContext context,
    String action,
    Category category,
    HybridCategoryProvider categoryProvider,
    HybridTaskProvider taskProvider,
  ) {
    switch (action) {
      case 'view':
        _viewCategoryTodos(context, category, taskProvider);
        break;
      case 'edit':
        _showEditCategoryDialog(context, category);
        break;
      case 'delete':
        _showDeleteCategoryDialog(
            context, category, categoryProvider, taskProvider);
        break;
    }
  }

  void _viewCategoryTodos(BuildContext context, Category category,
      HybridTaskProvider taskProvider) {
    // Set category filter and navigate back to home
    taskProvider.setCategoryFilter(category.id);
    Navigator.pop(context);
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddEditCategoryDialog(),
    );
  }

  void _showEditCategoryDialog(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (context) => AddEditCategoryDialog(category: category),
    );
  }

  void _showDeleteCategoryDialog(
    BuildContext context,
    Category category,
    HybridCategoryProvider categoryProvider,
    HybridTaskProvider taskProvider,
  ) {
    final todosInCategory = taskProvider.getTodosByCategory(category.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${category.name}"?'),
            if (todosInCategory.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'This category has ${todosInCategory.length} todo(s). They will not be deleted, but their category will be removed.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              categoryProvider.deleteCategory(category.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${category.name}" deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class AddEditCategoryDialog extends StatefulWidget {
  final Category? category;

  const AddEditCategoryDialog({super.key, this.category});

  @override
  State<AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends State<AddEditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late Color _selectedColor;
  late IconData _selectedIcon;

  bool get _isEditing => widget.category != null;

  // Predefined colors for categories
  final List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.indigo,
    Colors.brown,
    Colors.grey,
    Colors.cyan,
  ];

  // Predefined icons for categories
  final List<IconData> _icons = [
    Icons.work,
    Icons.home,
    Icons.school,
    Icons.shopping_cart,
    Icons.fitness_center,
    Icons.restaurant,
    Icons.local_hospital,
    Icons.directions_car,
    Icons.flight,
    Icons.music_note,
    Icons.book,
    Icons.sports_soccer,
    Icons.pets,
    Icons.beach_access,
    Icons.camera_alt,
    Icons.computer,
    Icons.phone,
    Icons.email,
    Icons.favorite,
    Icons.star,
    Icons.lightbulb,
    Icons.palette,
    Icons.build,
    Icons.nature,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: _isEditing ? widget.category!.name : '',
    );
    _descriptionController = TextEditingController(
      text: _isEditing ? widget.category!.description : '',
    );
    _selectedColor = _isEditing ? widget.category!.color : _colors.first;
    _selectedIcon = _isEditing ? widget.category!.iconData : _icons.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Category' : 'Add New Category'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name.';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // Color Selection
              const Text(
                'Color:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _colors
                    .map(
                      (color) => GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColor == color
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: _selectedColor == color
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Icon Selection
              const Text(
                'Icon:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _icons.length,
                  itemBuilder: (context, index) {
                    final icon = _icons[index];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = icon),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedIcon == icon
                              ? _selectedColor
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedIcon == icon
                                ? _selectedColor
                                : Colors.grey,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: _selectedIcon == icon
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Preview
              const SizedBox(height: 16),
              const Text(
                'Preview:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _selectedColor,
                      child: Icon(_selectedIcon, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.isEmpty
                                ? 'Category Name'
                                : _nameController.text,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (_descriptionController.text.isNotEmpty)
                            Text(
                              _descriptionController.text,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveCategory,
          child: Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  void _saveCategory() {
    if (_formKey.currentState!.validate()) {
      final categoryProvider = context.read<HybridCategoryProvider>();

      if (_isEditing) {
        // Update existing category
        final updatedCategory = widget.category!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          colorValue: _selectedColor.toARGB32(),
          iconData: _selectedIcon,
        );
        categoryProvider.updateCategory(updatedCategory);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category updated successfully!')),
        );
      } else {
        // Add new category
        categoryProvider.addCategory(
          _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          color: _selectedColor,
          iconData: _selectedIcon,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added successfully!')),
        );
      }

      Navigator.pop(context);
    }
  }
}
