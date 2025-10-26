// lib/presentation/screens/chat/widgets/side_bar.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/providers/sidebar_state_provider.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../settings/settings_screen.dart';
import 'session_list.dart';

class SideBar extends ConsumerStatefulWidget {
  const SideBar({super.key});

  @override
  ConsumerState<SideBar> createState() => _SideBarState();
}

class _SideBarState extends ConsumerState<SideBar> {
  bool showExpandedContent = false;
  Timer? _expansionTimer;

  @override
  void dispose() {
    _expansionTimer?.cancel();
    super.dispose();
  }

  void _handleSidebarStateChange(bool shouldShowExpanded) {
    _expansionTimer?.cancel();
    if (shouldShowExpanded) {
      _expansionTimer = Timer(UIConstants.sidebarAnimationDuration, () {
        if (mounted) {
          setState(() {
            showExpandedContent = true;
          });
        }
      });
    } else {
      if (mounted) {
        setState(() {
          showExpandedContent = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sidebarState = ref.watch(sidebarStateProvider);
    final displayWidth = sidebarState.shouldShowExpanded
        ? UIConstants.sessionListWidth
        : UIConstants.sessionListCollapsedWidth;
    final shouldShowExpanded = sidebarState.shouldShowExpanded;

    if (shouldShowExpanded !=
        (_expansionTimer?.isActive ?? false
            ? !showExpandedContent
            : showExpandedContent)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSidebarStateChange(shouldShowExpanded);
      });
    }

    return MouseRegion(
      onEnter: (_) => ref.read(sidebarStateProvider.notifier).startHover(),
      onExit: (_) => ref.read(sidebarStateProvider.notifier).endHover(),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacingMd),
        child: AnimatedContainer(
          duration: UIConstants.animationDuration,
          curve: Curves.easeOut,
          width: displayWidth,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(UIConstants.radiusLg),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: UIConstants.glassBlur,
                sigmaY: UIConstants.glassBlur,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withAlpha(UIConstants.alpha95),
                  borderRadius: BorderRadius.circular(UIConstants.radiusLg),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withAlpha(UIConstants.alpha20),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(UIConstants.alpha10),
                      blurRadius: UIConstants.radiusLg,
                      offset: const Offset(0, UIConstants.spacingXs),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SideBarHeader(
                      isExpanded: showExpandedContent,
                    ),
                    Expanded(
                      child: SessionList(
                        isExpanded: showExpandedContent,
                      ),
                    ),
                    SideBarFooter(
                      isExpanded: showExpandedContent,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SideBarHeader
// ============================================================================

class SideBarHeader extends ConsumerWidget {
  final bool isExpanded;

  const SideBarHeader({
    super.key,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // 상단: 메뉴 버튼 + 앱 이름
        Container(
          decoration: BoxDecoration(gradient: AppColors.gradient),
          padding: const EdgeInsets.all(UIConstants.spacingMd),
          child: isExpanded
              ? _buildExpandedAppHeader(context, ref)
              : _buildCollapsedAppHeader(context, ref),
        ),
        // 디바이더
        Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withAlpha(UIConstants.alpha30),
        ),
        // ✅ 제거: 대화 목록 섹션 헤더
      ],
    );
  }

  /// 확장 상태: 메뉴 버튼 + 앱 이름 (그라디언트)
  Widget _buildExpandedAppHeader(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.bars),
          iconSize: UIConstants.iconMd,
          tooltip: "메뉴 고정",
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: UIConstants.iconLg + UIConstants.spacingSm,
            minHeight: UIConstants.iconLg + UIConstants.spacingSm,
          ),
          onPressed: () {
            ref.read(sidebarStateProvider.notifier).toggle();
          },
        ),
        const SizedBox(width: UIConstants.spacingMd),
        Expanded(
          child: Text(
            'Vibe Code',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  /// 축소 상태: 메뉴 버튼만
  Widget _buildCollapsedAppHeader(BuildContext context, WidgetRef ref) {
    return Center(
      child: IconButton(
        icon: const FaIcon(FontAwesomeIcons.bars),
        iconSize: UIConstants.iconMd,
        tooltip: '사이드바 펼치기',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: UIConstants.iconLg + UIConstants.spacingSm,
          minHeight: UIConstants.iconLg + UIConstants.spacingSm,
        ),
        onPressed: () {
          ref.read(sidebarStateProvider.notifier).toggle();
        },
      ),
    );
  }
}

// ============================================================================
// SideBarFooter
// ============================================================================

class SideBarFooter extends ConsumerWidget {
  final bool isExpanded;

  const SideBarFooter({
    super.key,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacingMd),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withAlpha(UIConstants.alpha30),
            width: 1,
          ),
        ),
      ),
      child: isExpanded
          ? _buildExpandedFooter(context)
          : _buildCollapsedFooter(context),
    );
  }

  /// 확장된 상태: 그라디언트 프로필 카드
  Widget _buildExpandedFooter(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToSettings(context),
        borderRadius: BorderRadius.circular(UIConstants.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(UIConstants.spacingMd),
          decoration: BoxDecoration(
            gradient: AppColors.gradient,
            borderRadius: BorderRadius.circular(UIConstants.radiusMd),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(UIConstants.alpha30),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 아바타
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(UIConstants.alpha20),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withAlpha(UIConstants.alpha40),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.user,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: UIConstants.spacingMd),
              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Creator Jun',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: UIConstants.fontSizeLg,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Vibe Code',
                      style: TextStyle(
                        color: Colors.white.withAlpha(UIConstants.alpha70),
                        fontSize: UIConstants.fontSizeSm,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 화살표 아이콘
              FaIcon(
                FontAwesomeIcons.chevronRight,
                size: UIConstants.iconSm,
                color: Colors.white.withAlpha(UIConstants.alpha80),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 축소된 상태: 그라디언트 원형 아이콘 버튼
  Widget _buildCollapsedFooter(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToSettings(context),
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(UIConstants.alpha30),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.user,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 설정 화면으로 이동
  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }
}
