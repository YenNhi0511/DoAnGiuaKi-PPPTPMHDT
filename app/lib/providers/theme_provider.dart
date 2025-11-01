// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';

class MyThemes {
  static const Color primaryColor = Color(0xFF673AB7);
  static const Color accentColor = Color(0xFFFF9800);
  static const Color scaffoldLight = Color(0xFFFBFBFF);

  // Style chuẩn cho InputDecoration
  static final inputDecorationStyle = InputDecorationTheme(
    filled: true,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide.none,
    ),
  );

  // ------------------ LIGHT THEME ------------------
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    // ✅ không dùng background (deprecated) nữa
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      surface: scaffoldLight,
    ),
    scaffoldBackgroundColor: scaffoldLight,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 2,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),

    // ✅ CardThemeData đúng kiểu (Flutter 3.35+)
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      margin: EdgeInsets.all(8),
    ),

    inputDecorationTheme: inputDecorationStyle.copyWith(
      fillColor: Colors.grey.shade100,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    ),
  );

  // ------------------ DARK THEME ------------------
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      background: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 2,
    ),

    // ✅ CardThemeData cho dark mode
    cardTheme: const CardThemeData(
      color: Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      margin: EdgeInsets.all(8),
    ),

    inputDecorationTheme: inputDecorationStyle.copyWith(
      fillColor: const Color(0xFF2C2C2C),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: accentColor, width: 2),
      ),
    ),
  );
}

// ------------------ PROVIDER ------------------
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
