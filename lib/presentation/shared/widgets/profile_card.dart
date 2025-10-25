// lib/presentation/shared/widgets/profile_card.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:vibe_code/core/theme/app_colors.dart';
import 'package:vibe_code/core/constants/ui_constants.dart';

/// 그라디언트 배경을 가진 프로필 카드 위젯
///
/// 사용자 또는 AI 프로필 정보를 표시하는 데 사용됩니다.
class ProfileCard extends StatelessWidget {
  /// 프로필 이름
  final String name;

  /// 프로필 설명 또는 서브타이틀
  final String? subtitle;

  /// 프로필 아이콘 (Font Awesome 아이콘)
  final IconData? icon;

  /// 커스텀 아바타 위젯 (icon 대신 사용 가능)
  final Widget? avatar;

  /// 카드가 컴팩트 모드인지 여부
  final bool isCompact;

  /// 탭 이벤트 핸들러
  final VoidCallback? onTap;

  const ProfileCard({
    super.key,
    required this.name,
    this.subtitle,
    this.icon,
    this.avatar,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UIConstants.radiusLg),
        child: Container(
          padding: EdgeInsets.all(
            isCompact ? UIConstants.spacingMd : UIConstants.spacingLg,
          ),
          decoration: BoxDecoration(
            gradient: AppColors.gradient,
            borderRadius: BorderRadius.circular(UIConstants.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(UIConstants.alpha30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: isCompact ? _buildCompactContent() : _buildFullContent(),
        ),
      ),
    );
  }

  /// 컴팩트 모드 콘텐츠
  Widget _buildCompactContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAvatar(size: 40),
        const SizedBox(width: UIConstants.spacingMd),
        Flexible(
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: UIConstants.fontSizeLg,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 전체 모드 콘텐츠
  Widget _buildFullContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAvatar(size: 64),
        const SizedBox(height: UIConstants.spacingMd),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: UIConstants.spacingSm),
          Text(
            subtitle!,
            style: TextStyle(
              color: Colors.white.withAlpha(UIConstants.alpha80),
              fontSize: UIConstants.fontSizeMd,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  /// 아바타 위젯 생성
  Widget _buildAvatar({required double size}) {
    if (avatar != null) {
      return SizedBox(
        width: size,
        height: size,
        child: avatar,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(UIConstants.alpha20),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withAlpha(UIConstants.alpha40),
          width: 2,
        ),
      ),
      child: Center(
        child: FaIcon(
          icon ?? FontAwesomeIcons.user,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}

/// 그라디언트가 있는 정보 카드
///
/// 통계나 정보를 표시하는 데 사용됩니다.
class GradientInfoCard extends StatelessWidget {
  /// 카드 제목
  final String title;

  /// 카드 값 (숫자 또는 텍스트)
  final String value;

  /// 카드 아이콘
  final IconData icon;

  /// 탭 이벤트 핸들러
  final VoidCallback? onTap;

  const GradientInfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UIConstants.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(UIConstants.spacingMd),
          decoration: BoxDecoration(
            gradient: AppColors.gradient,
            borderRadius: BorderRadius.circular(UIConstants.radiusMd),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(UIConstants.alpha20),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                icon,
                color: Colors.white.withAlpha(UIConstants.alpha80),
                size: UIConstants.iconMd,
              ),
              const SizedBox(height: UIConstants.spacingMd),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: UIConstants.spacingXs),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withAlpha(UIConstants.alpha70),
                  fontSize: UIConstants.fontSizeSm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 심플한 그라디언트 컨테이너
///
/// 커스텀 콘텐츠를 그라디언트 배경에 표시합니다.
class GradientContainer extends StatelessWidget {
  /// 자식 위젯
  final Widget child;

  /// 패딩
  final EdgeInsetsGeometry? padding;

  /// 테두리 반경
  final double borderRadius;

  /// 그림자 표시 여부
  final bool showShadow;

  const GradientContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = UIConstants.radiusLg,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(UIConstants.spacingLg),
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
          BoxShadow(
            color: AppColors.primary.withAlpha(UIConstants.alpha30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ]
            : null,
      ),
      child: child,
    );
  }
}
