import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class UIHelpers {
  UIHelpers._();

  /// 플로팅 글래스 컨테이너 데코레이션
  static BoxDecoration floatingGlassDecoration({
    required bool isDark,
    double opacity = 0.5,
    double borderRadius = 16,
    BorderRadiusGeometry? customBorderRadius,
    double borderOpacity = 0.2,
    bool withElevation = true,
  }) {
    return BoxDecoration(
      color: isDark
          ? AppColors.darkSurface.withOpacity(opacity)
          : Colors.white.withOpacity(opacity * 0.3),
      borderRadius: customBorderRadius ?? BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(borderOpacity),
        width: 1,
      ),
      boxShadow: withElevation
          ? [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.3 : 0.15),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.15 : 0.08),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ]
          : null,
    );
  }

  /// 플로팅 글래스 위젯 빌더
  static Widget buildFloatingGlass({
    required Widget child,
    required bool isDark,
    double opacity = 0.5,
    double borderRadius = 16,
    BorderRadiusGeometry? customBorderRadius,
    double borderOpacity = 0.2,
    double blurSigma = 10,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool withElevation = true,
  }) {
    final effectiveBorderRadius =
        customBorderRadius ?? BorderRadius.circular(borderRadius);

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: floatingGlassDecoration(
              isDark: isDark,
              opacity: opacity,
              borderRadius: borderRadius,
              customBorderRadius: customBorderRadius,
              borderOpacity: borderOpacity,
              withElevation: withElevation,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// 플로팅 버튼 데코레이션 (클릭 가능한 카드)
  static Widget buildFloatingButton({
    required Widget child,
    required bool isDark,
    required VoidCallback? onTap,
    double opacity = 0.3,
    double borderRadius = 12,
    double borderOpacity = 0.1,
    double blurSigma = 5,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool withElevation = false,
  }) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            decoration: floatingGlassDecoration(
              isDark: isDark,
              opacity: opacity,
              borderRadius: borderRadius,
              borderOpacity: borderOpacity,
              withElevation: withElevation,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(12),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 플로팅 AppBar 데코레이션
  static BoxDecoration floatingAppBarDecoration({
    required bool isDark,
  }) {
    return BoxDecoration(
      color: isDark
          ? AppColors.darkSurface.withOpacity(0.5)
          : Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
          blurRadius: 12,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// 텍스트 스타일 헬퍼
  static TextStyle getTextStyle({
    required bool isDark,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    bool isSecondary = false,
    double opacity = 1.0,
  }) {
    Color color;
    if (isDark) {
      color = isSecondary ? AppColors.darkTextSecondary : AppColors.darkText;
    } else {
      color = isSecondary
          ? Colors.white.withOpacity(0.6)
          : Colors.white;
    }

    if (opacity != 1.0) {
      color = color.withOpacity(opacity);
    }

    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// 그라데이션 버튼 데코레이션
  static BoxDecoration gradientButtonDecoration({
    double borderRadius = 12,
    bool isActive = true,
    bool withElevation = false,
    bool isDark = false,
  }) {
    return BoxDecoration(
      gradient: isActive ? AppColors.gradient : null,
      color: !isActive ? Colors.grey.withOpacity(0.3) : null,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: withElevation && isActive
          ? [
        BoxShadow(
          color: AppColors.gradientStart.withOpacity(0.3),
          blurRadius: 12,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ]
          : null,
    );
  }

  /// Divider 스타일
  static Widget buildDivider({
    required bool isDark,
    double opacity = 0.1,
  }) {
    return Divider(
      height: 1,
      color: Colors.white.withOpacity(opacity),
    );
  }

  /// 아이콘 색상 헬퍼
  static Color getIconColor({
    required bool isDark,
    bool isSecondary = false,
    double opacity = 0.7,
  }) {
    if (isDark) {
      return isSecondary ? AppColors.darkTextSecondary : AppColors.darkText;
    } else {
      return Colors.white.withOpacity(opacity);
    }
  }
}