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
          // 사이드바 - 전체 높이 차지 (UI 수정 유지)
          const SessionList(),

          // 메인 영역 - 그래디언트 배경 + 플로팅 앱바 (UI 수정 유지)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                    const Color(0xFF1A237E).withAlpha(77),
                    const Color(0xFF0D47A1).withAlpha(51),
                    const Color(0xFF01579B).withAlpha(38),
                  ]
                      : [
                    const Color(0xFF2196F3).withAlpha(38),
                    const Color(0xFF1976D2).withAlpha(51),
                    const Color(0xFF1565C0).withAlpha(64),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // 메인 콘텐츠 (원본 로직 유지)
                  Positioned.fill(
                    child: Column(
                      children: [
                        // 앱바 높이만큼 여백 (플로팅 앱바가 차지하는 공간)
                        const SizedBox(height: kToolbarHeight + 32), // 16*2 margin

                        // 콘텐츠 영역
                        Expanded(
                          child: activeSession == null
                              ? const EmptyStateWidget()
                              : MessageList(sessionId: activeSession),
                        ),

                        // 채팅 입력 (원본 그대로)
                        const ChatInput(),
                      ],
                    ),
                  ),

                  // 플로팅 앱바 (UI 수정 유지)
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
