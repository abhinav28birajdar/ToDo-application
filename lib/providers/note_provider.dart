import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

/// Note Provider for managing notes state using Supabase
/// Version: 2.0.0 (September 8, 2025)
class NoteProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Map<String, dynamic>> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get filtered notes
  List<Map<String, dynamic>> getFilteredNotes({
    bool? isFavorite,
    bool? isPinned,
    String? categoryId,
    List<String>? tags,
  }) {
    return _notes.where((note) {
      if (isFavorite != null && note['is_favorite'] != isFavorite) {
        return false;
      }
      if (isPinned != null && note['is_pinned'] != isPinned) {
        return false;
      }
      if (categoryId != null && note['category_id'] != categoryId) {
        return false;
      }
      if (tags != null && tags.isNotEmpty) {
        final noteTags = List<String>.from(note['tags'] ?? []);
        if (!tags.any((tag) => noteTags.contains(tag))) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // Load notes from Supabase
  Future<void> loadNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notes = await _supabaseService.getNotes();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _notes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search notes
  Future<List<Map<String, dynamic>>> searchNotes(String query) async {
    try {
      return await _supabaseService.searchNotes(query);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Create a new note
  Future<bool> createNote({
    required String title,
    String? content,
    String contentType = 'text',
    bool isFavorite = false,
    bool isPinned = false,
    List<String>? tags,
    String? categoryId,
    String folderPath = '/',
  }) async {
    try {
      final newNote = await _supabaseService.createNote(
        title: title,
        content: content,
        contentType: contentType,
        isFavorite: isFavorite,
        isPinned: isPinned,
        tags: tags,
        categoryId: categoryId,
        folderPath: folderPath,
      );

      _notes.insert(0, newNote);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update an existing note
  Future<bool> updateNote({
    required String noteId,
    String? title,
    String? content,
    bool? isFavorite,
    bool? isPinned,
    List<String>? tags,
    String? categoryId,
  }) async {
    try {
      // For now, we'll implement a basic update
      // In a real implementation, you'd add updateNote to SupabaseService
      final index = _notes.indexWhere((note) => note['id'] == noteId);
      if (index != -1) {
        final note = Map<String, dynamic>.from(_notes[index]);
        if (title != null) note['title'] = title;
        if (content != null) note['content'] = content;
        if (isFavorite != null) note['is_favorite'] = isFavorite;
        if (isPinned != null) note['is_pinned'] = isPinned;
        if (tags != null) note['tags'] = tags;
        if (categoryId != null) note['category_id'] = categoryId;
        note['updated_at'] = DateTime.now().toIso8601String();

        _notes[index] = note;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Toggle note favorite
  Future<bool> toggleNoteFavorite(String noteId) async {
    final note = _notes.firstWhere((n) => n['id'] == noteId);
    return await updateNote(
      noteId: noteId,
      isFavorite: !note['is_favorite'],
    );
  }

  // Toggle note pinned
  Future<bool> toggleNotePinned(String noteId) async {
    final note = _notes.firstWhere((n) => n['id'] == noteId);
    return await updateNote(
      noteId: noteId,
      isPinned: !note['is_pinned'],
    );
  }

  // Delete a note
  Future<bool> deleteNote(String noteId) async {
    try {
      // For now, we'll implement a basic delete
      // In a real implementation, you'd add deleteNote to SupabaseService
      _notes.removeWhere((note) => note['id'] == noteId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
