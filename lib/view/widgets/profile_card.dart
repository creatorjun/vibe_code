import 'package:flutter/material.dart';
import '../../common/constants/app_colors.dart';
import '../../common/constants/ui_constants.dart';
import '../../common/utils/ui_helpers.dart';

/// 사용자 프로필 카드 위젯
///
/// 사이드바 하단에 표시되는 프로필 정보 카드입니다.
/// 확장/축소 상태에 따라 다른 레이아웃을 보여줍니다.
class ProfileCard extends StatelessWidget {
  final bool isExpanded;
  final bool showContent; // ✅ 추가!

  const ProfileCard({
    super.key,
    required this.isExpanded,
    required this.showContent, // ✅ 추가!
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return UIHelpers.buildFloatingButton(
      isDark: isDark,
      onTap: () {
        // TODO: 프로필 상세 보기 구현
      },
      alpha: UIConstants.glassAlphaLow,
      padding: isExpanded
          ? const EdgeInsets.symmetric(
              horizontal: UIConstants.spacing12,
              vertical: UIConstants.spacing10,
            )
          : const EdgeInsets.all(UIConstants.spacing6),
      child:
          isExpanded &&
              showContent // ✅ 둘 다 체크!
          ? _buildExpandedLayout(isDark)
          : _buildCollapsedLayout(),
    );
  }

  /// 확장된 상태의 레이아웃
  Widget _buildExpandedLayout(bool isDark) {
    return SizedBox(
      height: UIConstants.profileCardHeightExpanded,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProfileIcon(
            size: UIConstants.profileIconLarge,
            iconSize: UIConstants.iconLarge,
          ),
          const SizedBox(width: UIConstants.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'John Doe',
                  style: UIHelpers.getTextStyle(
                    isDark: isDark,
                    fontSize: UIConstants.fontSmall,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: UIConstants.spacing3),
                Text(
                  'john@example.com',
                  style: UIHelpers.getTextStyle(
                    isDark: isDark,
                    fontSize: UIConstants.fontTiny,
                    isSecondary: true,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 축소된 상태의 레이아웃
  Widget _buildCollapsedLayout() {
    return Center(
      child: _buildProfileIcon(
        size: UIConstants.profileIconMedium,
        iconSize: UIConstants.iconMedium,
      ),
    );
  }

  /// 프로필 아이콘 빌더
  Widget _buildProfileIcon({required double size, required double iconSize}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: AppColors.gradient,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(Icons.person_rounded, color: Colors.white, size: iconSize),
    );
  }
}
