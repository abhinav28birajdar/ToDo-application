import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService with ChangeNotifier {
  static late final SupabaseClient _client;
  bool _isSessionExpired = false;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      // Configure auto refresh before token expiration
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
    );

    _client = Supabase.instance.client;
  }

  bool get isSessionExpired => _isSessionExpired;

  // Method to refresh the token
  Future<bool> refreshSession() async {
    try {
      final response = await client.auth.refreshSession();
      _isSessionExpired = false;
      notifyListeners();
      return response.session != null;
    } catch (e) {
      // If refresh fails, we need to re-authenticate
      _isSessionExpired = true;
      notifyListeners();
      return false;
    }
  }

  static SupabaseClient get client => _client;

  // Authentication methods

  /// Sign up a new user
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Get the current user
  User? get currentUser => client.auth.currentUser;

  /// Check if a user is signed in
  bool get isSignedIn => currentUser != null;

  /// Reset password
  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  /// Listen to auth state changes
  Stream<AuthState> get onAuthStateChange => client.auth.onAuthStateChange;

  /// Wrapper for API calls to handle token expiration
  Future<T> _handleApiCall<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
    } on AuthException catch (e) {
      // Check if it's a JWT expiration error
      if (e.message.contains('JWT') && e.message.contains('expired')) {
        // Try to refresh the token
        final refreshed = await refreshSession();
        if (refreshed) {
          // Retry the API call if refresh was successful
          return await apiCall();
        } else {
          _isSessionExpired = true;
          notifyListeners();
          throw Exception('Session expired. Please log in again.');
        }
      }
      rethrow;
    }
  }

  // User profile methods

  /// Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    if (currentUser == null) throw Exception('User not authenticated');

    return _handleApiCall(() async {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();

      if (response == null) {
        throw Exception('Profile not found');
      }

      return response;
    });
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateUserProfile(
      Map<String, dynamic> profileData) async {
    if (currentUser == null) throw Exception('User not authenticated');

    return _handleApiCall(() async {
      final response = await client
          .from('profiles')
          .update(profileData)
          .eq('id', currentUser!.id)
          .select()
          .single();

      return response;
    });
  }

  /// Upload user avatar
  Future<String> uploadAvatar(List<int> fileBytes, String fileName) async {
    if (currentUser == null) throw Exception('User not authenticated');

    return _handleApiCall(() async {
      final Uint8List uint8List = Uint8List.fromList(fileBytes);

      final fileExt = fileName.split('.').last;
      final filePath = '${currentUser!.id}/avatar.$fileExt';

      await client.storage.from('avatars').uploadBinary(filePath, uint8List);

      final imageUrlResponse =
          client.storage.from('avatars').getPublicUrl(filePath);

      // Update the user profile with the new avatar URL
      await updateUserProfile({
        'avatar_url': imageUrlResponse,
        'updated_at': DateTime.now().toIso8601String()
      });

      return imageUrlResponse;
    });
  }

  /// Delete user avatar
  Future<void> deleteAvatar() async {
    if (currentUser == null) throw Exception('User not authenticated');

    // Get current profile to find avatar path
    final profile = await getUserProfile();
    final avatarUrl = profile['avatar_url'] as String?;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      // Extract path from URL
      final uri = Uri.parse(avatarUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2) {
        final filePath = '${currentUser!.id}/${pathSegments.last}';

        // Delete from storage
        await client.storage.from('avatars').remove([filePath]);
      }
    }

    // Update profile to remove avatar_url
    await updateUserProfile(
        {'avatar_url': null, 'updated_at': DateTime.now().toIso8601String()});
  }

  // Database methods - Tasks

  /// Create a new task
  Future<Map<String, dynamic>> createTask(Map<String, dynamic> taskData) async {
    final response =
        await client.from('tasks').insert(taskData).select().single();

    return response;
  }

  /// Get all tasks for the current user
  Future<List<Map<String, dynamic>>> getTasks() async {
    if (currentUser == null) return [];

    final response = await client
        .from('tasks')
        .select()
        .eq('user_id', currentUser!.id)
        .order('due_date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Update an existing task
  Future<Map<String, dynamic>> updateTask(
      String id, Map<String, dynamic> taskData) async {
    final response = await client
        .from('tasks')
        .update(taskData)
        .eq('id', id)
        .select()
        .single();

    return response;
  }

  /// Delete a task
  Future<void> deleteTask(String id) async {
    await client.from('tasks').delete().eq('id', id);
  }

  // Database methods - Notes

  /// Create a new note
  Future<Map<String, dynamic>> createNote(Map<String, dynamic> noteData) async {
    final response =
        await client.from('notes').insert(noteData).select().single();

    return response;
  }

  /// Get all notes for the current user
  Future<List<Map<String, dynamic>>> getNotes() async {
    if (currentUser == null) return [];

    final response = await client
        .from('notes')
        .select()
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Update an existing note
  Future<Map<String, dynamic>> updateNote(
      String id, Map<String, dynamic> noteData) async {
    final response = await client
        .from('notes')
        .update(noteData)
        .eq('id', id)
        .select()
        .single();

    return response;
  }

  /// Delete a note
  Future<void> deleteNote(String id) async {
    await client.from('notes').delete().eq('id', id);
  }

  /// Share a note with another user
  Future<void> shareNote(String noteId, String recipientEmail) async {
    // First, get the recipient's user ID
    final recipientData = await client
        .from('profiles')
        .select('id')
        .eq('email', recipientEmail)
        .maybeSingle();

    if (recipientData == null) {
      throw Exception('User not found');
    }

    final recipientId = recipientData['id'];

    // Then share the note by creating a note_shares record
    await client.from('note_shares').insert({
      'note_id': noteId,
      'user_id': recipientId,
      'shared_by': currentUser!.id,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get notes shared with the current user
  Future<List<Map<String, dynamic>>> getSharedNotes() async {
    if (currentUser == null) return [];

    final response = await client
        .from('notes')
        .select('''
          *,
          note_shares!inner(user_id)
        ''')
        .eq('note_shares.user_id', currentUser!.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Database methods - Categories

  /// Create a new category
  Future<Map<String, dynamic>> createCategory(
      Map<String, dynamic> categoryData) async {
    final response =
        await client.from('categories').insert(categoryData).select().single();

    return response;
  }

  /// Get all categories for the current user
  Future<List<Map<String, dynamic>>> getCategories() async {
    if (currentUser == null) return [];

    final response =
        await client.from('categories').select().eq('user_id', currentUser!.id);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Update an existing category
  Future<Map<String, dynamic>> updateCategory(
      String id, Map<String, dynamic> categoryData) async {
    final response = await client
        .from('categories')
        .update(categoryData)
        .eq('id', id)
        .select()
        .single();

    return response;
  }

  /// Delete a category
  Future<void> deleteCategory(String id) async {
    await client.from('categories').delete().eq('id', id);
  }
}
