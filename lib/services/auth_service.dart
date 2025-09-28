import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_profile.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '951387755919-u4bfdqoitnn8fbn580n0h01d4iui6m7p.apps.googleusercontent.com',
  );
  final FacebookAuth _facebookAuth = FacebookAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;

  // Stream for auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  AuthService() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _loadUserProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        _userProfile = null;
      }
      notifyListeners();
    });

    // Load existing user if session exists
    if (isAuthenticated) {
      await _loadUserProfile();
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.session != null) {
        await _loadUserProfile();
      }
      
      return response;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmail(
    String email, 
    String password, {
    String? displayName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
          'member_since': DateTime.now().toIso8601String(),
        },
      );

      if (response.session != null) {
        // Create user profile
        await _createUserProfile(response.user!, displayName);
      }

      return response;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in with Google
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (response.session != null) {
        await _createUserProfile(response.user!, googleUser.displayName);
      }

      return response;
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  // Sign in with Facebook
  Future<AuthResponse?> signInWithFacebook() async {
    try {
      final LoginResult result = await _facebookAuth.login();
      
      if (result.status != LoginStatus.success) {
        throw Exception('Facebook login failed');
      }

      final AccessToken accessToken = result.accessToken!;
      
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.facebook,
        idToken: accessToken.token,
      );

      if (response.session != null) {
        final userData = await _facebookAuth.getUserData();
        await _createUserProfile(response.user!, userData['name']);
      }

      return response;
    } catch (e) {
      throw Exception('Facebook sign in failed: $e');
    }
  }

  // Create user profile in Supabase
  Future<void> _createUserProfile(User user, String? displayName) async {
    try {
      final profileData = {
        'id': user.id,
        'email': user.email,
        'display_name': displayName ?? user.email?.split('@')[0] ?? 'User',
        'avatar_url': user.userMetadata?['avatar_url'],
        'member_since': DateTime.now().toIso8601String(),
        'bio': '',
        'phone': '',
        'location': '',
        'is_online': true,
        'last_seen': DateTime.now().toIso8601String(),
      };

      await _supabase.from('user_profiles').upsert(profileData);
      await _loadUserProfile();
    } catch (e) {
      debugPrint('Error creating user profile: $e');
    }
  }

  // Load user profile from Supabase
  Future<void> _loadUserProfile() async {
    if (!isAuthenticated) return;

    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();

      _userProfile = UserProfile.fromJson(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      // Create profile if it doesn't exist
      await _createUserProfile(currentUser!, currentUser!.email?.split('@')[0]);
    }
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (!isAuthenticated || _userProfile == null) return;

    try {
      updates['last_seen'] = DateTime.now().toIso8601String();
      
      await _supabase
          .from('user_profiles')
          .update(updates)
          .eq('id', currentUser!.id);

      await _loadUserProfile();
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Update online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    if (!isAuthenticated) return;

    try {
      await _supabase
          .from('user_profiles')
          .update({
            'is_online': isOnline,
            'last_seen': DateTime.now().toIso8601String(),
          })
          .eq('id', currentUser!.id);
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await updateOnlineStatus(false);
      await _googleSignIn.signOut();
      await _facebookAuth.logOut();
      await _supabase.auth.signOut();
      _userProfile = null;
      notifyListeners();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    if (!isAuthenticated) return;

    try {
      // Delete user data
      await _supabase.from('user_profiles').delete().eq('id', currentUser!.id);
      await _supabase.from('todos').delete().eq('user_id', currentUser!.id);
      await _supabase.from('notes').delete().eq('user_id', currentUser!.id);
      
      // Delete auth user
      await _supabase.auth.admin.deleteUser(currentUser!.id);
      
      _userProfile = null;
      notifyListeners();
    } catch (e) {
      throw Exception('Account deletion failed: $e');
    }
  }
}