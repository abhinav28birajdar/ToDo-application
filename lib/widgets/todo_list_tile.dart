import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/todo.dart';
import '../providers/hybrid_category_provider.dart';

class TodoListTile extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TodoListTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<HybridCategoryProvider>(
      builder: (context, categoryProvider, child) {
        final category = todo.categoryId != null
            ? categoryProvider.getCategoryById(todo.categoryId!)
            : null;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getPriorityColor().withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              leading: _buildLeading(category),
              title: _buildTitle(context),
              subtitle: _buildSubtitle(context, category),
              trailing: _buildTrailing(context),
              onTap: onEdit,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeading(category) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Checkbox
        Checkbox(
          value: todo.isCompleted,
          onChanged: (bool? newValue) => onToggle(),
          activeColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        // Category icon (if available)
        if (category != null)
          Container(
            margin: const EdgeInsets.only(left: 4),
            child: Icon(
              category.iconData,
              color: category.color,
              size: 20,
            ),
          ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      children: [
        // Priority indicator
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _getPriorityColor(),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        // Title text
        Expanded(
          child: Text(
            todo.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
              color: todo.isCompleted ? Colors.grey[600] : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Due date indicator
        if (todo.dueDate != null) _buildDueDateChip(),
      ],
    );
  }

  Widget _buildSubtitle(BuildContext context, category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        if (todo.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            todo.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        const SizedBox(height: 8),

        // Tags
        if (todo.tags.isNotEmpty) ...[
          Wrap(
            spacing: 4,
            children: todo.tags
                .take(3)
                .map(
                  (tag) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
        ],

        // Bottom row with creation date and category
        Row(
          children: [
            // Creation date
            Icon(Icons.schedule, size: 12, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              'Created: ${DateFormat.MMMd().format(todo.creationDate)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),

            // Category name
            if (category != null) ...[
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 10,
                    color: category.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            const Spacer(),

            // Notification indicator
            if (todo.hasNotification && !todo.isCompleted)
              Icon(
                Icons.notifications_active,
                size: 14,
                color: Colors.orange[600],
              ),
          ],
        ),

        // Due date details (if overdue or due today)
        if (todo.dueDate != null && (todo.isOverdue || todo.isDueToday)) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                todo.isOverdue ? Icons.warning : Icons.today,
                size: 14,
                color: todo.isOverdue ? Colors.red[700] : Colors.orange[700],
              ),
              const SizedBox(width: 4),
              Text(
                todo.isOverdue
                    ? 'Overdue since ${DateFormat.MMMd().format(todo.dueDate!)}'
                    : 'Due today at ${DateFormat.jm().format(todo.dueDate!)}',
                style: TextStyle(
                  fontSize: 11,
                  color: todo.isOverdue ? Colors.red[700] : Colors.orange[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Edit button
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue[600], size: 20),
            onPressed: onEdit,
            tooltip: 'Edit Todo',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
          // Delete button
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red[600], size: 20),
            onPressed: onDelete,
            tooltip: 'Delete Todo',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateChip() {
    if (todo.dueDate == null) return const SizedBox.shrink();

    Color chipColor;
    String chipText;
    IconData chipIcon;

    if (todo.isCompleted) {
      chipColor = Colors.green;
      chipText = 'Done';
      chipIcon = Icons.check_circle;
    } else if (todo.isOverdue) {
      chipColor = Colors.red;
      chipText = 'Overdue';
      chipIcon = Icons.warning;
    } else if (todo.isDueToday) {
      chipColor = Colors.orange;
      chipText = 'Today';
      chipIcon = Icons.today;
    } else {
      final daysUntilDue = todo.dueDate!.difference(DateTime.now()).inDays;
      if (daysUntilDue <= 7) {
        chipColor = Colors.amber;
        chipText = '${daysUntilDue}d';
        chipIcon = Icons.schedule;
      } else {
        chipColor = Colors.blue;
        chipText = DateFormat.MMMd().format(todo.dueDate!);
        chipIcon = Icons.calendar_today;
      }
    }

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            chipText,
            style: TextStyle(
              fontSize: 10,
              color: chipColor,
              fontWeight: FontWeight.bold,
            ),
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
}
