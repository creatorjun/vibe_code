// lib/presentation/screens/chat/widgets/message_list.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/providers/database_provider.dart';
import '../../../../domain/providers/chat_input_state_provider.dart';
import '../../../../domain/providers/scroll_controller_provider.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'message_bubble.dart';

/// ✅ Riverpod 3.0 개선: ref.listen 제거, StatefulConsumerWidget 사용
/// 메시지 목록을 표시하고 자동 스크롤을 관리합니다.
class MessageList extends ConsumerStatefulWidget {
  final int sessionId;

  const MessageList({super.key, required this.sessionId});

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  int? previousMessageCount;
  double? previousInputHeight;

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(sessionMessagesProvider(widget.sessionId));
    final scrollController = ref.watch(messageScrollProvider);
    final scrollNotifier = ref.read(messageScrollProvider.notifier);
    final inputHeight = ref.watch(chatInputStateProvider.select((s) => s.height));

    // ✅ Riverpod 3.0 개선: ref.listen 제거, watch 기반으로 변경
    _handleScrollEffects(messagesAsync, scrollNotifier, inputHeight);

    return messagesAsync.when(
      data: (messages) {
        if (messages.isEmpty) {
          return const Center(
            child: Text('메시지가 없습니다'),
          );
        }

        // 데이터 로드 시 자동 스크롤
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && scrollNotifier.shouldAutoScroll()) {
            scrollNotifier.scrollToBottom();
          }
        });

        return CustomScrollView(
          controller: scrollController,
          slivers: [
            // 메시지 렌더링 (최적화)
            ...messages.expand((message) {
              return MessageBubble(message: message).buildAsSliver(context);
            }),
          ],
        );
      },
      loading: () => const Center(
        child: LoadingIndicator(message: '메시지 로딩 중...'),
      ),
      error: (error, stack) => Center(
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

  /// ✅ Riverpod 3.0 개선: ref.listen 대신 watch 기반 상태 감지
  ///
  /// ref.listen을 사용하면 StreamProvider와 이중 구독이 발생하므로,
  /// watch로 상태 변화를 감지하고 직접 비교하는 방식으로 개선
  void _handleScrollEffects(
      AsyncValue messagesAsync,
      MessageScrollNotifier scrollNotifier,
      double inputHeight,
      ) {
    // 1. 메시지 개수 변화 감지
    messagesAsync.whenData((messages) {
      final currentCount = messages.length;

      if (previousMessageCount != null &&
          currentCount != previousMessageCount &&
          scrollNotifier.shouldAutoScroll()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            scrollNotifier.scrollToBottom();
          }
        });
      }

      previousMessageCount = currentCount;
    });

    // 2. 입력창 높이 변화 감지
    if (previousInputHeight != null &&
        inputHeight != previousInputHeight &&
        scrollNotifier.shouldAutoScroll()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          scrollNotifier.scrollToBottom();
        }
      });
    }

    previousInputHeight = inputHeight;
  }
}
