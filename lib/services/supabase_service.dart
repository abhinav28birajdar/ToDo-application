import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart'; // Temporarily disabled
import 'dart:io';
import 'dart:typed_data';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Supabase client
  SupabaseClient get client => Supabase.instance.client;

  // Auth helpers
  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  String? get userId => currentUser?.id;

  /// Initialize Supabase with your project credentials
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: false, // Set to true for development
    );
  }

  // ============================================================================
  // AUTHENTICATION METHODS
  // ============================================================================

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('Starting signup process for email: $email');

      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName ?? email.split('@')[0],
          'username': email.split('@')[0],
          ...?metadata,
        },
      );

      debugPrint('Auth response received: ${response.user?.id}');

      if (response.user != null) {
        try {
          await _createUserSession(response.user!);
          debugPrint('User session created successfully');
          await Future.delayed(const Duration(milliseconds: 500));

          // Verify profile was created, if not create it manually
          final profileExists = await _verifyProfile(response.user!.id);
          if (!profileExists) {
            debugPrint('Profile not found, creating manually...');
            await _createUserProfile(
                response.user!, fullName ?? email.split('@')[0], email);
          }
        } catch (profileError) {
          debugPrint('Profile setup error (non-fatal): $profileError');
          // Don't throw here as the auth user is already created
        }
      }

      return response;
    } catch (e) {
      debugPrint('Signup error: $e');
      throw _handleAuthError(e);
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _createUserSession(response.user!);
        await _updateLastLogin(response.user!.id);
      }

      return response;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Sign in with Google
  Future<AuthResponse> signInWithGoogle() async {
    try {
      // Configure Google Sign-In
      const List<String> scopes = ['email', 'profile'];

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: scopes,
        // Add your web client ID here for Android/iOS
        // serverClientId: 'your-google-client-id.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Google sign-in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw const AuthException('Failed to get Google authentication tokens');
      }

      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );

      if (response.user != null) {
        await _createUserSession(response.user!);
        await _updateLastLogin(response.user!.id);
      }

      return response;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Sign in with Facebook
  Future<AuthResponse> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        throw AuthException('Facebook sign-in failed: ${result.message}');
      }

      final AccessToken? accessToken = result.accessToken;
      if (accessToken == null) {
        throw const AuthException('Failed to get Facebook access token');
      }

      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.facebook,
        idToken: accessToken.token,
      );

      if (response.user != null) {
        await _createUserSession(response.user!);
        await _updateLastLogin(response.user!.id);
      }

      return response;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Sign in with Apple (iOS only) - Temporarily disabled
  Future<AuthResponse> signInWithApple() async {
    throw const AuthException(
        'Apple Sign-In temporarily unavailable due to Android build compatibility');

    /* TODO: Re-enable when sign_in_with_apple plugin compatibility is fixed
    try {
      if (!Platform.isIOS) {
        throw const AuthException('Apple Sign-In is only available on iOS');
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
      );

      if (response.user != null) {
        await _createUserSession(response.user!);
        await _updateLastLogin(response.user!.id);
      }

      return response;
    } catch (e) {
      throw _handleAuthError(e);
    }
    */
  }

  /// Send magic link for passwordless authentication
  Future<void> sendMagicLink({required String email}) async {
    try {
      await client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutterquickstart://reset-password-callback/',
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Update password
  Future<UserResponse> updatePassword({required String newPassword}) async {
    try {
      return await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      if (currentUser != null) {
        await _invalidateUserSessions(currentUser!.id);
      }
      await client.auth.signOut();
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      if (currentUser == null) {
        throw const AuthException('No user is currently signed in');
      }

      // Delete user data first
      await _deleteUserData(currentUser!.id);

      // Then delete the auth user (requires admin privileges)
      await client.auth.admin.deleteUser(currentUser!.id);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ============================================================================
  // PROFILE METHODS
  // ============================================================================

  /// Get current user profile
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    try {
      if (currentUser == null) return null;

      final response = await client
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();

      return response;
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? username,
    String? fullName,
    String? bio,
    String? phone,
    String? avatarUrl,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      if (currentUser == null) {
        throw const AuthException('No user is currently signed in');
      }

      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (fullName != null) updates['full_name'] = fullName;
      if (bio != null) updates['bio'] = bio;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (preferences != null) updates['preferences'] = preferences;

      if (updates.isNotEmpty) {
        await client.from('profiles').update(updates).eq('id', currentUser!.id);
      }
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  /// Upload avatar image
  Future<String> uploadAvatar({
    required String filePath,
    required List<int> fileBytes,
  }) async {
    try {
      if (currentUser == null) {
        throw const AuthException('No user is currently signed in');
      }

      final fileName = '${currentUser!.id}/avatar.png';

      await client.storage
          .from('avatars')
          .uploadBinary(fileName, Uint8List.fromList(fileBytes),
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ));

      final url = client.storage.from('avatars').getPublicUrl(fileName);

      // Update profile with new avatar URL
      await updateProfile(avatarUrl: url);

      return url;
    } catch (e) {
      throw _handleStorageError(e);
    }
  }

  // ============================================================================
  // TASK METHODS
  // ============================================================================

  /// Get all tasks for current user
  Future<List<Map<String, dynamic>>> getTasks({
    bool? isCompleted,
    String? categoryId,
    DateTime? dueBefore,
    int? priority,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      if (currentUser == null) {
        throw const AuthException('No user is currently signed in');
      }

      var queryBuilder = client
          .from('tasks')
          .select('*, categories(name, color, icon)')
          .eq('user_id', currentUser!.id);

      if (isCompleted != null) {
        queryBuilder = queryBuilder.eq('is_completed', isCompleted);
      }

      if (categoryId != null) {
        queryBuilder = queryBuilder.eq('category_id', categoryId);
      }

      if (dueBefore != null) {
        queryBuilder = queryBuilder.lt('due_date', dueBefore.toIso8601String());
      }

      if (priority != null) {
        queryBuilder = queryBuilder.eq('priority', priority);
      }

      final result = await queryBuilder
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return result;
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  /// Create a new task
  Future<Map<String, dynamic>> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    DateTime? notificationTime,
    int priority = 2,
    String? categoryId,
    String? parentTaskId,
    List<String>? tags,
    int? estimatedDuration,
    String? location,
    String? recurrence,
  }) async {
    try {
      if (currentUser == null) {
        throw const AuthException('No user is currently signed in');
      }

      final task = {
        'user_id': currentUser!.id,
        'title': title,
        'description': description,
        'due_date': dueDate?.toIso8601String(),
        'notification_time': notificationTime?.toIso8601String(),
        'priority': priority,
        'category_id': categoryId,
        'parent_task_id': parentTaskId,
        'tags': tags,
        'estimated_duration': estimatedDuration,
        'location': location,
        'recurrence': recurrence,
      };

      final response =
          await client.from('tasks').insert(task).select().single();

      await _logActivity('task_created', 'task', response['id'], response);

      return response;
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  /// Update a task
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
    int? actualDuration,
    String? location,
  }) async {
    try {
      if (currentUser == null) {
        throw const AuthException('No user is currently signed in');
      }

      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (isCompleted != null) {
        updates['is_completed'] = isCompleted;
        if (isCompleted) {
          updates['completed_date'] = DateTime.now().toIso8601String();
        } else {
          updates['completed_date'] = null;
        }
      }
      if (dueDate != null) updates['due_date'] = dueDate.toIso8601String();
      if (notificationTime != null)
        updates['notification_time'] = notificationTime.toIso8601String();
      if (priority != null) updates['priority'] = priority;
      if (categoryId != null) updates['category_id'] = categoryId;
      if (tags != null) updates['tags'] = tags;
      if (actualDuration != null) updates['actual_duration'] = actualDuration;
      if (location != null) updates['location'] = location;

      if (updates.isEmpty) {
        throw const DatabaseException('No updates provided');
      }

      final response = await client
          .from('tasks')
          .update(updates)
          .eq('id', taskId)
          .eq('user_id', currentUser!.id)
          .select()
          .single();

      await _logActivity('task_updated', 'task', taskId, updates);

      return response;
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      if (currentUser == null) {
        throw const AuthException('No user is currently signed in');
      }

      await client
          .from('tasks')
          .delete()
          .eq('id', taskId)
          .eq('user_id', currentUser!.id);

      await _logActivity('task_deleted', 'task', taskId, null);
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  // ============================================================================
  // CATEGORY METHODS
  // ============================================================================

  /// Get all categories for current user
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      if (currentUser == null) {
        throw const AuthException('No user is currently signed in');
      }

      return await client
          .from('categories')
          .select()
          .eq('user_id', currentUser!.id)
          .order('sort_order')
          .order('name');
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  /// Create a new category
  Future<Map<String, dynamic>> createCategory({
    required String name,
    String? description,
    required String color,
    String? icon,
    bool isDefault = false,
    int sortOrder = 0,
  }) async {
    try {
      if (currentUser == null) {
        throw const AuthException('No user is currently signed in');
      }

      final category = {
        'user_id': currentUser!.id,
        'name': name,
        'description': description,
        'color': color,
        'icon': icon,
        'is_default': isDefault,
        'sort_order': sortOrder,
      };

      return await client.from('categories').insert(category).select().single();
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  // ============================================================================
  // NOTES METHODS
  // ============================================================================

  /// Get all notes for current user
  Future<List<Map<String, dynamic>>> getNotes({
    bool? isFavorite,
    bool? isPinned,
    String? categoryId,
    List<String>? tags,
    String? searchQuery,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      if (currentUser == null) {
        throw const AuthException('No user is currently signed in');
      }

      var queryBuilder = client
          .from('notes')
          .select('*, categories(name, color)')
          .eq('user_id', currentUser!.id);

      if (isFavorite != null) {
        queryBuilder = queryBuilder.eq('is_favorite', isFavorite);
      }

      if (isPinned != null) {
        queryBuilder = queryBuilder.eq('is_pinned', isPinned);
      }

      if (categoryId != null) {
        queryBuilder = queryBuilder.eq('category_id', categoryId);
      }

      final result = await queryBuilder
          .order('is_pinned', ascending: false)
          .order('updated_at', ascending: false)
          .range(offset, offset + limit - 1);

      return result;
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  /// Search notes using full-text search
  Future<List<Map<String, dynamic>>> searchNotes(String searchQuery) async {
    try {
      if (currentUser == null) {
        throw const AuthException('No user is currently signed in');
      }

      return await client.rpc('search_notes', params: {
        'search_query': searchQuery,
        'user_uuid': currentUser!.id,
      });
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  /// Create a new note
  Future<Map<String, dynamic>> createNote({
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
      if (currentUser == null) {
        throw const AuthException('No user is currently signed in');
      }

      final note = {
        'user_id': currentUser!.id,
        'title': title,
        'content': content,
        'content_type': contentType,
        'is_favorite': isFavorite,
        'is_pinned': isPinned,
        'tags': tags,
        'category_id': categoryId,
        'folder_path': folderPath,
      };

      return await client.from('notes').insert(note).select().single();
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  /// Create a new note from Map
  Future<Map<String, dynamic>> createNoteFromMap(
      Map<String, dynamic> noteData) async {
    try {
      if (currentUser == null) {
        throw const AuthException('No user is currently signed in');
      }

      // Ensure user_id is set
      noteData['user_id'] = currentUser!.id;

      return await client.from('notes').insert(noteData).select().single();
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  /// Update a note
  Future<Map<String, dynamic>> updateNote(
      String noteId, Map<String, dynamic> updates) async {
    try {
      if (currentUser == null) {
        throw const AuthException('No user is currently signed in');
      }

      // Update the updated_at timestamp
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await client
          .from('notes')
          .update(updates)
          .eq('id', noteId)
          .eq('user_id', currentUser!.id)
          .select()
          .single();

      return response;
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    try {
      if (currentUser == null) {
        throw const AuthException('No user is currently signed in');
      }

      await client
          .from('notes')
          .delete()
          .eq('id', noteId)
          .eq('user_id', currentUser!.id);

      await _logActivity('note_deleted', 'note', noteId, null);
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  /// Share a note with another user
  Future<void> shareNote(String noteId, String email) async {
    try {
      if (currentUser == null) {
        throw const AuthException('No user is currently signed in');
      }

      // First, find the user by email
      final userResponse = await client
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (userResponse == null) {
        throw DatabaseException('User with email $email not found');
      }

      final targetUserId = userResponse['id'] as String;

      // Create a note share record
      await client.from('note_shares').insert({
        'note_id': noteId,
        'shared_by': currentUser!.id,
        'shared_with': targetUserId,
        'permission': 'read',
      });

      await _logActivity('note_shared', 'note', noteId, {'shared_with': email});
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  // ============================================================================
  // SETTINGS METHODS
  // ============================================================================

  /// Get user settings
  Future<Map<String, dynamic>?> getSettings() async {
    try {
      if (currentUser == null) return null;

      return await client
          .from('settings')
          .select()
          .eq('user_id', currentUser!.id)
          .single();
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  /// Update user settings
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    try {
      if (currentUser == null) {
        throw const AuthException('No user is currently signed in');
      }

      await client
          .from('settings')
          .update(settings)
          .eq('user_id', currentUser!.id);
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  // ============================================================================
  // BACKUP METHODS
  // ============================================================================

  /// Create a backup of user data
  Future<Map<String, dynamic>> createBackup({
    String backupType = 'manual',
    bool includeArchived = false,
  }) async {
    try {
      if (currentUser == null) {
        throw const AuthException('No user is currently signed in');
      }

      // Gather all user data
      final tasks = await getTasks();
      final categories = await getCategories();
      final notes = await getNotes();
      final settings = await getSettings();
      final profile = await getCurrentProfile();

      final backupData = {
        'profile': profile,
        'settings': settings,
        'tasks': tasks,
        'categories': categories,
        'notes': notes,
        'version': '2.0.0',
        'created_at': DateTime.now().toIso8601String(),
      };

      final backup = {
        'user_id': currentUser!.id,
        'backup_type': backupType,
        'data': backupData,
        'file_size': backupData.toString().length,
        'metadata': {
          'tasks_count': tasks.length,
          'notes_count': notes.length,
          'categories_count': categories.length,
        },
      };

      return await client.from('backups').insert(backup).select().single();
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  /// Get user backups
  Future<List<Map<String, dynamic>>> getBackups() async {
    try {
      if (currentUser == null) {
        throw const AuthException('No user is currently signed in');
      }

      return await client
          .from('backups')
          .select('id, backup_type, file_size, metadata, created_at')
          .eq('user_id', currentUser!.id)
          .order('created_at', ascending: false);
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  /// Create user profile and default data
  /// Verify if user profile exists
  Future<bool> _verifyProfile(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error verifying profile: $e');
      return false;
    }
  }

  Future<void> _createUserProfile(
      User user, String fullName, String email) async {
    try {
      debugPrint('Creating user profile for user: ${user.id}');

      // Create profile entry - using upsert to avoid conflicts
      await client.from('profiles').upsert({
        'id': user.id,
        'full_name': fullName,
        'email': email,
        'username': email.split('@')[0],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('Profile created successfully');

      // Create default categories
      await _createDefaultCategories(user.id);

      // Create default settings
      await client.from('settings').upsert({
        'user_id': user.id,
        'theme_mode': 'system',
        'notifications_enabled': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('User profile and default data created successfully');
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      // Don't throw here as the auth user is already created
      // The profile can be created later if needed
    }
  }

  /// Create default categories for new user
  Future<void> _createDefaultCategories(String userId) async {
    try {
      final defaultCategories = [
        {
          'user_id': userId,
          'name': 'Work',
          'description': 'Work-related tasks and projects',
          'color': '#2196F3',
          'icon': 'work',
          'is_default': true,
        },
        {
          'user_id': userId,
          'name': 'Personal',
          'description': 'Personal tasks and activities',
          'color': '#4CAF50',
          'icon': 'home',
          'is_default': true,
        },
        {
          'user_id': userId,
          'name': 'Shopping',
          'description': 'Shopping lists and errands',
          'color': '#FF9800',
          'icon': 'shopping_cart',
          'is_default': true,
        },
        {
          'user_id': userId,
          'name': 'Health',
          'description': 'Health and fitness activities',
          'color': '#F44336',
          'icon': 'local_hospital',
          'is_default': true,
        },
        {
          'user_id': userId,
          'name': 'Education',
          'description': 'Learning and educational tasks',
          'color': '#9C27B0',
          'icon': 'school',
          'is_default': true,
        },
      ];

      await client.from('categories').insert(defaultCategories);
      debugPrint('Default categories created for user: $userId');
    } catch (e) {
      debugPrint('Error creating default categories: $e');
    }
  }

  /// Create user session for tracking
  Future<void> _createUserSession(User user) async {
    try {
      // Only create session entry if user_sessions table exists
      // For now, just log the session creation
      debugPrint('User session created for: ${user.id}');
    } catch (e) {
      debugPrint('Failed to create user session: $e');
    }
  }

  /// Update user's last login time
  Future<void> _updateLastLogin(String userId) async {
    try {
      await client.from('profiles').update(
          {'last_login': DateTime.now().toIso8601String()}).eq('id', userId);
    } catch (e) {
      // Log error but don't throw
      print('Failed to update last login: $e');
    }
  }

  /// Invalidate user sessions
  Future<void> _invalidateUserSessions(String userId) async {
    try {
      await client
          .from('user_sessions')
          .update({'is_active': false}).eq('user_id', userId);
    } catch (e) {
      // Log error but don't throw
      print('Failed to invalidate sessions: $e');
    }
  }

  /// Delete all user data
  Future<void> _deleteUserData(String userId) async {
    try {
      // Delete in reverse dependency order
      await client.from('note_shares').delete().eq('user_id', userId);
      await client.from('user_sessions').delete().eq('user_id', userId);
      await client.from('activity_logs').delete().eq('user_id', userId);
      await client.from('backups').delete().eq('user_id', userId);
      await client.from('notes').delete().eq('user_id', userId);
      await client.from('tasks').delete().eq('user_id', userId);
      await client.from('categories').delete().eq('user_id', userId);
      await client.from('settings').delete().eq('user_id', userId);
      await client.from('profiles').delete().eq('id', userId);
    } catch (e) {
      print('Failed to delete user data: $e');
      rethrow;
    }
  }

  /// Log user activity
  Future<void> _logActivity(
    String action,
    String entityType,
    String entityId,
    Map<String, dynamic>? data,
  ) async {
    try {
      if (currentUser == null) return;

      await client.from('activity_logs').insert({
        'user_id': currentUser!.id,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'new_data': data,
      });
    } catch (e) {
      // Log error but don't throw - activity logging is not critical
      print('Failed to log activity: $e');
    }
  }

  /// Handle authentication errors
  Exception _handleAuthError(dynamic error) {
    if (error is AuthException) {
      return error;
    } else if (error is PostgrestException) {
      return AuthException(error.message);
    } else {
      return AuthException(
          'An unexpected authentication error occurred: $error');
    }
  }

  /// Handle database errors
  Exception _handleDatabaseError(dynamic error) {
    if (error is PostgrestException) {
      return DatabaseException(error.message);
    } else {
      return DatabaseException('An unexpected database error occurred: $error');
    }
  }

  /// Handle storage errors
  Exception _handleStorageError(dynamic error) {
    if (error is StorageException) {
      return error;
    } else {
      return StorageException('An unexpected storage error occurred: $error');
    }
  }
}

// Custom exceptions
class DatabaseException implements Exception {
  final String message;
  const DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}
