/// UI 관련 상수 정의
///
/// 모든 spacing, size, duration 등의 매직 넘버를 여기에 정의하여
/// 일관성을 유지하고 유지보수를 용이하게 합니다.
class UIConstants {
  UIConstants._(); // 인스턴스 생성 방지

  // ==================== Spacing ====================
  static const double spacing3 = 3.0;
  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing10 = 10.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing60 = 60.0;

  // ==================== Border Radius ====================
  static const double radiusSmall = 6.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusXXLarge = 20.0;

  // ==================== Animation Duration ====================
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // ==================== Glass Effect Opacity ====================
  static const double glassOpacityLow = 0.3;
  static const double glassOpacityMedium = 0.4;
  static const double glassOpacityHigh = 0.6;
  static const double glassOpacityVeryHigh = 0.8;
  static const double glassBorderOpacity = 0.2;

  // ==================== Blur ====================
  static const double blurSigmaSmall = 5.0;
  static const double blurSigmaMedium = 10.0;
  static const double blurSigmaLarge = 15.0;

  // ==================== Icon Sizes ====================
  static const double iconTiny = 14.0;
  static const double iconSmall = 18.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  static const double iconXLarge = 40.0;

  // ==================== Font Sizes ====================
  static const double fontTiny = 11.0;
  static const double fontSmall = 13.0;
  static const double fontMedium = 14.0;
  static const double fontNormal = 15.0;
  static const double fontLarge = 18.0;

  // ==================== Code Snippet ====================
  static const double codeLineHeight = 22.4;
  static const double codePadding = 32.0;
  static const double codeHeaderHeight = 48.0;
  static const double codeHeaderPadding = 16.0;
  static const double codeBorderWidth = 1.0;

  // ==================== Profile Card ====================
  static const double profileIconLarge = 40.0;
  static const double profileIconMedium = 32.0;
  static const double profileIconSmall = 24.0;
  static const double profileCardHeightExpanded = 60.0;

  // ==================== Sidebar ====================
  static const double sidebarWidthCollapsed = 80.0;
  static const double sidebarWidthExpanded = 260.0;

  // ==================== Chat Bubble ====================
  static const double chatBubbleMaxWidth = 60.0; // 왼쪽 여백용

  // ==================== AppBar ====================
  static const double appBarHeight = 56.0; // kToolbarHeight
}
