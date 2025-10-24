import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/providers/chat_provider.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/app_colors.dart';
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
      body: Stack(
        children: [
          // 1. 메인 영역 - (그래디언트 배경)
          // (기존 Container(child: Stack(...)) 구조에서
          // 배경 Container를 Stack의 맨 아래 레이어로 변경)
          Container(
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
          ),

          // 2. 메인 콘텐츠 (배경 위)
          // (기존 nested Stack에서 메인 Stack으로 이동)
          activeSession == null
              ? const EmptyStateWidget()
              : MessageList(sessionId: activeSession),

          // 3. 플로팅 입력창 (하단)
          // (기존 nested Stack에서 메인 Stack으로 이동)
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ChatInput(),
          ),

          // 4. 플로팅 앱바 (상단)
          // (기존 nested Stack에서 메인 Stack으로 이동)
          const ChatAppBar(),

          // 5. 플로팅 사이드바 (좌측 최상단)
          // (기존과 동일)
          const Positioned(top: 0, left: 0, bottom: 0, child: SessionList()),
        ],
      ),
    );
  }
}