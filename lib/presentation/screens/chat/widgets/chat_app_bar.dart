// lib/presentation/screens/chat/widgets/chat_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/providers/chat_provider.dart';
import '../../../../domain/providers/database_provider.dart';
import '../../../../domain/providers/session_stats_provider.dart';
import '../../settings/settings_screen.dart';

class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ChatAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSessionId = ref.watch(activeSessionProvider);

    if (activeSessionId == null) {
      return AppBar(
        title: const Text('Vibe Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '설정',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      );
    }

    return AppBar(
      title: FutureBuilder(
        future: ref.read(chatRepositoryProvider).getSession(activeSessionId),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snapshot.data!.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                // ✅ 메시지 수와 토큰 표시
                Consumer(
                  builder: (context, ref, child) {
                    final statsAsync = ref.watch(activeSessionStatsProvider);
                    return statsAsync.when(
                      data: (stats) {
                        if (stats.messageCount == 0) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          '${stats.messageCount}개 메시지 • ${stats.tokenDisplay} 토큰',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(153),
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
              ],
            );
          }
          return const Text('...');
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: '새로고침',
          onPressed: () {
            ref.invalidate(sessionMessagesProvider(activeSessionId));
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: '설정',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}
