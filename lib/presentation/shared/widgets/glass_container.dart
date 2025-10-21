import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/app_colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? color;
  final Border? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? AppColors.glassDark : AppColors.glassLight;
    final defaultBorderColor = isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(UIConstants.radiusMd),
        border: border ?? Border.all(color: defaultBorderColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(UIConstants.radiusMd),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: UIConstants.glassBlur,
            sigmaY: UIConstants.glassBlur,
          ),
          child: Container(
            padding: padding ?? const EdgeInsets.all(UIConstants.spacingMd),
            decoration: BoxDecoration(
              color: color ?? defaultColor,
              borderRadius: borderRadius ?? BorderRadius.circular(UIConstants.radiusMd),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
