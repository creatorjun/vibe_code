import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/providers/chat_provider.dart';
import 'widgets/chat_app_bar.dart';
import 'widgets/session_list.dart';
import 'widgets/message_list.dart';
import 'widgets/chat_input.dart';
import 'widgets/empty_state_widget.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = ref.watch(activeSessionProvider);

    return Scaffold(
      appBar: const ChatAppBar(),
      body: Row(
        children: [
          const SessionList(),
          Expanded(
            child: activeSession == null
                ? Column(
              children: [
                const Expanded(child: EmptyStateWidget()),
                ChatInput(sessionId: activeSession),
              ],
            )
                : Column(
              children: [
                Expanded(
                  child: MessageList(sessionId: activeSession),
                ),
                ChatInput(sessionId: activeSession),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
