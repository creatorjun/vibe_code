// lib/core/constants/ui_constants.dart

class UIConstants {
  // ===== Spacing =====
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // ===== Border Radius =====
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  // ===== Opacity / Alpha Values (0-255 범위) =====
  // 사용법: color.withAlpha(UIConstants.alpha90)
  static const int alpha100 = 255; // 100% - 완전 불투명
  static const int alpha95 = 242;  // 95%
  static const int alpha90 = 230;  // 90%
  static const int alpha85 = 217;  // 85%
  static const int alpha80 = 204;  // 80%
  static const int alpha75 = 191;  // 75%
  static const int alpha70 = 179;  // 70%
  static const int alpha65 = 166;  // 65%
  static const int alpha60 = 153;  // 60%
  static const int alpha55 = 140;  // 55%
  static const int alpha50 = 128;  // 50%
  static const int alpha45 = 115;  // 45%
  static const int alpha40 = 102;  // 40%
  static const int alpha35 = 89;   // 35%
  static const int alpha30 = 77;   // 30%
  static const int alpha25 = 64;   // 25%
  static const int alpha20 = 51;   // 20%
  static const int alpha15 = 38;   // 15%
  static const int alpha10 = 26;   // 10%
  static const int alpha5 = 13;    // 5%
  static const int alpha0 = 0;     // 0% - 완전 투명

  // ===== Icons =====
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;

  // ===== Font Sizes =====
  static const double fontSizeSm = 12.0;
  static const double fontSizeMd = 14.0;
  static const double fontSizeLg = 16.0;

  // ===== Glass Effect =====
  static const double glassBlur = 10.0;

  // ===== Layout Sizes =====
  static const double sessionListWidth = 280.0;
  static const double sessionListCollapsedWidth = 64.0;
  static const double messageBubbleMaxWidth = 600.0;
  static const double messageBubblePadding = 12.0;
  static const double chatInputMinHeight = 48.0;
  static const double chatInputMaxHeight = 200.0;
  static const double appBarHeight = 56.0;

  // ===== Text Limits =====
  static const int maxSessionTitlePreviewLength = 50;
  static const int maxMessagePreviewLength = 100;

  // ===== Animation Durations =====
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration scrollDuration = Duration(milliseconds: 300);
  static const Duration shortDuration = Duration(milliseconds: 150);
  static const Duration sidebarAnimationDuration = Duration(milliseconds: 250);

  // ===== File Limits =====
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

  // Private constructor
  UIConstants._();
}
