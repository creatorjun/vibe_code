import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF667EEA);
  static const gradientStart = Color(0xFF667EEA);
  static const gradientEnd = Color(0xFF764BA2);

  static const gradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const lightBackground = Color(0xFFF5F5F5);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF212121);
  static const lightTextSecondary = Color(0xFF757575);

  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkText = Color(0xFFE0E0E0);
  static const darkTextSecondary = Color(0xFFB0B0B0);

  static const divider = Color(0xFFE0E0E0);
  static const dividerDark = Color(0xFF2C2C2C);
}
