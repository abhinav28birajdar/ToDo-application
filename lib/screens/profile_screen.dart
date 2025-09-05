import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../services/supabase/supabase_service.dart';
import '../utils/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  bool _isEditing = false;
  UserProfile? _userProfile;
  String? _errorMessage;
  File? _selectedImage;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final userData = await supabaseService.getUserProfile();

      setState(() {
        _userProfile = UserProfile.fromSupabase(userData);
        _nameController.text = _userProfile?.fullName ?? '';
        _bioController.text = _userProfile?.bio ?? '';
        _phoneController.text = _userProfile?.phoneNumber ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);

      // Upload new avatar if selected
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        final fileName = _selectedImage!.path.split('/').last;
        final avatarUrl = await supabaseService.uploadAvatar(bytes, fileName);
        _userProfile = _userProfile!.copyWith(avatarUrl: avatarUrl);
      }

      // Update profile data
      final updatedProfile = _userProfile!.copyWith(
        fullName: _nameController.text,
        bio: _bioController.text,
        phoneNumber: _phoneController.text,
        updatedAt: DateTime.now(),
      );

      await supabaseService.updateUserProfile(updatedProfile.toSupabase());

      setState(() {
        _userProfile = updatedProfile;
        _isEditing = false;
        _isLoading = false;
        _selectedImage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  Future<void> _removeAvatar() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      await supabaseService.deleteAvatar();

      setState(() {
        _userProfile = _userProfile!.copyWith(avatarUrl: null);
        _isLoading = false;
        _selectedImage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar removed')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error removing avatar: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _nameController.text = _userProfile?.fullName ?? '';
                  _bioController.text = _userProfile?.bio ?? '';
                  _phoneController.text = _userProfile?.phoneNumber ?? '';
                  _selectedImage = null;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserProfile,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildProfileHeader(theme),
                      const SizedBox(height: 24),
                      _isEditing
                          ? _buildProfileForm()
                          : _buildProfileInfo(theme),
                    ],
                  ),
                ),
      bottomNavigationBar: _isEditing
          ? BottomAppBar(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sageGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Save Changes',
                  style: theme.textTheme.bodyLarge!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 64,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!) as ImageProvider
                  : _userProfile?.avatarUrl != null
                      ? NetworkImage(_userProfile!.avatarUrl!)
                      : null,
              child: _userProfile?.avatarUrl == null && _selectedImage == null
                  ? Icon(
                      Icons.person,
                      size: 64,
                      color: theme.colorScheme.primary,
                    )
                  : null,
            ),
            if (_isEditing)
              InkWell(
                onTap: _selectImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isEditing &&
            (_userProfile?.avatarUrl != null || _selectedImage != null))
          TextButton.icon(
            onPressed: _removeAvatar,
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Remove Avatar'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
      ],
    );
  }

  Widget _buildProfileInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoSection(
          title: 'Name',
          content: _userProfile?.fullName ?? 'Not set',
          icon: Icons.person,
          theme: theme,
        ),
        _infoSection(
          title: 'Email',
          content: _userProfile?.email ?? '',
          icon: Icons.email,
          theme: theme,
        ),
        if (_userProfile?.phoneNumber != null &&
            _userProfile!.phoneNumber!.isNotEmpty)
          _infoSection(
            title: 'Phone',
            content: _userProfile!.phoneNumber!,
            icon: Icons.phone,
            theme: theme,
          ),
        if (_userProfile?.bio != null && _userProfile!.bio!.isNotEmpty)
          _infoSection(
            title: 'Bio',
            content: _userProfile!.bio!,
            icon: Icons.description,
            theme: theme,
          ),
        _infoSection(
          title: 'Member Since',
          content:
              '${_userProfile?.createdAt.toLocal().toString().split(' ')[0]}',
          icon: Icons.calendar_today,
          theme: theme,
        ),
      ],
    );
  }

  Widget _infoSection({
    required String title,
    required String content,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bioController,
            decoration: const InputDecoration(
              labelText: 'Bio',
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
              hintText: 'Tell us about yourself',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _userProfile?.email ?? '',
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            enabled: false, // Email cannot be changed
          ),
        ],
      ),
    );
  }
}
