// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/utils/app_theme.dart';

void main() {
  testWidgets('AppTheme has correct violet color', (WidgetTester tester) async {
    // Test that our theme has the correct violet color
    expect(AppTheme.violet500, const Color(0xFF8B5CF6));
    expect(AppTheme.primaryColor, AppTheme.violet500);
  });

  testWidgets('Light theme is properly configured',
      (WidgetTester tester) async {
    final lightTheme = AppTheme.lightTheme;

    // Verify theme is configured
    expect(lightTheme.brightness, Brightness.light);
    expect(lightTheme.colorScheme.primary, AppTheme.violet500);
  });

  testWidgets('Dark theme is properly configured', (WidgetTester tester) async {
    final darkTheme = AppTheme.darkTheme;

    // Verify theme is configured
    expect(darkTheme.brightness, Brightness.dark);
    expect(darkTheme.colorScheme.primary, AppTheme.violet500);
  });
}
