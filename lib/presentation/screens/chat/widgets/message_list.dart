import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/providers/database_provider.dart';
import '../../../../domain/providers/chat_input_state_provider.dart';
import '../../../../domain/providers/sidebar_state_provider.dart';
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
    final inputHeight = ref.watch(
      chatInputStateProvider.select((state) => state.height),
    );
    final scrollController = ref.watch(messageScrollProvider);
    final scrollNotifier = ref.read(messageScrollProvider.notifier);

    final sidebarState = ref.watch(sidebarStateProvider);
    final sidebarWidth = sidebarState.shouldShowExpanded
        ? UIConstants.sessionListWidth + (UIConstants.spacingMd * 2)
        : UIConstants.sessionListCollapsedWidth + (UIConstants.spacingMd * 2);

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
          return Center(
            child: Padding(
              padding: EdgeInsets.only(left: sidebarWidth),
              child: const Text('메시지가 없습니다'),
            ),
          );
        }

        // 데이터 로드 시 자동 스크롤
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollNotifier.scrollToBottom();
        });

        return AnimatedContainer(
          duration: UIConstants.animationDuration,
          curve: Curves.easeOut,
          margin: EdgeInsets.only(left: sidebarWidth),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // 상단 패딩
              SliverPadding(
                padding: EdgeInsets.only(
                  top: kToolbarHeight + (UIConstants.spacingMd * 2),
                ),
              ),
              // 메시지 렌더링
              ...messages.expand((message) {
                return MessageBubble(message: message).buildAsSliver(context);
              }),
              // 하단 패딩
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: inputHeight + (UIConstants.spacingMd * 2),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Center(
        child: Padding(
          padding: EdgeInsets.only(left: sidebarWidth),
          child: const LoadingIndicator(message: '메시지 로딩 중...'),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: EdgeInsets.only(left: sidebarWidth),
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
      ),
    );
  }
}
