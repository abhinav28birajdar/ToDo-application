import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/todo.dart';
import '../providers/hybrid_task_provider.dart';
import '../providers/hybrid_category_provider.dart';
import '../widgets/rich_text_editor.dart';
import 'add_edit_todo_screen.dart';

class TodoDetailScreen extends StatelessWidget {
  final Todo todo;

  const TodoDetailScreen({Key? key, required this.todo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<HybridCategoryProvider>(
      builder: (context, categoryProvider, child) {
        final category = todo.categoryId != null
            ? categoryProvider.getCategoryById(todo.categoryId!)
            : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Todo Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _navigateToEditScreen(context),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(context, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: ListTile(
                      leading: Icon(Icons.copy),
                      title: Text('Duplicate'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and completion status
                _buildTitleSection(context),
                const SizedBox(height: 24),

                // Priority and category
                _buildMetadataSection(context, category),
                const SizedBox(height: 24),

                // Description
                if (todo.description.isNotEmpty) ...[
                  _buildSectionCard(
                    context,
                    'Description',
                    Icons.description,
                    Text(
                      todo.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Rich Text Notes
                if (todo.notes != null && todo.notes!.isNotEmpty) ...[
                  _buildSectionCard(
                    context,
                    'Notes',
                    Icons.note,
                    Container(
                      height: 200,
                      child: isRichTextContent(todo.notes!)
                          ? RichTextDisplay(content: todo.notes!)
                          : Text(
                              todo.notes!,
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Due date and notifications
                if (todo.dueDate != null || todo.hasNotification) ...[
                  _buildDateTimeSection(context),
                  const SizedBox(height: 16),
                ],

                // Tags
                if (todo.tags.isNotEmpty) ...[
                  _buildTagsSection(context),
                  const SizedBox(height: 16),
                ],

                // Creation and completion dates
                _buildDatesSection(context),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _toggleCompletion(context),
            icon: Icon(todo.isCompleted ? Icons.undo : Icons.check),
            label: Text(todo.isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
            backgroundColor: todo.isCompleted ? Colors.orange : Colors.green,
          ),
        );
      },
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Completion checkbox
                Checkbox(
                  value: todo.isCompleted,
                  onChanged: (value) => _toggleCompletion(context),
                  activeColor: Colors.green,
                ),
                const SizedBox(width: 8),
                // Title
                Expanded(
                  child: Text(
                    todo.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                      color: todo.isCompleted ? Colors.grey[600] : null,
                    ),
                  ),
                ),
              ],
            ),
            if (todo.isCompleted && todo.completedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Completed on ${DateFormat('MMM d, yyyy • h:mm a').format(todo.completedAt!)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection(BuildContext context, category) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flag, color: _getPriorityColor()),
                      const SizedBox(width: 8),
                      const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(_getPriorityText(), style: TextStyle(color: _getPriorityColor())),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(category?.iconData ?? Icons.category, color: category?.color ?? Colors.grey),
                      const SizedBox(width: 8),
                      const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(category?.name ?? 'No Category'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(BuildContext context, String title, IconData icon, Widget content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Schedule',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (todo.dueDate != null) ...[
              ListTile(
                leading: Icon(
                  todo.isOverdue ? Icons.warning : Icons.calendar_today,
                  color: todo.isOverdue ? Colors.red : Colors.blue,
                ),
                title: const Text('Due Date'),
                subtitle: Text(
                  DateFormat('EEEE, MMM d, yyyy • h:mm a').format(todo.dueDate!),
                  style: TextStyle(
                    color: todo.isOverdue ? Colors.red : null,
                    fontWeight: todo.isOverdue ? FontWeight.w500 : null,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              if (todo.isOverdue && !todo.isCompleted)
                Padding(
                  padding: const EdgeInsets.only(left: 56),
                  child: Text(
                    'Overdue by ${DateTime.now().difference(todo.dueDate!).inDays} days',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
            if (todo.hasNotification && todo.notificationTime != null) ...[
              if (todo.dueDate != null) const Divider(),
              ListTile(
                leading: const Icon(Icons.notifications, color: Colors.orange),
                title: const Text('Notification'),
                subtitle: Text(
                  DateFormat('EEEE, MMM d, yyyy • h:mm a').format(todo.notificationTime!),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.label, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: todo.tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Timeline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
              title: const Text('Created'),
              subtitle: Text(
                DateFormat('EEEE, MMM d, yyyy • h:mm a').format(todo.creationDate),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            if (todo.isCompleted && todo.completedAt != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                title: const Text('Completed'),
                subtitle: Text(
                  DateFormat('EEEE, MMM d, yyyy • h:mm a').format(todo.completedAt!),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToEditScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTodoScreen(todo: todo),
      ),
    );
  }

  void _toggleCompletion(BuildContext context) {
    final provider = context.read<HybridTaskProvider>();
    provider.toggleTodoCompletion(todo.id);
    
    // Show snackbar with undo option
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          todo.isCompleted
              ? 'Todo marked as incomplete'
              : 'Todo marked as complete',
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => provider.toggleTodoCompletion(todo.id),
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final provider = context.read<HybridTaskProvider>();
    
    switch (action) {
      case 'duplicate':
        _duplicateTodo(context, provider);
        break;
      case 'delete':
        _showDeleteConfirmation(context, provider);
        break;
    }
  }

  void _duplicateTodo(BuildContext context, HybridTaskProvider provider) {
    final duplicatedTodo = todo.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '${todo.title} (Copy)',
      isCompleted: false,
      creationDate: DateTime.now(),
      completionDate: null,
    );
    
    provider.addTodo(duplicatedTodo);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Todo duplicated successfully')),
    );
  }

  void _showDeleteConfirmation(BuildContext context, HybridTaskProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo'),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTodo(todo.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Todo deleted successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor() {
    switch (todo.priority) {
      case 1: // High
        return Colors.red;
      case 2: // Medium
        return Colors.orange;
      case 3: // Low
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getPriorityText() {
    switch (todo.priority) {
      case 1:
        return 'High Priority';
      case 2:
        return 'Medium Priority';
      case 3:
        return 'Low Priority';
      default:
        return 'Normal Priority';
    }
  }
}