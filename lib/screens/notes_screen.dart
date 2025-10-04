import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/note.dart';
import '../services/supabase_service.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/rich_text_editor.dart';
import 'add_edit_note_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedTag;
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseService = SupabaseService();
      final notesData = await supabaseService.getNotes();

      setState(() {
        _notes.clear();
        _notes.addAll(notesData.map((data) => Note.fromSupabase(data)));
        _filterNotes();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notes: $e')),
      );
    }
  }

  void _filterNotes() {
    setState(() {
      _filteredNotes = _notes.where((note) {
        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!note.title.toLowerCase().contains(query) &&
              !note.content.toLowerCase().contains(query)) {
            return false;
          }
        }

        // Apply tag filter
        if (_selectedTag != null && !note.tags.contains(_selectedTag)) {
          return false;
        }

        // Apply favorites filter
        if (_showFavoritesOnly && !note.isFavorite) {
          return false;
        }

        return true;
      }).toList();

      // Sort by updated date (newest first)
      _filteredNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedTag = null;
      _showFavoritesOnly = false;
      _filterNotes();
    });
  }

  Future<void> _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final supabaseService = SupabaseService();
        await supabaseService.deleteNote(note.id);

        setState(() {
          _notes.remove(note);
          _filterNotes();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note "${note.title}" deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting note: $e')),
        );
      }
    }
  }

  Future<void> _toggleFavorite(Note note) async {
    try {
      final supabaseService = SupabaseService();
      final updates = {
        'is_favorite': !note.isFavorite,
      };

      await supabaseService.updateNote(
        noteId: note.id,
        isPinned: updates['is_pinned'],
        isArchived: updates['is_archived'],
      );

      setState(() {
        final index = _notes.indexWhere((n) => n.id == note.id);
        if (index != -1) {
          _notes[index] = note.copyWith(isFavorite: !note.isFavorite);
          _filterNotes();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating favorite status: $e')),
      );
    }
  }

  Future<void> _shareNote(Note note) async {
    final contentToShare = isRichTextContent(note.content)
        ? richTextToPlainText(note.content)
        : note.content;

    await Share.share(
      '${note.title}\n\n$contentToShare',
      subject: note.title,
    );
  }

  Future<void> _shareNoteWithUser(Note note) async {
    final TextEditingController emailController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Enter the email of the user you want to share this note with:'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'user@example.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Share'),
          ),
        ],
      ),
    );

    if (confirmed == true && emailController.text.trim().isNotEmpty) {
      try {
        final email = emailController.text.trim();
        final supabaseService = SupabaseService();

        await supabaseService.shareNote(note.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note shared with $email')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing note: $e')),
        );
      }
    }
  }

  Future<void> _copyToClipboard(Note note) async {
    final textToCopy = isRichTextContent(note.content)
        ? richTextToPlainText(note.content)
        : note.content;

    await Clipboard.setData(ClipboardData(text: textToCopy));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note content copied to clipboard')),
    );
  }

  Set<String> _getAllTags() {
    final Set<String> tags = {};
    for (final note in _notes) {
      tags.addAll(note.tags);
    }
    return tags;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Notes'),
        content: StatefulBuilder(
          builder: (context, setState) {
            final allTags = _getAllTags().toList()..sort();

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tags:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedTag == null,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedTag = null;
                          });
                        }
                      },
                    ),
                    ...allTags.map((tag) => FilterChip(
                          label: Text(tag),
                          selected: _selectedTag == tag,
                          onSelected: (selected) {
                            setState(() {
                              _selectedTag = selected ? tag : null;
                            });
                          },
                        )),
                  ],
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Favorites only'),
                  value: _showFavoritesOnly,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    setState(() {
                      _showFavoritesOnly = value ?? false;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _filterNotes();
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddEditNote([Note? note]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditNoteScreen(note: note),
      ),
    ).then((_) => _loadNotes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Search Notes'),
                  content: SearchBarWidget(
                    initialQuery: _searchQuery,
                    onSearch: (query) {
                      setState(() {
                        _searchQuery = query;
                        _filterNotes();
                      });
                      Navigator.pop(context);
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_filters') {
                _clearFilters();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_filters',
                child: Text('Clear Filters'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredNotes.isEmpty
              ? _buildEmptyState()
              : _buildNotesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditNote(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty || _selectedTag != null || _showFavoritesOnly) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'No notes match your filters',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'No notes yet',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to create your first note',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        final note = _filteredNotes[index];
        return _buildNoteCard(note);
      },
    );
  }

  Widget _buildNoteCard(Note note) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToAddEditNote(note),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                note.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                DateFormat('MMM d, yyyy • h:mm a').format(note.updatedAt),
                style: theme.textTheme.bodySmall,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      note.isFavorite ? Icons.star : Icons.star_border,
                      color: note.isFavorite ? Colors.amber : null,
                    ),
                    onPressed: () => _toggleFavorite(note),
                    tooltip: note.isFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _navigateToAddEditNote(note);
                          break;
                        case 'delete':
                          _deleteNote(note);
                          break;
                        case 'share':
                          _shareNote(note);
                          break;
                        case 'share_user':
                          _shareNoteWithUser(note);
                          break;
                        case 'copy':
                          _copyToClipboard(note);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: ListTile(
                          leading: Icon(Icons.share),
                          title: Text('Share'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share_user',
                        child: ListTile(
                          leading: Icon(Icons.person_add),
                          title: Text('Share with User'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'copy',
                        child: ListTile(
                          leading: Icon(Icons.content_copy),
                          title: Text('Copy Content'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (note.content.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: isRichTextContent(note.content)
                    ? Container(
                        height: 60,
                        child: RichTextDisplay(
                          content: note.content,
                        ),
                      )
                    : Text(
                        note.preview,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            if (note.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Wrap(
                  spacing: 8,
                  children: note.tags
                      .map((tag) => Chip(
                            label: Text(tag),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
