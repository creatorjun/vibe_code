import 'package:flutter/material.dart';
import 'dart:ui'; // BackdropFilter를 사용하기 위해 추가
import '../../common/constants/app_colors.dart';
import '../../common/constants/ui_constants.dart';
import '../../common/utils/ui_helpers.dart';

/// 메인 채팅 화면 상단에 표시되는 Sliver 앱 바 위젯
/// CustomScrollView 내에서 상단에 고정됩니다.
class ChatAppBar extends StatelessWidget {
  const ChatAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    // AppBar의 실제 UI 부분
    final appBarContent = Container(
      margin: const EdgeInsets.only(
        left: UIConstants.spacing16,
        right: UIConstants.spacing16,
        top: UIConstants.spacing8,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: UIConstants.blurSigmaMedium,
            sigmaY: UIConstants.blurSigmaMedium,
          ),
          child: Container(
            height: UIConstants.appBarHeight,
            padding: const EdgeInsets.symmetric(
              horizontal: UIConstants.spacing16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gradientStart.withAlpha(UIConstants.glassAlphaVeryHigh),
                  AppColors.gradientEnd.withAlpha(UIConstants.glassAlphaVeryHigh),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
              border: Border.all(
                color: Colors.white.withAlpha(UIConstants.glassAlphaBorder),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Vibe Code AI',
                  style: UIHelpers.getTextStyle(
                    isDark: Theme.of(context).brightness == Brightness.dark,
                    fontSize: UIConstants.fontLarge,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _buildUsageInfo(
                  Theme.of(context).brightness == Brightness.dark,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // 위젯을 Sliver로 만들기 위해 SliverPersistentHeader를 사용
    return SliverPersistentHeader(
      pinned: true, // 스크롤 시 상단에 고정
      delegate: _SliverAppBarDelegate(
        height: UIConstants.appBarHeight + UIConstants.spacing8,
        // 위젯 높이 + 상단 마진
        child: appBarContent,
      ),
    );
  }

  /// 메시지 및 토큰 사용량 정보 위젯 빌더
  Widget _buildUsageInfo(bool isDark) {
    return Row(
      children: [
        _buildInfoChip(
          isDark: isDark,
          icon: Icons.message_outlined,
          text: '5', // 더미 메시지 카운트
        ),
        const SizedBox(width: UIConstants.spacing8),
        _buildInfoChip(
          isDark: isDark,
          icon: Icons.token_outlined,
          text: '128', // 더미 토큰 카운트
        ),
      ],
    );
  }

  /// 정보 표시를 위한 작은 칩 위젯 빌더
  Widget _buildInfoChip({
    required bool isDark,
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacing10,
        vertical: UIConstants.spacing6,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBackground.withAlpha(UIConstants.glassAlphaLow)
            : AppColors.lightSurface.withAlpha(UIConstants.glassAlphaLow),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: UIConstants.iconTiny,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          const SizedBox(width: UIConstants.spacing6),
          Text(
            text,
            style: UIHelpers.getTextStyle(
              isDark: isDark,
              fontSize: UIConstants.fontSmall,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// ChatAppBar를 SliverPersistentHeader로 만들기 위한 Delegate
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _SliverAppBarDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}
