import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/providers/chat_provider.dart';
import '../../../../domain/providers/database_provider.dart';
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
            return Text(snapshot.data!.title);
          }
          return const Text('채팅');
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
