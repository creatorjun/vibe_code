import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/constants/app_colors.dart';
import '../../common/constants/ui_constants.dart';
import '../../common/utils/ui_helpers.dart';
import '../../providers/sidebar_provider.dart';
import '../screens/settings_screen.dart';
import 'profile_card.dart';

/// 애플리케이션 사이드바 위젯
///
/// 마우스 호버 시 확장되며, 대화 내역과 프로필 카드를 표시합니다.
/// 모든 상태는 Provider로 관리됩니다.
class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key});

  /// 확장 처리
  void _handleExpand(WidgetRef ref) {
    ref.read(sidebarExpandedProvider.notifier).expand();

    // 150ms 후 콘텐츠 표시
    Future.delayed(const Duration(milliseconds: 150), () {
      ref.read(sidebarContentVisibleProvider.notifier).show();
    });
  }

  /// 축소 처리
  void _handleCollapse(WidgetRef ref) {
    ref.read(sidebarContentVisibleProvider.notifier).hide();
    ref.read(sidebarExpandedProvider.notifier).collapse();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpanded = ref.watch(sidebarExpandedProvider);
    final showContent = ref.watch(sidebarContentVisibleProvider);

    return MouseRegion(
      onEnter: (_) => _handleExpand(ref),
      onExit: (_) => _handleCollapse(ref),
      child: AnimatedContainer(
        duration: UIConstants.animationNormal,
        width: isExpanded
            ? UIConstants.sidebarWidthExpanded
            : UIConstants.sidebarWidthCollapsed,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              AppColors.darkSurface.withValues(alpha: 0.95),
              AppColors.darkSurface.withValues(alpha: 0.85),
            ]
                : [
              Colors.white.withValues(alpha: 0.95),
              Colors.white.withValues(alpha: 0.85),
            ],
          ),
          border: Border(
            right: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: UIConstants.spacing24,
              offset: const Offset(4, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(isDark, isExpanded, showContent),
            const SizedBox(height: UIConstants.spacing16),
            _buildNewChatButton(isDark, isExpanded, showContent),
            const SizedBox(height: UIConstants.spacing16),
            Expanded(
              child: _buildConversationList(isDark, isExpanded, showContent),
            ),
            _buildBottomSection(context, isDark, isExpanded, showContent),
          ],
        ),
      ),
    );
  }

  /// 헤더 빌더
  Widget _buildHeader(bool isDark, bool isExpanded, bool showContent) {
    return Padding(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      child: isExpanded
          ? Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: UIConstants.iconXLarge,
            height: UIConstants.iconXLarge,
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
            ),
            child: const Icon(
              Icons.code_rounded,
              color: Colors.white,
              size: UIConstants.iconLarge,
            ),
          ),
          if (showContent) ...[
            const SizedBox(width: UIConstants.spacing12),
            Flexible(
              child: Text(
                'Vibe Code',
                style: UIHelpers.getTextStyle(
                  isDark: isDark,
                  fontSize: UIConstants.fontXLarge,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      )
          : Center(
        child: Container(
          width: UIConstants.iconXLarge,
          height: UIConstants.iconXLarge,
          decoration: BoxDecoration(
            gradient: AppColors.gradient,
            borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
          ),
          child: const Icon(
            Icons.code_rounded,
            color: Colors.white,
            size: UIConstants.iconLarge,
          ),
        ),
      ),
    );
  }

  /// 새 대화 버튼 빌더
  Widget _buildNewChatButton(bool isDark, bool isExpanded, bool showContent) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? UIConstants.spacing16 : UIConstants.spacing8,
      ),
      child: UIHelpers.buildFloatingButton(
        isDark: isDark,
        onTap: () {
          // TODO: 새 대화 시작 로직
        },
        alpha: UIConstants.glassAlphaLow,
        padding: EdgeInsets.symmetric(
          horizontal: UIConstants.spacing12,
          vertical: isExpanded ? UIConstants.spacing12 : UIConstants.spacing10,
        ),
        child: Row(
          mainAxisAlignment: isExpanded
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              size: UIConstants.iconMedium,
              color: isDark ? Colors.white : Colors.black87,
            ),
            if (isExpanded && showContent) ...[
              const SizedBox(width: UIConstants.spacing8),
              Text(
                '새 대화',
                style: UIHelpers.getTextStyle(
                  isDark: isDark,
                  fontSize: UIConstants.fontMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 대화 목록 빌더
  Widget _buildConversationList(bool isDark, bool isExpanded, bool showContent) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? UIConstants.spacing16 : UIConstants.spacing8,
      ),
      children: [
        _buildConversationItem(
          isDark: isDark,
          isExpanded: isExpanded,
          showContent: showContent,
          title: 'Flutter 프로젝트 구조',
          lastMessage: 'MVVM 패턴 설명...',
          isActive: true,
        ),
        const SizedBox(height: UIConstants.spacing8),
        _buildConversationItem(
          isDark: isDark,
          isExpanded: isExpanded,
          showContent: showContent,
          title: 'Riverpod 3.0 사용법',
          lastMessage: '상태 관리 방법...',
          isActive: false,
        ),
      ],
    );
  }

  /// 대화 항목 빌더
  Widget _buildConversationItem({
    required bool isDark,
    required bool isExpanded,
    required bool showContent,
    required String title,
    required String lastMessage,
    required bool isActive,
  }) {
    return UIHelpers.buildFloatingButton(
      isDark: isDark,
      onTap: () {
        // TODO: 대화 선택 로직
      },
      alpha: isActive
          ? UIConstants.glassAlphaMedium
          : UIConstants.glassAlphaLow,
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacing12,
        vertical: UIConstants.spacing10,
      ),
      child: isExpanded && showContent
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
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
            lastMessage,
            style: UIHelpers.getTextStyle(
              isDark: isDark,
              fontSize: UIConstants.fontTiny,
              isSecondary: true,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      )
          : Icon(
        Icons.chat_bubble_outline_rounded,
        size: UIConstants.iconMedium,
        color: isDark ? Colors.white70 : Colors.black54,
      ),
    );
  }

  /// 하단 섹션 빌더
  Widget _buildBottomSection(
      BuildContext context,
      bool isDark,
      bool isExpanded,
      bool showContent,
      ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? UIConstants.spacing16 : UIConstants.spacing8,
        vertical: UIConstants.spacing16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProfileCard(
            isExpanded: isExpanded,
            showContent: showContent,
          ),
          const SizedBox(height: UIConstants.spacing8),
          _buildSettingsButton(context, isDark, isExpanded, showContent),
        ],
      ),
    );
  }

  /// 설정 버튼 빌더
  Widget _buildSettingsButton(
      BuildContext context,
      bool isDark,
      bool isExpanded,
      bool showContent,
      ) {
    return UIHelpers.buildFloatingButton(
      isDark: isDark,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingsScreen(),
          ),
        );
      },
      alpha: UIConstants.glassAlphaLow,
      padding: EdgeInsets.symmetric(
        horizontal: UIConstants.spacing12,
        vertical: isExpanded ? UIConstants.spacing10 : UIConstants.spacing8,
      ),
      child: Row(
        mainAxisAlignment:
        isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings_outlined,
            size: UIConstants.iconMedium,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          if (isExpanded && showContent) ...[
            const SizedBox(width: UIConstants.spacing8),
            Text(
              '설정',
              style: UIHelpers.getTextStyle(
                isDark: isDark,
                fontSize: UIConstants.fontMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
