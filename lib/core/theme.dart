import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    primaryColor: const Color(0xFF1A237E),
    scaffoldBackgroundColor: const Color(0xFFF5F6FA),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: const Color(0xFF1A237E),
      secondary: const Color(0xFF1976D2),
      surface: const Color(0xFFF5F6FA),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A237E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: Color(0xFF1A237E),
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(color: Color(0xFF222B45)),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: Color(0xFF1976D2),
      textTheme: ButtonTextTheme.primary,
    ),
  );
}
