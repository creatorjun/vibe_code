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
          // 메인 영역 - 전체 화면 (그래디언트 배경)
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
            child: Stack(
              children: [
                // 메인 콘텐츠 (전체 화면)
                activeSession == null
                    ? const EmptyStateWidget()
                    : MessageList(sessionId: activeSession),
                // 플로팅 입력창 (하단)
                const Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ChatInput(),
                ),
                // 플로팅 앱바 (상단)
                const ChatAppBar(),
              ],
            ),
          ),
          // 플로팅 사이드바 (좌측 최상단)
          const Positioned(top: 0, left: 0, bottom: 0, child: SessionList()),
        ],
      ),
    );
  }
}
