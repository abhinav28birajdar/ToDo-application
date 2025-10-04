import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../services/supabase_service.dart';
import '../widgets/drawing_pad.dart';
import '../widgets/rich_text_editor.dart';

class AddEditNoteScreen extends StatefulWidget {
  final Note? note;

  const AddEditNoteScreen({super.key, this.note});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _tagController;
  late List<String> _tags;
  late bool _isFavorite;
  late List<dynamic> _drawings;
  String _contentData = '';
  bool _isLoading = false;
  bool _contentChanged = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentData = widget.note?.content ?? '';
    _tagController = TextEditingController();
    _tags = widget.note?.tags.toList() ?? [];
    _isFavorite = widget.note?.isFavorite ?? false;
    _drawings = widget.note?.drawings ?? [];
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseService = SupabaseService();

      if (widget.note == null) {
        // Create new note
        await supabaseService.createNote(
          title: title,
          content: _contentData,
          contentType: 'text',
          isFavorite: _isFavorite,
          isPinned: false,
          tags: _tags,
          folderPath: '/',
        );
      } else {
        // Update existing note
        await supabaseService.updateNote(
          noteId: widget.note!.id,
          title: title,
          content: _contentData,
          tags: _tags,
          isPinned: widget.note?.isPinned,
        );
      }

      // Check if still mounted before accessing context
      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving note: $e')),
      );
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();

    if (tag.isEmpty) return;

    setState(() {
      if (!_tags.contains(tag)) {
        _tags.add(tag);
      }
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _updateDrawings(List<dynamic> drawings) {
    setState(() {
      _drawings = drawings;
      _contentChanged = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: _isFavorite ? Colors.amber : null,
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveNote,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.text_fields),
              text: "Text",
            ),
            Tab(
              icon: Icon(Icons.draw),
              text: "Drawing",
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Text tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Title',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),

                      const Divider(),

                      // Rich Text Content field
                      SizedBox(
                        height: 300,
                        child: RichTextEditor(
                          initialContent: _contentData,
                          onContentChanged: (content) {
                            _contentData = content;
                            if (!_contentChanged) {
                              setState(() {
                                _contentChanged = true;
                              });
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tags section
                      const Text(
                        'Tags',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _tagController,
                              decoration: const InputDecoration(
                                hintText: 'Add a tag',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onSubmitted: (_) => _addTag(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addTag,
                            child: const Text('Add'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags
                            .map((tag) => Chip(
                                  label: Text(tag),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () => _removeTag(tag),
                                ))
                            .toList(),
                      ),

                      if (widget.note != null && _contentChanged) ...[
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Theme.of(context).hintColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Last updated: ${DateFormat('MMM d, yyyy • h:mm a').format(widget.note!.updatedAt)}',
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Drawing tab
                DrawingPad(
                  drawings: _drawings,
                  onDrawingComplete: _updateDrawings,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                ),
              ],
            ),
    );
  }
}
