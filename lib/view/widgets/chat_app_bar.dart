import 'package:flutter/material.dart';
import '../../common/constants/app_colors.dart'; // AppColors를 사용하기 위해 추가
import '../../common/constants/ui_constants.dart';
import '../../common/utils/ui_helpers.dart';

/// 메인 채팅 화면 상단에 표시되는 Sliver 앱 바 위젯
/// CustomScrollView 내에서 상단에 고정됩니다.
class ChatAppBar extends StatelessWidget {
  const ChatAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // AppBar의 실제 UI 부분
    final appBarContent = UIHelpers.buildFloatingGlass(
      isDark: isDark,
      margin: const EdgeInsets.only(
        left: UIConstants.spacing16,
        right: UIConstants.spacing16,
        top: UIConstants.spacing8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacing16),
      borderRadius: UIConstants.radiusXLarge,
      child: SizedBox(
        height: UIConstants.appBarHeight,
        child: Row(
          children: [
            Text(
              'Vibe Code AI',
              style: UIHelpers.getTextStyle(
                isDark: isDark,
                fontSize: UIConstants.fontLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // 설정 버튼 대신 메시지/토큰 정보 위젯 추가
            _buildUsageInfo(isDark),
          ],
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
