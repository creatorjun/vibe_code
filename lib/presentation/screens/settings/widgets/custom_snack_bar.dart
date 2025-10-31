// lib/presentation/shared/widgets/custom_snack_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_code/core/constants/ui_constants.dart';
import 'package:vibe_code/core/theme/app_colors.dart';
import 'package:vibe_code/domain/providers/chat_input_state_provider.dart';
import 'package:vibe_code/domain/providers/sidebar_state_provider.dart';

/// 커스텀 스낵바 (Overlay 기반)
///
/// 사이드바 상태와 채팅 인풋 높이를 자동으로 고려하여 위치를 설정합니다.
class CustomSnackBar {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  /// 성공 스낵바 표시
  static void showSuccess(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 3),
        double? bottomOffsetOverride,
      }) {
    _show(
      context,
      message: message,
      backgroundColor: _getSuccessColor(context),
      icon: Icons.check_circle,
      iconColor: Colors.white,
      duration: duration,
      bottomOffsetOverride: bottomOffsetOverride,
    );
  }

  /// 에러 스낵바 표시
  static void showError(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 4),
        double? bottomOffsetOverride,
      }) {
    _show(
      context,
      message: message,
      backgroundColor: _getErrorColor(context),
      icon: Icons.error,
      iconColor: Colors.white,
      duration: duration,
      bottomOffsetOverride: bottomOffsetOverride,
    );
  }

  /// 정보 스낵바 표시
  static void showInfo(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 3),
        double? bottomOffsetOverride,
      }) {
    _show(
      context,
      message: message,
      backgroundColor: _getInfoColor(context),
      icon: Icons.info,
      iconColor: Colors.white,
      duration: duration,
      bottomOffsetOverride: bottomOffsetOverride,
    );
  }

  /// 경고 스낵바 표시
  static void showWarning(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 3),
        double? bottomOffsetOverride,
      }) {
    _show(
      context,
      message: message,
      backgroundColor: _getWarningColor(context),
      icon: Icons.warning,
      iconColor: Colors.white,
      duration: duration,
      bottomOffsetOverride: bottomOffsetOverride,
    );
  }

  /// 기본 스낵바 표시 (내부 메서드)
  static void _show(
      BuildContext context, {
        required String message,
        required Color backgroundColor,
        required IconData icon,
        required Color iconColor,
        required Duration duration,
        double? bottomOffsetOverride,
      }) {
    // 기존 스낵바 제거
    hide();

    // ✅ ProviderContainer 접근
    final container = ProviderScope.containerOf(context);

    // ✅ 채팅 인풋 높이
    final inputHeight = container.read(
      chatInputStateProvider.select((s) => s.height),
    );

    // ✅ 사이드바 상태
    final sidebarState = container.read(sidebarStateProvider);
    final sidebarWidth = sidebarState.shouldShowExpanded
        ? UIConstants.sessionListWidth + UIConstants.spacingMd
        : UIConstants.sessionListCollapsedWidth + UIConstants.spacingMd;

    // ✅ 스낵바 위치 계산
    final bottomOffset = bottomOffsetOverride ?? (inputHeight);

    _isShowing = true;

    // Overlay 엔트리 생성
    _overlayEntry = OverlayEntry(
      builder: (context) => _SnackBarWidget(
        message: message,
        backgroundColor: backgroundColor,
        icon: icon,
        iconColor: iconColor,
        bottomOffset: bottomOffset,
        leftOffset: sidebarWidth, // ✅ 사이드바 크기 고려
      ),
    );

    // Overlay에 추가
    Overlay.of(context).insert(_overlayEntry!);

    // 지정된 시간 후 자동 제거
    Future.delayed(duration, () {
      hide();
    });
  }

  /// 스낵바 숨기기
  static void hide() {
    if (_isShowing && _overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isShowing = false;
    }
  }

  /// AppColors 사용
  static Color _getSuccessColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
  }

  static Color _getErrorColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkError : AppColors.lightError;
  }

  static Color _getInfoColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
  }

  static Color _getWarningColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkSecondary : AppColors.secondary;
  }
}

/// 스낵바 위젯 (내부 사용)
class _SnackBarWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final double bottomOffset;
  final double leftOffset; // ✅ 사이드바 고려

  const _SnackBarWidget({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.bottomOffset,
    required this.leftOffset,
  });

  @override
  State<_SnackBarWidget> createState() => _SnackBarWidgetState();
}

class _SnackBarWidgetState extends State<_SnackBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: UIConstants.animationDuration,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      // ✅ 사이드바와 채팅 인풋을 모두 고려한 위치
      bottom: widget.bottomOffset,
      left: widget.leftOffset + UIConstants.spacingMd,
      right: UIConstants.spacingMd,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: UIConstants.spacingMd,
                vertical: UIConstants.spacingSm,
              ),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(UIConstants.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withAlpha(UIConstants.alpha50)
                        : Colors.black.withAlpha(UIConstants.alpha20),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    color: widget.iconColor,
                    size: UIConstants.iconSm,
                  ),
                  SizedBox(width: UIConstants.spacingSm),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: widget.iconColor,
                        fontSize: UIConstants.fontSizeSm,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ✅ Extension (BuildContext만으로 사용)
extension SnackBarExtension on BuildContext {
  /// 성공 스낵바 표시
  void showSuccessSnackBar(String message, {double? bottomOffsetOverride}) {
    CustomSnackBar.showSuccess(this, message, bottomOffsetOverride: bottomOffsetOverride);
  }

  /// 에러 스낵바 표시
  void showErrorSnackBar(String message, {double? bottomOffsetOverride}) {
    CustomSnackBar.showError(this, message, bottomOffsetOverride: bottomOffsetOverride);
  }

  /// 정보 스낵바 표시
  void showInfoSnackBar(String message, {double? bottomOffsetOverride}) {
    CustomSnackBar.showInfo(this, message, bottomOffsetOverride: bottomOffsetOverride);
  }

  /// 경고 스낵바 표시
  void showWarningSnackBar(String message, {double? bottomOffsetOverride}) {
    CustomSnackBar.showWarning(this, message, bottomOffsetOverride: bottomOffsetOverride);
  }
}
