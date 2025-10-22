import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../domain/providers/chat_provider.dart';
import '../../../../../../domain/providers/database_provider.dart';
import '../../../../../../domain/providers/session_stats_provider.dart';
import '../../../../../../core/constants/ui_constants.dart';
import '../../settings/settings_screen.dart';

class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ChatAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSessionId = ref.watch(activeSessionProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: kToolbarHeight,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withAlpha(230),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withAlpha(51),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // 타이틀 영역
                  Expanded(
                    child: activeSessionId == null
                        ? Text(
                      'Vibe Code',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : FutureBuilder(
                      future: ref.read(chatRepositoryProvider).getSession(activeSessionId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Text(
                            snapshot.data!.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }
                        return const Text('...');
                      },
                    ),
                  ),

                  // 통계 정보 (메시지 수 & 토큰)
                  if (activeSessionId != null)
                    Consumer(
                      builder: (context, ref, child) {
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
                      },
                    ),

                  // 액션 버튼들
                  if (activeSessionId != null) ...[
                    const SizedBox(width: UIConstants.spacingSm),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: '새로고침',
                      iconSize: 20,
                      onPressed: () {
                        ref.invalidate(sessionMessagesProvider(activeSessionId));
                      },
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: '설정',
                    iconSize: 20,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 통계 정보 컨테이너 (글래스 효과)
  Widget _buildStatsContainer(BuildContext context, SessionStats stats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: UIConstants.spacingSm),
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacingMd,
        vertical: UIConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(77),
        borderRadius: BorderRadius.circular(UIConstants.radiusSm),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(51),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 메시지 수
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '${stats.messageCount}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),

          // 구분선
          Container(
            margin: const EdgeInsets.symmetric(horizontal: UIConstants.spacingSm),
            width: 1,
            height: 16,
            color: Theme.of(context).colorScheme.outline.withAlpha(77),
          ),

          // 토큰 수
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.token_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                stats.tokenDisplay,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
