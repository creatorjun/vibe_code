// lib/presentation/screens/chat/widgets/chat_app_bar.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_code/core/theme/app_colors.dart';
import '../../../../domain/providers/chat_provider.dart';
import '../../../../domain/providers/database_provider.dart';
import '../../../../domain/providers/session_stats_provider.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../domain/providers/sidebar_state_provider.dart';
import '../../settings/settings_screen.dart';

class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ChatAppBar({super.key});

  // ✅ 캐싱된 상수 (UIConstants 적용)
  static const _borderRadius = BorderRadius.all(
    Radius.circular(UIConstants.radiusLg),
  );
  static final _blurFilter = ImageFilter.blur(
    sigmaX: UIConstants.glassBlur,
    sigmaY: UIConstants.glassBlur,
  );
  static const _padding = EdgeInsets.symmetric(
    horizontal: UIConstants.spacingMd,
  );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSessionId = ref.watch(activeSessionProvider);

    // ✅ Provider 감시 최적화 (.select() 사용)
    final sidebarWidth = ref.watch(
      sidebarStateProvider.select(
        (state) => state.shouldShowExpanded
            ? UIConstants.sessionListWidth + (UIConstants.spacingMd * 2)
            : UIConstants.sessionListCollapsedWidth +
                  (UIConstants.spacingMd * 2),
      ),
    );

    // ✅ AnimatedPositioned를 유지 (애니메이션 보존)
    return AnimatedPositioned(
      duration: UIConstants.sidebarAnimationDuration,
      curve: Curves.easeInOut,
      top: UIConstants.spacingMd,
      left: sidebarWidth,
      right: UIConstants.spacingMd,
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: _borderRadius,
          child: BackdropFilter(
            filter: _blurFilter,
            child: Container(
              height: kToolbarHeight,
              decoration: _buildContainerDecoration(context),
              child: Padding(
                padding: _padding,
                child: Row(
                  children: [
                    // 타이틀 영역
                    Expanded(child: _buildTitle(context, ref, activeSessionId)),
                    // 통계 정보 (메시지 수 & 토큰)
                    if (activeSessionId != null)
                      _SessionStatsWidget(sessionId: activeSessionId),
                    // 액션 버튼들
                    if (activeSessionId != null) ...[
                      const SizedBox(width: UIConstants.spacingSm),
                      _RefreshButton(sessionId: activeSessionId),
                    ],
                    const _SettingsButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ BoxDecoration 캐싱 (AppColors 적용)
  BoxDecoration _buildContainerDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: AppColors.gradient,
      borderRadius: _borderRadius,
      border: Border.all(
        color: Theme.of(
          context,
        ).colorScheme.outline.withAlpha(UIConstants.alpha20),
        width: 1,
      ),
    );
  }

  // ✅ 타이틀 빌더 메서드
  Widget _buildTitle(
    BuildContext context,
    WidgetRef ref,
    int? activeSessionId,
  ) {
    if (activeSessionId == null) {
      return Text(
        'Vibe Code',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      );
    }

    return _SessionTitleWidget(sessionId: activeSessionId);
  }
}

// ✅ 세션 제목을 별도 위젯으로 분리 (리빌드 범위 최소화)
class _SessionTitleWidget extends ConsumerWidget {
  const _SessionTitleWidget({required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider(sessionId));
    return sessionAsync.when(
      data: (session) {
        if (session != null) {
          return Text(
            session.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        return const Text('...');
      },
      loading: () => const Text('...'),
      error: (_, __) => const Text('...'),
    );
  }
}

// ✅ 통계 정보를 별도 위젯으로 분리 (중첩 Consumer 제거, UIConstants 적용)
class _SessionStatsWidget extends ConsumerWidget {
  const _SessionStatsWidget({required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(activeSessionStatsProvider);
    return statsAsync.when(
      data: (stats) {
        if (stats.messageCount == 0) {
          return const SizedBox.shrink();
        }

        return _buildStatsContainer(context, stats);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatsContainer(BuildContext context, SessionStats stats) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: UIConstants.spacingSm),
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacingMd,
        vertical: UIConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(
          UIConstants.alpha30,
        ),
        borderRadius: const BorderRadius.all(
          Radius.circular(UIConstants.radiusSm),
        ),
        border: Border.all(
          color: primaryColor.withAlpha(UIConstants.alpha20),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 메시지 수
          _StatItem(
            icon: Icons.chat_bubble_outline,
            value: '${stats.messageCount}',
            color: primaryColor,
          ),
          // 구분선
          _VerticalDivider(
            color: theme.colorScheme.outline.withAlpha(UIConstants.alpha30),
          ),
          // 토큰 수
          _StatItem(
            icon: Icons.token_outlined,
            value: stats.tokenDisplay,
            color: primaryColor,
          ),
        ],
      ),
    );
  }
}

// ✅ 통계 항목 위젯 분리 (UIConstants 적용)
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  static const _iconSpacing = SizedBox(width: UIConstants.spacingXs);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: UIConstants.iconSm, color: color),
        _iconSpacing,
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ✅ 수직 구분선 위젯 (UIConstants 적용)
class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider({required this.color});

  final Color color;

  static const _dividerHeight = UIConstants.iconSm;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: UIConstants.spacingSm),
      width: 1,
      height: _dividerHeight,
      color: color,
    );
  }
}

// ✅ 새로고침 버튼 위젯 분리 (UIConstants 적용)
class _RefreshButton extends ConsumerWidget {
  const _RefreshButton({required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.refresh),
      tooltip: '새로고침',
      iconSize: UIConstants.iconMd,
      onPressed: () {
        ref.invalidate(sessionMessagesProvider(sessionId));
      },
    );
  }
}

// ✅ 설정 버튼 위젯 분리 (UIConstants 적용)
class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: '설정',
      iconSize: UIConstants.iconMd,
      onPressed: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
      },
    );
  }
}
