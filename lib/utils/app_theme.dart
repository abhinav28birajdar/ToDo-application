import 'package:flutter/material.dart';

class AppTheme {
  // Define the color palette
  static const Color darkOlive = Color(0xFF3E3F29);
  static const Color sageGreen = Color(0xFF7D8D86);
  static const Color beigeSand = Color(0xFFBCA88D);
  static const Color offWhite = Color(0xFFF1F0E4);

  // Dark theme variations
  static final Color darkBackground = darkOlive.withOpacity(0.95);
  static final Color darkSurface = darkOlive.withOpacity(0.8);
  static final Color darkSageGreen = sageGreen.withOpacity(0.8);
  static final Color darkBeigeSand = beigeSand.withOpacity(0.7);

  // Create a MaterialColor from darkOlive for primarySwatch
  static MaterialColor createMaterialColor(Color color) {
    List<double> strengths = <double>[.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: createMaterialColor(darkOlive),
      colorScheme: ColorScheme.light(
        primary: sageGreen,
        onPrimary: offWhite,
        secondary: beigeSand,
        onSecondary: darkOlive,
        background: offWhite,
        onBackground: darkOlive,
        surface: beigeSand.withOpacity(0.3),
        onSurface: darkOlive,
        error: Colors.redAccent,
        onError: offWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkOlive,
        foregroundColor: offWhite,
        elevation: 0,
      ),
      scaffoldBackgroundColor: offWhite,
      cardTheme: CardThemeData(
        color: beigeSand.withOpacity(0.7),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: sageGreen,
        foregroundColor: offWhite,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: offWhite,
          backgroundColor: sageGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: sageGreen,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return sageGreen;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(offWhite),
        side: const BorderSide(color: sageGreen, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: offWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: sageGreen, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: sageGreen, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkOlive, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: darkOlive, fontWeight: FontWeight.bold),
        headlineMedium:
            TextStyle(color: darkOlive, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: darkOlive, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: darkOlive, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: darkOlive),
        bodyMedium: TextStyle(color: darkOlive),
      ),
      dividerTheme: const DividerThemeData(
        color: sageGreen,
        thickness: 1,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: offWhite,
        unselectedLabelColor: offWhite,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: offWhite,
              width: 2,
            ),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return sageGreen;
          }
          return offWhite;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return sageGreen.withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.5);
        }),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: createMaterialColor(sageGreen),
      colorScheme: ColorScheme.dark(
        primary: sageGreen,
        onPrimary: offWhite,
        secondary: beigeSand,
        onSecondary: darkOlive,
        background: darkBackground,
        onBackground: offWhite,
        surface: darkSurface,
        onSurface: offWhite,
        error: Colors.redAccent,
        onError: offWhite,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: offWhite,
        elevation: 0,
      ),
      scaffoldBackgroundColor: darkBackground,
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkSageGreen,
        foregroundColor: offWhite,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: offWhite,
          backgroundColor: darkSageGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: sageGreen,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return sageGreen;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(offWhite),
        side: BorderSide(color: sageGreen, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBackground.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: sageGreen, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: sageGreen, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: beigeSand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge:
            const TextStyle(color: offWhite, fontWeight: FontWeight.bold),
        headlineMedium:
            const TextStyle(color: offWhite, fontWeight: FontWeight.bold),
        titleLarge:
            const TextStyle(color: offWhite, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: offWhite, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(color: offWhite),
        bodyMedium: const TextStyle(color: offWhite),
      ),
      dividerTheme: DividerThemeData(
        color: sageGreen.withOpacity(0.5),
        thickness: 1,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: offWhite,
        unselectedLabelColor: offWhite.withOpacity(0.6),
        indicator: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: offWhite,
              width: 2,
            ),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return sageGreen;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return sageGreen.withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.3);
        }),
      ),
      iconTheme: const IconThemeData(
        color: sageGreen,
      ),
    );
  }
}
