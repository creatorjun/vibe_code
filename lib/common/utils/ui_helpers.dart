import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/ui_constants.dart';

class UIHelpers {
  UIHelpers._();

  /// 플로팅 글래스 컨테이너 데코레이션
  static BoxDecoration floatingGlassDecoration({
    required bool isDark,
    int alpha = UIConstants.glassAlphaMedium,
    double borderRadius = 16,
    BorderRadiusGeometry? customBorderRadius,
    int borderAlpha = UIConstants.glassAlphaBorder,
    bool withElevation = true,
  }) {
    return BoxDecoration(
      color: isDark
          ? AppColors.darkSurface.withAlpha(alpha)
          : Colors.white.withAlpha((alpha * 0.3).round()),
      borderRadius: customBorderRadius ?? BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withAlpha(borderAlpha),
        width: 1,
      ),
      boxShadow: withElevation
          ? [
        BoxShadow(
          color: Colors.black.withAlpha(isDark ? UIConstants.glassAlphaLow : 38),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withAlpha(isDark ? 38 : 20),
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
    int alpha = UIConstants.glassAlphaMedium,
    double borderRadius = 16,
    BorderRadiusGeometry? customBorderRadius,
    int borderAlpha = UIConstants.glassAlphaBorder,
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
              alpha: alpha,
              borderRadius: borderRadius,
              customBorderRadius: customBorderRadius,
              borderAlpha: borderAlpha,
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
    int alpha = UIConstants.glassAlphaLow,
    double borderRadius = 12,
    int borderAlpha = UIConstants.glassAlphaBorder,
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
              alpha: alpha,
              borderRadius: borderRadius,
              borderAlpha: borderAlpha,
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
          ? AppColors.darkSurface.withAlpha(UIConstants.glassAlphaHigh)
          : Colors.white.withAlpha(26),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withAlpha(UIConstants.glassAlphaBorder),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(isDark ? UIConstants.glassAlphaBorder : 26),
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
    int? alpha,
  }) {
    Color color;
    if (isDark) {
      color = isSecondary ? AppColors.darkTextSecondary : AppColors.darkText;
    } else {
      color = isSecondary
          ? Colors.white.withAlpha(UIConstants.glassAlphaHigh)
          : Colors.white;
    }

    if (alpha != null) {
      color = color.withAlpha(alpha);
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
      color: !isActive ? Colors.grey.withAlpha(UIConstants.glassAlphaLow) : null,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withAlpha(UIConstants.glassAlphaBorder),
        width: 1,
      ),
      boxShadow: withElevation && isActive
          ? [
        BoxShadow(
          color: AppColors.gradientStart.withAlpha(UIConstants.glassAlphaLow),
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
    int alpha = 26, // 0.1
  }) {
    return Divider(
      height: 1,
      color: Colors.white.withAlpha(alpha),
    );
  }

  /// 아이콘 색상 헬퍼
  static Color getIconColor({
    required bool isDark,
    bool isSecondary = false,
    int alpha = 178, // 0.7
  }) {
    if (isDark) {
      return isSecondary ? AppColors.darkTextSecondary : AppColors.darkText;
    } else {
      return Colors.white.withAlpha(alpha);
    }
  }
}
