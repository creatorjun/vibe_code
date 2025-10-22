import 'package:flutter/material.dart';

class UIConstants {
  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // Border Radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  // Icons
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;

  // Font Sizes
  static const double fontSizeSm = 12.0;
  static const double fontSizeMd = 14.0;
  static const double fontSizeLg = 16.0;

  // Glass Effect
  static const double glassBlur = 10.0;

  // Layout Sizes
  static const double sessionListWidth = 280.0;
  static const double sessionListCollapsedWidth = 64.0; // 축소 상태 너비 추가
  static const double messageBubbleMaxWidth = 600.0;
  static const double messageBubblePadding = 12.0;
  static const double chatInputMinHeight = 48.0;
  static const double chatInputMaxHeight = 200.0;
  static const double appBarHeight = 56.0;

  // Text Limits
  static const int maxSessionTitlePreviewLength = 50;
  static const int maxMessagePreviewLength = 100;

  // Animation Durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration scrollDuration = Duration(milliseconds: 300);
  static const Duration shortDuration = Duration(milliseconds: 150);
  static const Duration sidebarAnimationDuration = Duration(milliseconds: 250); // 사이드바 애니메이션 추가

  // File Limits
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxFilesPerMessage = 5;
  static const List<String> allowedFileExtensions = [
    'txt',
    'md',
    'json',
    'dart',
    'yaml',
    'yml',
    'xml',
    'html',
    'css',
    'js',
    'ts',
    'py',
    'java',
    'kt',
    'swift',
  ];

  // Colors (Material 3)
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color errorRed = Color(0xFFE53935);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);

  // Private constructor
  UIConstants._();
}
