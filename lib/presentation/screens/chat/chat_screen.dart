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
                  // 2-1. 앱바 영역 (수정된 ChatAppBar 필요)
                  // ChatAppBar는 이제 Scaffold의 appBar가 아니므로,
                  // 내부에서 높이를 직접 관리하고 Positioned 대신 일반 위젯으로 반환해야 합니다.
                  const ChatAppBar(), // 내부 구현 수정 필요

                  // 2-2. 메시지 목록 영역
                  Expanded(
                    child: activeSession == null
                        ? const EmptyStateWidget()
                    // MessageList 내부에서 sidebarWidth 관련 로직 제거 필요
                    // 상단/하단 패딩 계산 방식 변경 필요 (AppBar, Input 높이 고려)
                        : MessageList(
                      sessionId: activeSession,
                      // MessageList에 상단(앱바), 하단(입력창) 여백을 전달하거나
                      // MessageList 내부에서 직접 계산하도록 수정 필요
                      // 예: topPadding: kToolbarHeight + UIConstants.spacingMd * 2,
                      //    bottomPadding: inputHeight + UIConstants.spacingMd * 2,
                    ),
                  ),

                  // 2-3. 입력창 영역 (수정된 ChatInput 필요)
                  // ChatInput도 Positioned 대신 일반 위젯으로 반환하고,
                  // 내부에서 sidebarWidth 관련 margin 로직 제거 필요
                  const ChatInput(), // 내부 구현 수정 필요
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}