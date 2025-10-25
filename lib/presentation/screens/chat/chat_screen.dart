// lib/presentation/screens/chat/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_code/presentation/screens/chat/widgets/chat_input.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/providers/chat_input_state_provider.dart';
import '../../../domain/providers/database_provider.dart';
import '../../../domain/providers/scroll_controller_provider.dart';
import '../../../domain/providers/sidebar_state_provider.dart';
import '../../../domain/providers/chat_provider.dart';
import 'widgets/chat_state_bar.dart';
import 'widgets/message_bubble.dart';
import 'widgets/session_list.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  int? previousSessionId;
  Timer? scrollDebounce;
  double prevKeyboardHeight = 0;
  double prevInputHeight = 0;

  @override
  void dispose() {
    scrollDebounce?.cancel();
    super.dispose();
  }

  void scrollToBottom(ScrollController controller) {
    if (!controller.hasClients) return;
    controller.animateTo(
      controller.position.maxScrollExtent,
      duration: UIConstants.scrollDuration,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 최적화: select를 사용하여 필요한 값만 구독
    final shouldShowExpanded = ref.watch(
      sidebarStateProvider.select((state) => state.shouldShowExpanded),
    );
    final activeSessionId = ref.watch(
      activeSessionProvider.select((id) => id),
    );

    final messagesAsync = activeSessionId != null
        ? ref.watch(sessionMessagesProvider(activeSessionId))
        : const AsyncValue.data(<Message>[]);

    final scrollController = ref.watch(messageScrollProvider);

    // 키보드와 입력 높이 변화 감지
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final inputHeight = ref.watch(
      chatInputStateProvider.select((s) => s.height),
    );

    // 세션 변경 시 스크롤
    if (activeSessionId != previousSessionId) {
      previousSessionId = activeSessionId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom(scrollController);
      });
    }

    // 메시지 변경 감지 (debounce 적용)
    ref.listen<AsyncValue<List<Message>>>(
      activeSessionId != null
          ? sessionMessagesProvider(activeSessionId)
          : Provider((ref) => const AsyncValue.data(<Message>[])),
          (previous, next) {
        if (next.hasValue && previous?.hasValue == true) {
          final prevLength = previous?.value?.length ?? 0;
          final nextLength = next.value?.length ?? 0;

          if (prevLength != nextLength) {
            scrollDebounce?.cancel();
            scrollDebounce = Timer(
              const Duration(milliseconds: 100),
                  () => scrollToBottom(scrollController),
            );
          }
        }
      },
    );

    // 키보드/입력 높이 변화 시 스크롤
    if (keyboardHeight != prevKeyboardHeight || inputHeight != prevInputHeight) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom(scrollController);
      });
      prevKeyboardHeight = keyboardHeight;
      prevInputHeight = inputHeight;
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            left: shouldShowExpanded
                ? UIConstants.sessionListWidth + UIConstants.spacingMd * 2
                : UIConstants.sessionListCollapsedWidth + UIConstants.spacingMd * 2,
            child: messagesAsync.when(
              data: (messages) => _buildChatContent(
                context,
                ref,
                messages,
                scrollController,
                activeSessionId,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    Text('$error'),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: SessionList(),
          ),
          Positioned(
            left: shouldShowExpanded
                ? UIConstants.sessionListWidth + UIConstants.spacingMd * 2
                : UIConstants.sessionListCollapsedWidth + UIConstants.spacingMd * 2,
            right: 0,
            bottom: 0,
            child: const ChatInput(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatContent(
      BuildContext context,
      WidgetRef ref,
      List<Message> messages,
      ScrollController scrollController,
      int? activeSessionId,
      ) {
    // 최적화: inputHeight만 watch
    final inputHeight = ref.watch(
      chatInputStateProvider.select((s) => s.height),
    );

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverAppBar(
          pinned: true,
          floating: true,
          toolbarHeight: UIConstants.appBarHeight,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          flexibleSpace: ChatStateBar(sessionId: activeSessionId),
        ),
        if (messages.isEmpty)
          _buildEmptyState(context, ref)
        else
          ...messages.expand((message) {
            return MessageBubble(message: message).buildAsSliver(context);
          }),
        SliverToBoxAdapter(
          child: SizedBox(
            height: inputHeight,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withAlpha(
                UIConstants.alpha30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '새로운 대화를 시작하세요',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(UIConstants.alpha50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '메시지를 입력하거나 파일을 첨부해보세요',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(UIConstants.alpha40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
