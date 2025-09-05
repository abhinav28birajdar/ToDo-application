import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/todo_provider.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../models/todo.dart';
import '../models/category.dart';

class AddEditTodoScreen extends StatefulWidget {
  final Todo? todo; // Optional todo to edit

  const AddEditTodoScreen({super.key, this.todo});

  @override
  State<AddEditTodoScreen> createState() => _AddEditTodoScreenState();
}

class _AddEditTodoScreenState extends State<AddEditTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;

  DateTime? _selectedDueDate;
  DateTime? _selectedDueTime;
  String? _selectedCategoryId;
  int _selectedPriority = 2; // Default medium priority
  List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();
  bool _hasNotification = false;
  DateTime? _notificationTime;

  bool get _isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeFields();
  }

  void _initializeControllers() {
    _titleController = TextEditingController(
      text: _isEditing ? widget.todo!.title : '',
    );
    _descriptionController = TextEditingController(
      text: _isEditing ? widget.todo!.description : '',
    );
    _notesController = TextEditingController(
      text: _isEditing ? widget.todo!.notes ?? '' : '',
    );
  }

  void _initializeFields() {
    if (_isEditing) {
      final todo = widget.todo!;
      _selectedDueDate = todo.dueDate;
      _selectedDueTime = todo.dueDate;
      _selectedCategoryId = todo.categoryId;
      _selectedPriority = todo.priority;
      _tags = List.from(todo.tags);
      _hasNotification = todo.hasNotification;
      _notificationTime = todo.notificationTime;
    } else {
      // Set defaults from settings
      final settings = context.read<SettingsProvider>().settings;
      _selectedPriority = settings.defaultPriority;
      _selectedCategoryId = settings.defaultCategoryId.isNotEmpty
          ? settings.defaultCategoryId
          : null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Todo' : 'Add New Todo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTodo,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'e.g., Buy groceries',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title.';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
                maxLength: 100,
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g., Milk, eggs, bread...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                maxLength: 500,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // Priority Selection
              _buildPrioritySection(),
              const SizedBox(height: 16),

              // Category Selection
              _buildCategorySection(),
              const SizedBox(height: 16),

              // Due Date and Time Section
              _buildDateTimeSection(),
              const SizedBox(height: 16),

              // Notification Section
              _buildNotificationSection(),
              const SizedBox(height: 16),

              // Tags Section
              _buildTagsSection(),
              const SizedBox(height: 16),

              // Notes Field
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  hintText: 'Any additional information...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 4,
                maxLength: 1000,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveTodo,
                      icon: Icon(_isEditing ? Icons.save : Icons.add),
                      label: Text(_isEditing ? 'Save Changes' : 'Add Todo'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Priority',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<int>(
                    title: const Text('High'),
                    subtitle: const Text('🔴'),
                    value: 1,
                    groupValue: _selectedPriority,
                    onChanged: (value) =>
                        setState(() => _selectedPriority = value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<int>(
                    title: const Text('Medium'),
                    subtitle: const Text('🟡'),
                    value: 2,
                    groupValue: _selectedPriority,
                    onChanged: (value) =>
                        setState(() => _selectedPriority = value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<int>(
                    title: const Text('Low'),
                    subtitle: const Text('🟢'),
                    value: 3,
                    groupValue: _selectedPriority,
                    onChanged: (value) =>
                        setState(() => _selectedPriority = value!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Category',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => _showAddCategoryDialog(),
                      child: const Text('Add New'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select a category',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No Category'),
                    ),
                    ...categoryProvider.categories.map(
                      (category) => DropdownMenuItem<String?>(
                        value: category.id,
                        child: Row(
                          children: [
                            Icon(category.iconData, color: category.color),
                            const SizedBox(width: 8),
                            Text(category.name),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedCategoryId = value),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Due Date & Time',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text(_selectedDueDate == null
                        ? 'No due date'
                        : DateFormat.yMMMEd().format(_selectedDueDate!)),
                    subtitle: const Text('Date'),
                    leading: const Icon(Icons.calendar_today),
                    onTap: () => _selectDueDate(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListTile(
                    title: Text(_selectedDueTime == null
                        ? 'No time'
                        : DateFormat.jm().format(_selectedDueTime!)),
                    subtitle: const Text('Time'),
                    leading: const Icon(Icons.access_time),
                    onTap: _selectedDueDate != null
                        ? () => _selectDueTime()
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedDueDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _clearDueDate(),
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notification',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: _hasNotification,
                  onChanged: _selectedDueDate != null
                      ? (value) => setState(() {
                            _hasNotification = value;
                            if (value && _notificationTime == null) {
                              _setDefaultNotificationTime();
                            }
                          })
                      : null,
                ),
              ],
            ),
            if (_hasNotification && _selectedDueDate != null) ...[
              const SizedBox(height: 16),
              const Text('Remind me:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildNotificationChip('At due time', 0),
                  _buildNotificationChip('15 min before', 15),
                  _buildNotificationChip('1 hour before', 60),
                  _buildNotificationChip('1 day before', 1440),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text(_notificationTime == null
                    ? 'Custom time'
                    : 'Notification: ${DateFormat.yMMMEd().add_jm().format(_notificationTime!)}'),
                leading: const Icon(Icons.notifications),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectNotificationTime(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ],
            if (_selectedDueDate == null)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Set a due date to enable notifications',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationChip(String label, int minutesBefore) {
    final isSelected = _notificationTime != null &&
        _selectedDueDate != null &&
        _notificationTime!.isAtSameMomentAs(
          _selectedDueDate!.subtract(Duration(minutes: minutesBefore)),
        );

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected && _selectedDueDate != null) {
          setState(() {
            _notificationTime =
                _selectedDueDate!.subtract(Duration(minutes: minutesBefore));
          });
        }
      },
    );
  }

  Widget _buildTagsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tags',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      hintText: 'Add a tag',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addTag,
                      ),
                    ),
                    onFieldSubmitted: (_) => _addTag(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: () => _removeTag(tag),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (date != null) {
      setState(() {
        _selectedDueDate = date;
        // Combine with existing time or set to end of day
        if (_selectedDueTime != null) {
          _selectedDueDate = DateTime(
            date.year,
            date.month,
            date.day,
            _selectedDueTime!.hour,
            _selectedDueTime!.minute,
          );
        } else {
          _selectedDueDate = DateTime(date.year, date.month, date.day, 23, 59);
          _selectedDueTime = _selectedDueDate;
        }
        // Reset notification if it was set
        if (_hasNotification) {
          _setDefaultNotificationTime();
        }
      });
    }
  }

  Future<void> _selectDueTime() async {
    if (_selectedDueDate == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _selectedDueTime != null
          ? TimeOfDay.fromDateTime(_selectedDueTime!)
          : const TimeOfDay(hour: 23, minute: 59),
    );
    if (time != null) {
      setState(() {
        _selectedDueTime = DateTime(
          _selectedDueDate!.year,
          _selectedDueDate!.month,
          _selectedDueDate!.day,
          time.hour,
          time.minute,
        );
        _selectedDueDate = _selectedDueTime;
        // Update notification time if it was set
        if (_hasNotification) {
          _setDefaultNotificationTime();
        }
      });
    }
  }

  void _clearDueDate() {
    setState(() {
      _selectedDueDate = null;
      _selectedDueTime = null;
      _hasNotification = false;
      _notificationTime = null;
    });
  }

  Future<void> _selectNotificationTime() async {
    if (_selectedDueDate == null) return;

    final date = await showDatePicker(
      context: context,
      initialDate: _notificationTime ??
          _selectedDueDate!.subtract(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: _selectedDueDate!,
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: _notificationTime != null
            ? TimeOfDay.fromDateTime(_notificationTime!)
            : const TimeOfDay(hour: 9, minute: 0),
      );
      if (time != null) {
        setState(() {
          _notificationTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _setDefaultNotificationTime() {
    if (_selectedDueDate == null) return;

    final settings = context.read<SettingsProvider>().settings;
    final minutesBefore = settings.reminderMinutesBefore;

    setState(() {
      _notificationTime =
          _selectedDueDate!.subtract(Duration(minutes: minutesBefore));
    });
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _showAddCategoryDialog() {
    // TODO: Implement add category dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add category functionality coming soon!')),
    );
  }

  void _saveTodo() {
    if (_formKey.currentState!.validate()) {
      final todoProvider = context.read<TodoProvider>();

      if (_isEditing) {
        // Update existing todo
        final updatedTodo = widget.todo!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dueDate: _selectedDueDate,
          categoryId: _selectedCategoryId,
          priority: _selectedPriority,
          tags: _tags,
          hasNotification: _hasNotification,
          notificationTime: _notificationTime,
          notes: _notesController.text.trim(),
        );
        todoProvider.updateTodo(updatedTodo);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todo updated successfully!')),
        );
      } else {
        // Add new todo
        final newTodo = Todo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          isCompleted: false,
          creationDate: DateTime.now(),
          dueDate: _selectedDueDate,
          categoryId: _selectedCategoryId,
          priority: _selectedPriority,
          tags: _tags,
          hasNotification: _hasNotification,
          notificationTime: _notificationTime,
          notes: _notesController.text.trim(),
        );
        todoProvider.addTodo(newTodo);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todo added successfully!')),
        );
      }

      Navigator.pop(context);
    }
  }
}
