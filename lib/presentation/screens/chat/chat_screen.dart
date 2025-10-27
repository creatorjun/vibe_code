// lib/presentation/screens/chat/chat_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_code/presentation/screens/chat/widgets/chat_input.dart';
import 'package:vibe_code/core/constants/ui_constants.dart';
import 'package:vibe_code/data/database/app_database.dart';
import 'package:vibe_code/domain/mutations/send_message/send_message_mutation.dart';
import 'package:vibe_code/domain/providers/chat_input_state_provider.dart';
import 'package:vibe_code/domain/providers/database_provider.dart';
import 'package:vibe_code/domain/providers/scroll_controller_provider.dart';
import 'package:vibe_code/domain/providers/sidebar_state_provider.dart';
import 'package:vibe_code/domain/providers/chat_provider.dart';
import 'widgets/chat_state_bar.dart';
import 'widgets/message_bubble.dart';
import 'widgets/side_bar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  static const _scrollDebounceDuration = Duration(milliseconds: 100);
  static const _emptyMessagesProvider = AsyncValue<List<Message>>.data([]);

  int? _previousSessionId;
  Timer? _scrollDebounce;
  double _prevKeyboardHeight = 0;
  double _prevInputHeight = 0;

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    super.dispose();
  }

  void _scrollToBottom(ScrollController controller) {
    if (!controller.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.hasClients) {
        controller.animateTo(
          controller.position.maxScrollExtent,
          duration: UIConstants.scrollDuration,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scheduleScrollToBottom(ScrollController controller) {
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(_scrollDebounceDuration, () {
      _scrollToBottom(controller);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowExpanded = ref.watch(
      sidebarStateProvider.select((state) => state.shouldShowExpanded),
    );
    final activeSessionId = ref.watch(activeSessionProvider);
    final scrollController = ref.watch(messageScrollProvider);

    final messagesAsync = activeSessionId != null
        ? ref.watch(sessionMessagesProvider(activeSessionId))
        : _emptyMessagesProvider;

    _setupListeners(activeSessionId, scrollController);
    _handleHeightChanges(context, scrollController);

    return Scaffold(
      body: Stack(
        children: [
          _ChatContentPositioned(
            shouldShowExpanded: shouldShowExpanded,
            messagesAsync: messagesAsync,
            scrollController: scrollController,
            activeSessionId: activeSessionId,
          ),
          const Positioned(top: 0, bottom: 0, child: SideBar()),
          _ChatInputPositioned(shouldShowExpanded: shouldShowExpanded),
        ],
      ),
    );
  }

  void _setupListeners(int? activeSessionId, ScrollController controller) {
    if (activeSessionId != _previousSessionId) {
      _previousSessionId = activeSessionId;
      _scrollToBottom(controller);
    }

    if (activeSessionId != null) {
      ref.listen<AsyncValue<List<Message>>>(
        sessionMessagesProvider(activeSessionId),
            (previous, next) {
          if (next.hasValue && previous?.hasValue == true) {
            final prevLength = previous?.value?.length ?? 0;
            final nextLength = next.value?.length ?? 0;
            if (prevLength != nextLength) {
              _scheduleScrollToBottom(controller);
            }
          }
        },
      );
    }

    ref.listen(
      sendMessageMutationProvider.select((state) => state.status),
          (previous, next) {
        if (previous == SendMessageStatus.streaming &&
            (next == SendMessageStatus.success ||
                next == SendMessageStatus.error ||
                next == SendMessageStatus.idle)) {
          _scrollToBottom(controller);
        }
      },
    );
  }

  void _handleHeightChanges(BuildContext context, ScrollController controller) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final inputHeight = ref.watch(chatInputStateProvider.select((s) => s.height));

    if (keyboardHeight != _prevKeyboardHeight || inputHeight != _prevInputHeight) {
      _scrollToBottom(controller);
      _prevKeyboardHeight = keyboardHeight;
      _prevInputHeight = inputHeight;
    }
  }
}

class _ChatContentPositioned extends ConsumerWidget {
  final bool shouldShowExpanded;
  final AsyncValue<List<Message>> messagesAsync;
  final ScrollController scrollController;
  final int? activeSessionId;

  const _ChatContentPositioned({
    required this.shouldShowExpanded,
    required this.messagesAsync,
    required this.scrollController,
    required this.activeSessionId,
  });

  double get _leftOffset => shouldShowExpanded
      ? UIConstants.sessionListWidth + UIConstants.spacingMd
      : UIConstants.sessionListCollapsedWidth + UIConstants.spacingMd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedPositioned(
      duration: UIConstants.animationDuration,
      curve: Curves.easeOut,
      left: _leftOffset,
      top: 0,
      right: 0,
      bottom: 0,
      child: messagesAsync.when(
        data: (messages) => _ChatContent(
          messages: messages,
          scrollController: scrollController,
          activeSessionId: activeSessionId,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(error: error),
      ),
    );
  }
}

class _ChatInputPositioned extends StatelessWidget {
  final bool shouldShowExpanded;

  const _ChatInputPositioned({required this.shouldShowExpanded});

  double get _leftOffset => shouldShowExpanded
      ? UIConstants.sessionListWidth + UIConstants.spacingMd
      : UIConstants.sessionListCollapsedWidth + UIConstants.spacingMd;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: UIConstants.animationDuration,
      curve: Curves.easeOut,
      left: _leftOffset,
      right: 0,
      bottom: 0,
      child: const ChatInput(),
    );
  }
}

class _ChatContent extends ConsumerWidget {
  final List<Message> messages;
  final ScrollController scrollController;
  final int? activeSessionId;

  const _ChatContent({
    required this.messages,
    required this.scrollController,
    required this.activeSessionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputHeight = ref.watch(chatInputStateProvider.select((s) => s.height));

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverAppBar(
          pinned: true,
          floating: true,
          toolbarHeight: UIConstants.appBarHeight,
          automaticallyImplyLeading: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: ChatStateBar(sessionId: activeSessionId),
        ),
        if (messages.isEmpty)
          const _EmptyState()
        else
          ..._buildMessageSlivers(messages, context),
        SliverToBoxAdapter(child: SizedBox(height: inputHeight)),
      ],
    );
  }

  List<Widget> _buildMessageSlivers(List<Message> messages, BuildContext context) {
    return messages.expand((message) {
      return MessageBubble(message: message).buildAsSliver(context);
    }).toList();
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: colorScheme.primary.withAlpha(UIConstants.alpha30),
            ),
            const SizedBox(height: UIConstants.spacingMd),
            Text(
              '새로운 대화를 시작하세요',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withAlpha(UIConstants.alpha50),
              ),
            ),
            const SizedBox(height: UIConstants.spacingSm),
            Text(
              '메시지를 입력하거나 파일을 첨부해보세요',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withAlpha(UIConstants.alpha40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: UIConstants.spacingMd),
          Text(
            '$error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
