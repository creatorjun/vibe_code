import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/providers/chat_provider.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/chat_app_bar.dart'; // 수정 필요
import 'widgets/session_list.dart';
import 'widgets/message_list.dart'; // 수정 필요
import 'widgets/chat_input.dart'; // 수정 필요
import 'widgets/empty_state_widget.dart';
import '../../../domain/providers/chat_input_state_provider.dart'; // inputHeight 가져오기 위해 추가

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = ref.watch(activeSessionProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // 입력창 높이를 가져옵니다. MessageList의 하단 패딩 계산에 사용됩니다.
    final inputHeight = ref.watch(
      chatInputStateProvider.select((state) => state.height),
    );

    return Scaffold(
      body: Container(
        // 배경 그라데이션
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
              AppColors.gradientStart.withAlpha(UIConstants.alpha30),
              AppColors.gradientEnd.withAlpha(UIConstants.alpha20),
              AppColors.darkPrimary.withAlpha(UIConstants.alpha15),
            ]
                : [
              AppColors.gradientStart.withAlpha(UIConstants.alpha15),
              AppColors.gradientEnd.withAlpha(UIConstants.alpha20),
              AppColors.lightPrimary.withAlpha(UIConstants.alpha25),
            ],
          ),
        ),
        child: Row(
          children: [
            // 1. 사이드바 (너비 애니메이션)
            const SessionList(),

            // 2. 메인 영역 (앱바, 메시지 목록, 입력창)
            Expanded(
              child: Column(
                children: [
                  const ChatAppBar(),
                  // 2-2. 메시지 목록 영역
                  Expanded(
                    child: activeSession == null
                        ? const EmptyStateWidget()
                        : MessageList(
                      sessionId: activeSession,
                    ),
                  ),
                  const ChatInput(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}