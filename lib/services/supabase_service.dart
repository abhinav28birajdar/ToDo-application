import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import '../config/supabase_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Supabase client
  SupabaseClient get client => Supabase.instance.client;

  // Auth helpers
  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  String get userId => currentUser?.id ?? '';

  // Connection status
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize Supabase with your project credentials
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    try {
      debugPrint('🔄 Initializing Supabase with URL: $url');

      // Check if the URL is reachable before attempting to initialize
      try {
        // Extract the domain from the Supabase URL
        final uri = Uri.parse(url);
        final domain = uri.host;

        debugPrint('Checking connectivity to Supabase host: $domain');

        // Try to resolve the domain
        final lookupResult = await InternetAddress.lookup(domain)
            .timeout(const Duration(seconds: 5));

        if (lookupResult.isEmpty || lookupResult[0].rawAddress.isEmpty) {
          throw Exception('Could not resolve Supabase host: $domain');
        }

        debugPrint('✅ Supabase host is reachable');
      } catch (e) {
        debugPrint('❌ Could not reach Supabase host: $e');
        throw Exception(
            'Could not connect to Supabase. Please check your internet connection and Supabase URL.');
      }

      // Initialize Supabase
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: SupabaseConfig.debugMode,
      );

      // Test the connection with a simple ping
      try {
        // A simple query to verify the connection works
        await Supabase.instance.client
            .from('user_profiles')
            .select('count')
            .limit(1)
            .count()
            .timeout(const Duration(seconds: 5));

        debugPrint('✅ Supabase connection verified successfully');
        _instance._isInitialized = true;
      } catch (e) {
        debugPrint('⚠️ Supabase connection test failed: $e');
        // We continue anyway since the initialization succeeded
        // The connection might be working for other operations
        _instance._isInitialized = true;
      }

      debugPrint('✅ Supabase initialized successfully');
    } catch (e) {
      debugPrint('❌ Supabase initialization failed: $e');
      _instance._isInitialized = false;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('host lookup') ||
          e.toString().contains('No address associated with hostname') ||
          e.toString().contains('internet connection')) {
        throw Exception(
            'Network error: Cannot connect to Supabase. Please check your internet connection and try again.');
      } else {
        throw Exception('Failed to initialize Supabase: $e');
      }
    }
  }

  // ===============================
  // Task Methods
  // ===============================

  /// Get all tasks for the current user
  Future<List<Map<String, dynamic>>> getTasks() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User is not authenticated');
      }

      final response = await client
          .from('tasks')
          .select('*, categories(*)')
          .eq('user_id', currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  /// Create a new task for the current user
  Future<Map<String, dynamic>> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    DateTime? notificationTime,
    int priority = 2,
    String? categoryId,
    List<String>? tags,
    String? location,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User is not authenticated');
      }

      final task = {
        'user_id': currentUser!.id,
        'title': title,
        'description': description,
        'due_date': dueDate?.toIso8601String(),
        'priority': priority,
        'category_id': categoryId,
        'tags': tags,
        'status': 'pending',
      };

      final response = await client
          .from('tasks')
          .insert(task)
          .select('*, categories(*)')
          .single();

      return response;
    } catch (e) {
      debugPrint('Error creating task: $e');
      throw Exception('Failed to create task: $e');
    }
  }

  /// Update an existing task
  Future<Map<String, dynamic>> updateTask({
    required String taskId,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? dueDate,
    DateTime? notificationTime,
    int? priority,
    String? categoryId,
    List<String>? tags,
    String? location,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User is not authenticated');
      }

      final task = <String, dynamic>{};

      if (title != null) task['title'] = title;
      if (description != null) task['description'] = description;
      if (isCompleted != null) task['is_completed'] = isCompleted;
      if (dueDate != null) task['due_date'] = dueDate.toIso8601String();
      if (priority != null) task['priority'] = priority;
      if (categoryId != null) task['category_id'] = categoryId;
      if (tags != null) task['tags'] = tags;

      final response = await client
          .from('tasks')
          .update(task)
          .eq('id', taskId)
          .eq('user_id', currentUser!.id)
          .select('*, categories(*)')
          .single();

      return response;
    } catch (e) {
      debugPrint('Error updating task: $e');
      throw Exception('Failed to update task: $e');
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User is not authenticated');
      }

      await client
          .from('tasks')
          .delete()
          .eq('id', taskId)
          .eq('user_id', currentUser!.id);
    } catch (e) {
      debugPrint('Error deleting task: $e');
      throw Exception('Failed to delete task: $e');
    }
  }

  // ===============================
  // Category Methods
  // ===============================

  /// Get all categories for the current user
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User is not authenticated');
      }

      final response = await client
          .from('categories')
          .select()
          .eq('user_id', currentUser!.id)
          .order('sort_order', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Create a new category
  Future<Map<String, dynamic>> createCategory({
    required String name,
    String? description,
    String color = '#007AFF',
    String icon = 'folder',
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User is not authenticated');
      }

      final category = {
        'user_id': currentUser!.id,
        'name': name,
        'description': description,
        'color': color,
        'icon': icon,
      };

      final response =
          await client.from('categories').insert(category).select().single();

      return response;
    } catch (e) {
      debugPrint('Error creating category: $e');
      throw Exception('Failed to create category: $e');
    }
  }

  /// Update an existing category
  Future<Map<String, dynamic>> updateCategory({
    required String categoryId,
    String? name,
    String? description,
    String? color,
    String? icon,
    int? sortOrder,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User is not authenticated');
      }

      final category = <String, dynamic>{};

      if (name != null) category['name'] = name;
      if (description != null) category['description'] = description;
      if (color != null) category['color'] = color;
      if (icon != null) category['icon'] = icon;
      if (sortOrder != null) category['sort_order'] = sortOrder;

      final response = await client
          .from('categories')
          .update(category)
          .eq('id', categoryId)
          .eq('user_id', currentUser!.id)
          .select()
          .single();

      return response;
    } catch (e) {
      debugPrint('Error updating category: $e');
      throw Exception('Failed to update category: $e');
    }
  }

  /// Delete a category
  Future<void> deleteCategory(String categoryId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User is not authenticated');
      }

      await client
          .from('categories')
          .delete()
          .eq('id', categoryId)
          .eq('user_id', currentUser!.id);
    } catch (e) {
      debugPrint('Error deleting category: $e');
      throw Exception('Failed to delete category: $e');
    }
  }

  // ===============================
  // Notes Methods
  // ===============================

  /// Get all notes for the current user
  Future<List<Map<String, dynamic>>> getNotes() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User is not authenticated');
      }

      final response = await client
          .from('notes')
          .select('*, categories(*)')
          .eq('user_id', currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching notes: $e');
      throw Exception('Failed to fetch notes: $e');
    }
  }

  /// Search notes by query
  Future<List<Map<String, dynamic>>> searchNotes(String query) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User is not authenticated');
      }

      final lowerQuery = query.toLowerCase();
      final response = await client
          .from('notes')
          .select('*, categories(*)')
          .eq('user_id', currentUser!.id)
          .or('title.ilike.%$lowerQuery%,content.ilike.%$lowerQuery%')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error searching notes: $e');
      throw Exception('Failed to search notes: $e');
    }
  }

  /// Create a new note
  Future<Map<String, dynamic>> createNote({
    required String title,
    String? content,
    String? contentType,
    String? categoryId,
    List<String>? tags,
    String? color,
    bool isPinned = false,
    bool isFavorite = false,
    String? folderPath,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User is not authenticated');
      }

      final note = {
        'user_id': currentUser!.id,
        'title': title,
        'content': content,
        'content_type': contentType ?? 'text',
        'category_id': categoryId,
        'tags': tags,
        'color': color ?? '#007AFF',
        'is_pinned': isPinned,
        'is_favorite': isFavorite,
        'folder_path': folderPath ?? '/',
      };

      final response = await client
          .from('notes')
          .insert(note)
          .select('*, categories(*)')
          .single();

      return response;
    } catch (e) {
      debugPrint('Error creating note: $e');
      throw Exception('Failed to create note: $e');
    }
  }

  /// Update an existing note
  Future<Map<String, dynamic>> updateNote({
    required String noteId,
    String? title,
    String? content,
    String? categoryId,
    List<String>? tags,
    String? color,
    bool? isPinned,
    bool? isArchived,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User is not authenticated');
      }

      final note = <String, dynamic>{};

      if (title != null) note['title'] = title;
      if (content != null) note['content'] = content;
      if (categoryId != null) note['category_id'] = categoryId;
      if (tags != null) note['tags'] = tags;
      if (color != null) note['color'] = color;
      if (isPinned != null) note['is_pinned'] = isPinned;
      if (isArchived != null) note['is_archived'] = isArchived;

      final response = await client
          .from('notes')
          .update(note)
          .eq('id', noteId)
          .eq('user_id', currentUser!.id)
          .select('*, categories(*)')
          .single();

      return response;
    } catch (e) {
      debugPrint('Error updating note: $e');
      throw Exception('Failed to update note: $e');
    }
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User is not authenticated');
      }

      await client
          .from('notes')
          .delete()
          .eq('id', noteId)
          .eq('user_id', currentUser!.id);
    } catch (e) {
      debugPrint('Error deleting note: $e');
      throw Exception('Failed to delete note: $e');
    }
  }

  /// Share a note (placeholder for future implementation)
  Future<String> shareNote(String noteId) async {
    try {
      // This could be implemented with a sharing mechanism
      // For now, it's a placeholder that returns the note ID
      return noteId;
    } catch (e) {
      debugPrint('Error sharing note: $e');
      throw Exception('Failed to share note: $e');
    }
  }

  // ===============================
  // Settings Methods
  // ===============================

  /// Get user settings
  Future<Map<String, dynamic>> getSettings() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User is not authenticated');
      }

      final response =
          await client.from('settings').select().eq('user_id', currentUser!.id);

      // Convert the response to a key-value map
      final settings = <String, dynamic>{};
      for (final setting in response) {
        settings[setting['setting_key']] = setting['setting_value'];
      }

      return settings;
    } catch (e) {
      debugPrint('Error fetching settings: $e');
      throw Exception('Failed to fetch settings: $e');
    }
  }

  /// Update user settings
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User is not authenticated');
      }

      // For each setting, update or insert
      for (final entry in settings.entries) {
        final key = entry.key;
        final value = entry.value;

        // Check if the setting exists
        final existing = await client
            .from('settings')
            .select()
            .eq('user_id', currentUser!.id)
            .eq('setting_key', key)
            .maybeSingle();

        if (existing != null) {
          // Update existing setting
          await client
              .from('settings')
              .update({'setting_value': value}).eq('id', existing['id']);
        } else {
          // Insert new setting
          await client.from('settings').insert({
            'user_id': currentUser!.id,
            'setting_key': key,
            'setting_value': value,
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating settings: $e');
      throw Exception('Failed to update settings: $e');
    }
  }
}
