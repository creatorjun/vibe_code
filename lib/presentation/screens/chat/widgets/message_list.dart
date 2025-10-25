// lib/presentation/screens/chat/widgets/message_list.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/providers/database_provider.dart';
import '../../../../domain/providers/chat_input_state_provider.dart';
import '../../../../domain/providers/scroll_controller_provider.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'message_bubble.dart';

class MessageList extends ConsumerWidget {
  final int sessionId;

  const MessageList({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(sessionMessagesProvider(sessionId));
    final scrollController = ref.watch(messageScrollProvider);
    final scrollNotifier = ref.read(messageScrollProvider.notifier);

    // 메시지 변화 감지 - 스크롤
    ref.listen(sessionMessagesProvider(sessionId), (previous, next) {
      if (next.hasValue && previous?.hasValue == true) {
        final prevLength = previous?.value?.length ?? 0;
        final nextLength = next.value?.length ?? 0;
        if (prevLength != nextLength && scrollNotifier.shouldAutoScroll()) {
          scrollNotifier.scrollToBottom();
        }
      }
    });

    // 입력창 높이 변화 감지 - 스크롤
    ref.listen(chatInputStateProvider.select((state) => state.height), (
        previous,
        next,
        ) {
      if (previous != next && scrollNotifier.shouldAutoScroll()) {
        scrollNotifier.scrollToBottom();
      }
    });

    return messagesAsync.when(
      data: (messages) {
        if (messages.isEmpty) {
          // ✅ Padding 제거
          return const Center(
            child: Text('메시지가 없습니다'),
          );
        }

        // 데이터 로드 시 자동 스크롤
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollNotifier.scrollToBottom();
        });

        // ✅ AnimatedContainer 및 margin 제거
        return CustomScrollView(
          controller: scrollController,
          slivers: [
            // 상단 패딩
            ...messages.expand((message) {
              return MessageBubble(message: message).buildAsSliver(context);
            }),
          ],
        );
      },
      loading: () =>
      // ✅ Padding 제거
      const Center(
        child: LoadingIndicator(message: '메시지 로딩 중...'),
      ),
      error: (error, stack) =>
      // ✅ Padding 제거
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: UIConstants.iconLg * 1.5,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: UIConstants.spacingMd),
            const Text('메시지를 불러올 수 없습니다'),
            const SizedBox(height: UIConstants.spacingSm),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}