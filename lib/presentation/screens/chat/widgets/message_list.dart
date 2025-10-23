import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/providers/database_provider.dart';
import '../../../../domain/providers/chat_input_state_provider.dart';
import '../../../../domain/providers/sidebar_state_provider.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'message_bubble.dart';

class MessageList extends ConsumerStatefulWidget {
  final int sessionId;

  const MessageList({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    _autoScroll = (maxScroll - currentScroll) < 100;
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    if (!_autoScroll) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: UIConstants.scrollDuration,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(sessionMessagesProvider(widget.sessionId));
    final inputHeight = ref.watch(
      chatInputStateProvider.select((state) => state.height),
    );

    // ✅ 사이드바 상태 감지
    final sidebarState = ref.watch(sidebarStateProvider);
    final sidebarWidth = sidebarState.shouldShowExpanded
        ? UIConstants.sessionListWidth + (UIConstants.spacingMd * 2) // 패딩 포함
        : UIConstants.sessionListCollapsedWidth + (UIConstants.spacingMd * 2);

    // 메시지 변화 감지 - 스크롤
    ref.listen(sessionMessagesProvider(widget.sessionId), (previous, next) {
      if (next.hasValue && previous?.hasValue == true) {
        final prevLength = previous?.value?.length ?? 0;
        final nextLength = next.value?.length ?? 0;
        if (prevLength != nextLength) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    });

    // 입력창 높이 변화 감지 - 스크롤
    ref.listen(
      chatInputStateProvider.select((state) => state.height),
          (previous, next) {
        if (previous != next && _autoScroll) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      },
    );

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

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.only(
            left: sidebarWidth, // ✅ 사이드바 너비만큼 좌측 여백
            top: UIConstants.spacingMd,
            right: UIConstants.spacingMd,
            bottom: UIConstants.spacingMd + inputHeight,
          ),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final isFirstMessage = index == 0;

            return Padding(
              padding: EdgeInsets.only(
                top: isFirstMessage
                    ? kToolbarHeight + (UIConstants.spacingMd * 2)
                    : 0,
              ),
              child: MessageBubble(
                key: ValueKey('msg_${messages[index].id}'),
                message: messages[index],
              ),
            );
          },
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
