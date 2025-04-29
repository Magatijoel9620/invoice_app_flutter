import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Colors.white;
  static const Color secondaryColor = Colors.blue;
  static const Color accentColor = Color(0xFF008080);

  static ThemeData lightTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        onPrimary: primaryColor,
        secondaryContainer: accentColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: secondaryColor,
      ),
      bottomAppBarTheme: const BottomAppBarTheme(
        color: secondaryColor,
      ),
      scaffoldBackgroundColor: primaryColor,
    );
  }

  static ThemeData darkTheme() {
    const Color darkPrimaryColor = Color(0xFF303030);
    const Color darkScaffoldBackgroundColor = Color(0xFF121212);
    return ThemeData(
      primaryColor: darkPrimaryColor,
      colorScheme: const ColorScheme.dark(
        onPrimary: darkPrimaryColor,
        secondaryContainer: accentColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkPrimaryColor,
      ),
      bottomAppBarTheme: const BottomAppBarTheme(
        color: darkPrimaryColor,
      ),
      scaffoldBackgroundColor: darkScaffoldBackgroundColor,
    );
  }
}