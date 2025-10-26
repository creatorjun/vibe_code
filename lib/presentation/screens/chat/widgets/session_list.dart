import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vibe_code/core/theme/app_colors.dart';
import 'package:vibe_code/domain/mutations/create_session_mutation.dart';
import 'package:vibe_code/domain/providers/database_provider.dart';
import 'package:vibe_code/domain/providers/sidebar_state_provider.dart';
import 'package:vibe_code/core/constants/ui_constants.dart';
import 'package:vibe_code/presentation/shared/widgets/adaptive_loading.dart';
import 'package:vibe_code/presentation/screens/settings/settings_screen.dart';
import 'session_tile.dart';

class SessionList extends ConsumerStatefulWidget {
  const SessionList({super.key});

  @override
  ConsumerState<SessionList> createState() => _SessionListState();
}

class _SessionListState extends ConsumerState<SessionList> {
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
    final sessionsAsync = ref.watch(chatSessionsProvider);
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
                    _buildHeader(context, ref),
                    Expanded(
                      child: sessionsAsync.when(
                        data: (sessions) {
                          if (sessions.isEmpty) {
                            return _buildEmptyState(context);
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(
                              UIConstants.spacingSm,
                            ),
                            itemCount: sessions.length,
                            itemBuilder: (context, index) {
                              return SessionTile(
                                key: ValueKey('session-${sessions[index].id}'),
                                session: sessions[index],
                                isCollapsed: !showExpandedContent,
                              );
                            },
                          );
                        },
                        loading: () => const AdaptiveLoading(
                          message: '...',
                          size: UIConstants.iconLg + UIConstants.spacingSm,
                        ),
                        error: (error, stack) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(
                                UIConstants.spacingMd,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: UIConstants.iconLg * 1.5,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  const SizedBox(height: UIConstants.spacingMd),
                                  const Text('오류 발생'),
                                  const SizedBox(height: UIConstants.spacingSm),
                                  Text(
                                    error.toString(),
                                    style: Theme.of(context).textTheme.bodySmall,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 헤더: 앱 이름 + 디바이더 + 대화 목록 섹션
  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // 상단: 메뉴 버튼 + 앱 이름
        Container(
          decoration: BoxDecoration(
            gradient: AppColors.gradient
          ),
          padding: const EdgeInsets.all(UIConstants.spacingMd),
          child: showExpandedContent
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
        // 하단: 대화 목록 섹션 (확장 시에만 표시)
        if (showExpandedContent) _buildSessionHeader(context, ref),
      ],
    );
  }

  /// 확장 상태: 메뉴 버튼 + 앱 이름 (그라디언트)
  Widget _buildExpandedAppHeader(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.menu),
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
        icon: const Icon(Icons.menu),
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

  /// 대화 목록 섹션 헤더 (확장 시에만 표시)
  Widget _buildSessionHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacingMd,
        vertical: UIConstants.spacingSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '대화 목록',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(UIConstants.alpha70),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            iconSize: UIConstants.iconMd,
            tooltip: '새 대화',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: UIConstants.iconLg + UIConstants.spacingSm,
              minHeight: UIConstants.iconLg + UIConstants.spacingSm,
            ),
            color: Theme.of(context).colorScheme.primary,
            onPressed: () => createNewSession(ref, '새로운 대화'),
          ),
        ],
      ),
    );
  }

  /// 푸터: 그라디언트 프로필 카드
  Widget _buildFooter(BuildContext context) {
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
      child: showExpandedContent
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
                      'User',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: UIConstants.fontSizeLg,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'AI Chat Assistant',
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
              Icon(
                Icons.arrow_forward_ios,
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

  /// 빈 상태 표시
  Widget _buildEmptyState(BuildContext context) {
    if (showExpandedContent) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: UIConstants.iconLg * 1.5,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(UIConstants.alpha30),
              ),
              const SizedBox(height: UIConstants.spacingMd),
              Text(
                '대화가 없습니다',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha(UIConstants.alpha60),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
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
