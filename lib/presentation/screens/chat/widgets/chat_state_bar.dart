// lib/presentation/screens/chat/widgets/chat_state_bar.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/constants/ui_constants.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/date_formatter.dart';
import '../../../../../../domain/providers/database_provider.dart';
import '../../../../../../domain/providers/session_stats_provider.dart';
import '../../settings/settings_screen.dart';

/// ChatStateBar - SliverAppBar의 flexibleSpace에 사용
class ChatStateBar extends ConsumerWidget {
  final int? sessionId;

  const ChatStateBar({super.key, this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacingXs),
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
              height: 120.0,
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.spacingMd,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                borderRadius: const BorderRadius.all(
                  Radius.circular(UIConstants.radiusLg),
                ),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withAlpha(UIConstants.alpha20),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 제목
                  Expanded(
                    child: _buildTitle(context, ref, sessionId),
                  ),
                  // 통계 및 버튼
                  if (sessionId != null) ...[
                    _SessionStatsWidget(sessionId: sessionId!),
                    const SizedBox(width: UIConstants.spacingXs),
                    RefreshButton(sessionId: sessionId!),
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

        return Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  session.title as String,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: UIConstants.spacingSm),
              Text(
                DateFormatter.formatChatTime(session.updatedAt as DateTime),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withAlpha(UIConstants.alpha70),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.fade,
              ),
            ],
          ),
        );
      },
      loading: () => const TitleLabel(title: 'Vibe Code'),
      error: (_, __) => const TitleLabel(title: 'Vibe Code'),
    );
  }
}

class TitleLabel extends StatelessWidget {
  final String title;

  const TitleLabel({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// 최적화: activeSessionStatsProvider를 사용하는 위젯
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
            color: Colors.white.withAlpha(UIConstants.alpha20),
            borderRadius: const BorderRadius.all(
              Radius.circular(UIConstants.radiusSm),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.message_outlined,
                size: UIConstants.iconSm,
                color: Colors.white.withAlpha(UIConstants.alpha90),
              ),
              const SizedBox(width: 4),
              Text(
                '${stats.messageCount}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: UIConstants.spacingSm),
              Icon(
                Icons.data_usage,
                size: UIConstants.iconSm,
                color: Colors.white.withAlpha(UIConstants.alpha90),
              ),
              const SizedBox(width: 4),
              Text(
                stats.tokenDisplay,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class RefreshButton extends ConsumerWidget {
  final int sessionId;

  const RefreshButton({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.refresh, color: Colors.white),
      iconSize: UIConstants.iconMd,
      tooltip: '새로고침',
      padding: const EdgeInsets.all(UIConstants.spacingXs),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      onPressed: () {
        ref.invalidate(sessionMessagesProvider(sessionId));
        ref.invalidate(chatSessionsProvider);
      },
    );
  }
}

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.settings_outlined,
        color: Colors.white,
      ),
      iconSize: UIConstants.iconMd,
      tooltip: '설정',
      padding: const EdgeInsets.all(UIConstants.spacingXs),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
