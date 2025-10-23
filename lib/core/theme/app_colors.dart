// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // ===== Concept Colors (새로 교체) =====
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
  static const Color lightPrimary = Color(0xFF667EEA); // primary 사용
  static const Color lightSecondary = Color(0xFF667EEA); // secondary 사용
  static const Color lightText = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF8E8E93);
  static const Color lightBorder = Color(0xFFE5E5EA);
  static const Color lightError = Color(0xFFFF3B30);
  static const Color lightSuccess = Color(0xFF34C759);

  // ===== Dark Theme Colors =====
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkPrimary = Color(0xFF667EEA); // primary 사용
  static const Color darkSecondary = Color(0xFF764BA2); // gradientEnd 사용
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8E8E93);
  static const Color darkBorder = Color(0xFF38383A);
  static const Color darkError = Color(0xFFFF453A);
  static const Color darkSuccess = Color(0xFF32D74B);

  // ===== Glass Effect Colors (withAlpha) =====
  static Color get glassLight => lightSurface.withAlpha(179); // 0.7
  static Color get glassDark => darkSurface.withAlpha(179); // 0.7
  static Color get glassBorderLight => lightBorder.withAlpha(77); // 0.3
  static Color get glassBorderDark => darkBorder.withAlpha(77); // 0.3

  // ===== User Message Bubble =====
  static const Color userBubbleLight = Color(0xFF667EEA); // primary 사용
  static const Color userBubbleDark = Color(0xFF667EEA); // primary 사용

  // ===== AI Message Bubble (withAlpha) =====
  static Color get aiBubbleLight => lightSurface.withAlpha(230); // 0.9
  static Color get aiBubbleDark => darkSurface.withAlpha(230); // 0.9

  // ===== Code Block =====
  static const Color codeBackgroundLight = Color(0xFFF6F8FA);
  static const Color codeBackgroundDark = Color(0xFF161B22);

  // ===== Hover Effects (withAlpha) =====
  static Color get hoverLight => lightText.withAlpha(13); // 0.05
  static Color get hoverDark => darkText.withAlpha(13); // 0.05

  // ===== Selected State (withAlpha) =====
  static Color get selectedLight => lightPrimary.withAlpha(26); // 0.1
  static Color get selectedDark => darkPrimary.withAlpha(26); // 0.1

  // ===== Overlay (withAlpha) =====
  static Color get overlayLight => Colors.black.withAlpha(128); // 0.5
  static Color get overlayDark => Colors.black.withAlpha(179); // 0.7

  // Private constructor
  AppColors._();
}
