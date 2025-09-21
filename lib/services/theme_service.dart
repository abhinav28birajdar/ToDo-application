import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // App Colors
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color secondaryPurple = Color(0xFF7C3AED);
  static const Color accentPurple = Color(0xFFA855F7);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F0F23);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF16213E);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF5F5F5);

  ThemeService() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themeKey) ?? 'dark';
    _themeMode = themeModeString == 'light' ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _themeKey, _themeMode == ThemeMode.light ? 'light' : 'dark');
    notifyListeners();
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryPurple,
        secondary: secondaryPurple,
        surface: darkSurface,
        background: darkBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
        error: Colors.red.shade400,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkCard,
        selectedColor: primaryPurple,
        disabledColor: Colors.grey.shade800,
        deleteIconColor: Colors.white,
        labelStyle: const TextStyle(color: Colors.white),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        brightness: Brightness.dark,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryPurple, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryPurple,
        secondary: secondaryPurple,
        surface: lightSurface,
        background: lightBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        onBackground: Colors.black87,
        error: Colors.red.shade600,
      ),
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: Colors.black87,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black12,
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: primaryPurple,
        disabledColor: Colors.grey.shade300,
        deleteIconColor: Colors.black54,
        labelStyle: const TextStyle(color: Colors.black87),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        brightness: Brightness.light,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryPurple, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }
}
