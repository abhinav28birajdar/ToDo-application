import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase/supabase_service.dart';
import '../screens/auth_screen.dart';

class AuthHandler extends StatelessWidget {
  final Widget child;

  const AuthHandler({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SupabaseService>(
      builder: (context, supabaseService, _) {
        if (supabaseService.isSessionExpired) {
          // Show re-authentication dialog
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showSessionExpiredDialog(context);
          });
        }

        return child;
      },
    );
  }

  void _showSessionExpiredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Session Expired'),
          content: const Text(
            'Your session has expired. Please log in again to continue.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Login'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
