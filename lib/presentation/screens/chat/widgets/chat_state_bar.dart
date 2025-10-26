import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_code/domain/providers/chat_provider.dart';
import '../../../../../../core/constants/ui_constants.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/date_formatter.dart';
import '../../../../../../domain/providers/database_provider.dart';
import '../../../../../../domain/providers/session_stats_provider.dart';
import '../../settings/settings_screen.dart';

/// ChatStateBar - SliverAppBar의 flexibleSpace에 사용되는 UI 최적화 버전
class ChatStateBar extends ConsumerWidget {
  final int? sessionId;

  const ChatStateBar({super.key, this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // RepaintBoundary: 이 위젯만 독립적으로 다시 그리도록 하여 성능 최적화
    return Padding(
      padding: EdgeInsets.all(UIConstants.spacingMd),
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: const BorderRadius.all(
            Radius.circular(UIConstants.radiusLg),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: UIConstants.glassBlur,
              sigmaY: UIConstants.glassBlur,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.spacingMd,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                borderRadius: const BorderRadius.all(
                  Radius.circular(UIConstants.radiusLg),
                ),
                border: Border.all(
                  color: Colors.white.withAlpha(UIConstants.alpha30),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(UIConstants.alpha15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 제목 섹션
                  Expanded(
                    child: _buildTitle(context, ref, sessionId),
                  ),
                  // 세션 통계 및 버튼
                  if (sessionId != null) ...[
                    _SessionStatsWidget(sessionId: sessionId!),
                    const SizedBox(width: UIConstants.spacingXs),
                    const RefreshButton(),
                  ],
                  const SettingsButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, WidgetRef ref, int? sessionId) {
    if (sessionId == null) {
      return const TitleLabel(title: 'Vibe Code');
    }

    final sessionsAsync = ref.watch(chatSessionsProvider);

    return sessionsAsync.when(
      data: (sessions) {
        final session = sessions.cast<dynamic>().firstWhere(
              (s) => s.id == sessionId,
          orElse: () => null,
        );

        if (session == null) {
          return const TitleLabel(title: 'Vibe Code');
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ 세션 제목
            Text(
              session.title as String,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700, // ✅ 굵기 강화
                fontSize: 18, // ✅ 폰트 크기 조정
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: UIConstants.spacingXs),
            // ✅ 업데이트 시간
            Text(
              DateFormatter.formatChatTime(session.updatedAt as DateTime),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withAlpha(UIConstants.alpha80), // ✅ 대비 강화
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
      loading: () => const TitleLabel(title: 'Vibe Code'),
      error: (_, __) => const TitleLabel(title: 'Vibe Code'),
    );
  }
}

/// 기본 타이틀 위젯
class TitleLabel extends StatelessWidget {
  final String title;
  const TitleLabel({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700, // ✅ 굵기 강화
          letterSpacing: 0.5,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// 세션 통계 위젯
class _SessionStatsWidget extends ConsumerWidget {
  final int sessionId;
  const _SessionStatsWidget({required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(activeSessionStatsProvider);

    return statsAsync.when(
      data: (stats) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.spacingSm,
            vertical: UIConstants.spacingXs,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(UIConstants.alpha25), // ✅ 대비 강화
            borderRadius: BorderRadius.circular(UIConstants.radiusMd), // ✅ 반경 통일
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatItem(
                context,
                icon: Icons.message_outlined,
                value: '${stats.messageCount}',
              ),
              const SizedBox(width: UIConstants.spacingMd),
              _buildStatItem(
                context,
                icon: Icons.data_usage_outlined, // ✅ 아이콘 변경
                value: stats.tokenDisplay,
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ✅ 통계 아이템을 위한 분리된 위젯
  Widget _buildStatItem(BuildContext context, {required IconData icon, required String value}) {
    return Row(
      children: [
        Icon(
          icon,
          size: UIConstants.iconSm,
          color: Colors.white.withAlpha(UIConstants.alpha90),
        ),
        const SizedBox(width: UIConstants.spacingXs),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// 새로고침 버튼 위젯
class RefreshButton extends ConsumerWidget {
  const RefreshButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionId = ref.watch(activeSessionProvider);
    if (sessionId == null) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.refresh, color: Colors.white),
      iconSize: UIConstants.iconMd,
      tooltip: '새로고침',
      padding: const EdgeInsets.all(UIConstants.spacingXs),
      onPressed: () {
        ref.invalidate(sessionMessagesProvider(sessionId));
        ref.invalidate(chatSessionsProvider);
      },
    );
  }
}

/// 설정 버튼 위젯
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_outlined, color: Colors.white),
      iconSize: UIConstants.iconMd,
      tooltip: '설정',
      padding: const EdgeInsets.all(UIConstants.spacingXs),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const SettingsScreen(),
          ),
        );
      },
    );
  }
}
