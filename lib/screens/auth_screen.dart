import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';
import '../services/supabase/supabase_service.dart';
import 'package:form_field_validator/form_field_validator.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String _errorMessage = '';

  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      FocusScope.of(context).unfocus();
      _clearErrorMessage();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _clearErrorMessage() {
    if (_errorMessage.isNotEmpty) {
      setState(() {
        _errorMessage = '';
      });
    }
  }

  Future<void> _handleSignIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        await _supabaseService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Sign in successful, navigate to the home screen
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        setState(() {
          _errorMessage = 'Sign in failed: ${e.toString()}';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        await _supabaseService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data: {'full_name': _nameController.text.trim()},
        );

        // Show a success message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Account created! Please check your email to confirm your account.'),
            backgroundColor: Colors.green,
          ),
        );

        // Switch to the sign in tab
        _tabController.animateTo(0);
      } catch (e) {
        setState(() {
          _errorMessage = 'Sign up failed: ${e.toString()}';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _handlePasswordReset() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _supabaseService.resetPassword(_emailController.text.trim());

      // Show a success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Please check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Password reset failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = settingsProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDarkMode ? AppTheme.darkOlive : AppTheme.sageGreen,
              isDarkMode ? Colors.black : AppTheme.offWhite,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Logo or App Name
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: isDarkMode ? AppTheme.offWhite : AppTheme.darkOlive,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pro-Organizer',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color:
                          isDarkMode ? AppTheme.offWhite : AppTheme.darkOlive,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Secure Task & Note Manager',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode
                          ? AppTheme.offWhite.withOpacity(0.8)
                          : AppTheme.darkOlive.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Authentication Form Card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: isDarkMode ? Colors.grey[850] : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Tab Bar for Sign In / Sign Up
                          TabBar(
                            controller: _tabController,
                            labelColor: AppTheme.sageGreen,
                            unselectedLabelColor:
                                isDarkMode ? Colors.grey : Colors.grey[600],
                            indicatorColor: AppTheme.sageGreen,
                            tabs: const [
                              Tab(text: 'Sign In'),
                              Tab(text: 'Sign Up'),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Tab Views
                          SizedBox(
                            height: _tabController.index == 0 ? 250 : 320,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Sign In Tab
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        decoration: const InputDecoration(
                                          labelText: 'Email',
                                          prefixIcon: Icon(Icons.email),
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: MultiValidator([
                                          RequiredValidator(
                                              errorText: 'Email is required'),
                                          EmailValidator(
                                              errorText:
                                                  'Enter a valid email address'),
                                        ]),
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: !_isPasswordVisible,
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          prefixIcon: const Icon(Icons.lock),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isPasswordVisible
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isPasswordVisible =
                                                    !_isPasswordVisible;
                                              });
                                            },
                                          ),
                                          border: const OutlineInputBorder(),
                                        ),
                                        validator: RequiredValidator(
                                          errorText: 'Password is required',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () =>
                                              _handlePasswordReset(),
                                          child: Text(
                                            'Forgot Password?',
                                            style: TextStyle(
                                              color: AppTheme.sageGreen,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Sign Up Tab
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _nameController,
                                        decoration: const InputDecoration(
                                          labelText: 'Full Name',
                                          prefixIcon: Icon(Icons.person),
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: RequiredValidator(
                                          errorText: 'Name is required',
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        decoration: const InputDecoration(
                                          labelText: 'Email',
                                          prefixIcon: Icon(Icons.email),
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: MultiValidator([
                                          RequiredValidator(
                                              errorText: 'Email is required'),
                                          EmailValidator(
                                              errorText:
                                                  'Enter a valid email address'),
                                        ]),
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: !_isPasswordVisible,
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          prefixIcon: const Icon(Icons.lock),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isPasswordVisible
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isPasswordVisible =
                                                    !_isPasswordVisible;
                                              });
                                            },
                                          ),
                                          border: const OutlineInputBorder(),
                                        ),
                                        validator: MultiValidator([
                                          RequiredValidator(
                                              errorText:
                                                  'Password is required'),
                                          MinLengthValidator(8,
                                              errorText:
                                                  'Password must be at least 8 characters long'),
                                          PatternValidator(
                                              r'(?=.*?[#?!@$%^&*-])',
                                              errorText:
                                                  'Password must have at least one special character')
                                        ]),
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _confirmPasswordController,
                                        obscureText: !_isConfirmPasswordVisible,
                                        decoration: InputDecoration(
                                          labelText: 'Confirm Password',
                                          prefixIcon:
                                              const Icon(Icons.lock_outline),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isConfirmPasswordVisible
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isConfirmPasswordVisible =
                                                    !_isConfirmPasswordVisible;
                                              });
                                            },
                                          ),
                                          border: const OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (value !=
                                              _passwordController.text) {
                                            return 'Passwords do not match';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Error Message
                          if (_errorMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                _errorMessage,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          const SizedBox(height: 24),

                          // Action Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      if (_tabController.index == 0) {
                                        _handleSignIn();
                                      } else {
                                        _handleSignUp();
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.sageGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text(
                                      _tabController.index == 0
                                          ? 'Sign In'
                                          : 'Sign Up',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Theme Toggle
                  TextButton.icon(
                    onPressed: () {
                      settingsProvider.toggleTheme();
                    },
                    icon: Icon(
                      isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color:
                          isDarkMode ? AppTheme.offWhite : AppTheme.darkOlive,
                    ),
                    label: Text(
                      isDarkMode ? 'Light Mode' : 'Dark Mode',
                      style: TextStyle(
                        color:
                            isDarkMode ? AppTheme.offWhite : AppTheme.darkOlive,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
