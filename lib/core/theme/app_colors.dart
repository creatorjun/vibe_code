import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF5F5F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF007AFF);
  static const Color lightSecondary = Color(0xFF5856D6);
  static const Color lightText = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF8E8E93);
  static const Color lightBorder = Color(0xFFE5E5EA);
  static const Color lightError = Color(0xFFFF3B30);
  static const Color lightSuccess = Color(0xFF34C759);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkPrimary = Color(0xFF0A84FF);
  static const Color darkSecondary = Color(0xFF5E5CE6);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8E8E93);
  static const Color darkBorder = Color(0xFF38383A);
  static const Color darkError = Color(0xFFFF453A);
  static const Color darkSuccess = Color(0xFF32D74B);

  // Glass Effect Colors (withAlpha 사용)
  static Color glassLight = lightSurface.withAlpha(179); // ~0.7
  static Color glassDark = darkSurface.withAlpha(179); // ~0.7
  static Color glassBorderLight = lightBorder.withAlpha(77); // ~0.3
  static Color glassBorderDark = darkBorder.withAlpha(77); // ~0.3

  // User Message Bubble
  static const Color userBubbleLight = Color(0xFF007AFF);
  static const Color userBubbleDark = Color(0xFF0A84FF);

  // AI Message Bubble (withAlpha 사용)
  static Color aiBubbleLight = lightSurface.withAlpha(230); // ~0.9
  static Color aiBubbleDark = darkSurface.withAlpha(230); // ~0.9

  // Code Block
  static const Color codeBackgroundLight = Color(0xFFF6F8FA);
  static const Color codeBackgroundDark = Color(0xFF161B22);

  // Hover Effects (withAlpha 사용)
  static Color hoverLight = lightText.withAlpha(13); // ~0.05
  static Color hoverDark = darkText.withAlpha(13); // ~0.05

  // Selected State (withAlpha 사용)
  static Color selectedLight = lightPrimary.withAlpha(26); // ~0.1
  static Color selectedDark = darkPrimary.withAlpha(26); // ~0.1

  // Overlay (withAlpha 사용)
  static Color overlayLight = Colors.black.withAlpha(128); // ~0.5
  static Color overlayDark = Colors.black.withAlpha(179); // ~0.7

  // Private constructor
  AppColors._();
}
