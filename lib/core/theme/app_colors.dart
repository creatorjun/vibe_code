import 'package:flutter/material.dart';

class AppColors {
  // ===== Concept Colors =====
  static const primary = Color(0xFF667EEA);
  static const secondary = Color(0xFF764BA2);
  static const gradientStart = Color(0xFF667EEA);
  static const gradientEnd = Color(0xFF764BA2);

  static const gradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===== Light Theme Colors =====
  static const Color lightBackground = Color(0xFFF5F5F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = primary;
  static const Color lightSecondary = secondary;
  static const Color lightText = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF8E8E93);
  static const Color lightBorder = Color(0xFFE5E5EA);
  static const Color lightError = Color(0xFFFF3B30);
  static const Color lightSuccess = Color(0xFF34C759);

  // ===== Dark Theme Colors =====
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkPrimary = primary;
  static const Color darkSecondary = gradientEnd;
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8E8E93);
  static const Color darkBorder = Color(0xFF38383A);
  static const Color darkError = Color(0xFFFF453A);
  static const Color darkSuccess = Color(0xFF32D74B);

  // ===== Glass Effect Colors =====
  static Color get glassLight => lightSurface.withAlpha(179);
  static Color get glassDark => darkSurface.withAlpha(179);
  static Color get glassBorderLight => lightBorder.withAlpha(77);
  static Color get glassBorderDark => darkBorder.withAlpha(77);

  // ===== User Message Bubble =====
  static const Color userBubbleLight = primary;
  static const Color userBubbleDark = primary;

  // ===== AI Message Bubble =====
  static Color get aiBubbleLight => lightSurface;
  static Color get aiBubbleDark => darkSurface;

  // ===== Code Snippet =====
  static const Color codeBackgroundLight = Color(0xFFFAFAFB);
  static const Color codeBackgroundDark = Color(0xFF0E0E0F);

  // ===== Hover Effects =====
  static Color get hoverLight => lightText.withAlpha(13);
  static Color get hoverDark => darkText.withAlpha(13);

  // ===== Selected State =====
  static Color get selectedLight => lightPrimary.withAlpha(26);
  static Color get selectedDark => darkPrimary.withAlpha(26);

  // ===== Overlay =====
  static Color get overlayLight => Colors.black.withAlpha(128);
  static Color get overlayDark => Colors.black.withAlpha(179);

  // Private constructor
  AppColors._();
}
