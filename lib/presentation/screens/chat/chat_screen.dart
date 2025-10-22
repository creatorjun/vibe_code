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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          // 사이드바 - 전체 높이 차지
          const SessionList(),

          // 메인 영역 - 그래디언트 배경 + 플로팅 앱바
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                    const Color(0xFF1A237E).withAlpha(77),  // 딥 블루
                    const Color(0xFF0D47A1).withAlpha(51),  // 로얄 블루
                    const Color(0xFF01579B).withAlpha(38),  // 다크 블루
                  ]
                      : [
                    const Color(0xFF2196F3).withAlpha(38),  // 밝은 블루
                    const Color(0xFF1976D2).withAlpha(51),  // 미디엄 블루
                    const Color(0xFF1565C0).withAlpha(64),  // 딥 블루
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // 메인 콘텐츠
                  Positioned.fill(
                    child: activeSession == null
                        ? const Column(
                      children: [
                        Expanded(child: EmptyStateWidget()),
                        ChatInput(),
                      ],
                    )
                        : Column(
                      children: [
                        Expanded(
                          child: MessageList(sessionId: activeSession),
                        ),
                        const ChatInput(),
                      ],
                    ),
                  ),

                  // 플로팅 앱바 (위에 오버레이)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ChatAppBar(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
