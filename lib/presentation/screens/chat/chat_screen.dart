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
import 'package:vibe_code/domain/notifiers/chat_input/chat_input_action_notifier.dart';
import 'package:vibe_code/presentation/screens/chat/widgets/side_bar.dart';
import 'widgets/chat_state_bar.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with WidgetsBindingObserver {
  static const _scrollDebounceDuration = Duration(milliseconds: 100);
  static const _emptyMessagesProvider = AsyncValue<List<Message>>.data([]);

  int? _previousSessionId;
  int? _previousMessageCount;
  Timer? _scrollDebounce;
  double _prevKeyboardHeight = 0;
  double _prevInputHeight = 0;

  @override
  void initState() {
    super.initState();
    // ✅ AppLifecycleState 감지를 위해 Observer 추가
    WidgetsBinding.instance.addObserver(this);

    // ✅ 화면 로드 시 포커스 요청
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(chatInputActionProvider.notifier).requestFocus();
      }
    });
  }

  @override
  void dispose() {
    // ✅ Observer 제거
    WidgetsBinding.instance.removeObserver(this);
    _scrollDebounce?.cancel();
    super.dispose();
  }

  /// ✅ 앱 라이프사이클 변경 감지
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 돌아왔을 때 포커스 요청
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          ref.read(chatInputActionProvider.notifier).requestFocus();
        }
      });
    }
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
      if (mounted) _scrollToBottom(controller);
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

    // ✅ 세션 변경 시 포커스 요청
    if (activeSessionId != _previousSessionId) {
      _previousSessionId = activeSessionId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(chatInputActionProvider.notifier).requestFocus();
        }
      });
    }

    // Setup scroll effects
    _setupScrollEffects(activeSessionId, messagesAsync, scrollController);

    // Handle height changes (keyboard, input)
    _handleHeightChanges(context, scrollController);

    // ✅ Watch message count changes
    messagesAsync.whenData((messages) {
      final currentCount = messages.length;
      if (_previousMessageCount != null && currentCount != _previousMessageCount) {
        _scheduleScrollToBottom(scrollController);
      }
      _previousMessageCount = currentCount;
    });

    final sendMessageStatus = ref.watch(
      sendMessageMutationProvider.select((state) => state.status),
    );
    if (sendMessageStatus == SendMessageStatus.success ||
        sendMessageStatus == SendMessageStatus.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(scrollController);
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          _ChatContentPositioned(
            shouldShowExpanded: shouldShowExpanded,
            messagesAsync: messagesAsync,
            scrollController: scrollController,
            activeSessionId: activeSessionId,
          ),
          const Positioned(
            top: 0,
            bottom: 0,
            child: SideBar(),
          ),
          _ChatInputPositioned(shouldShowExpanded: shouldShowExpanded),
        ],
      ),
    );
  }

  void _setupScrollEffects(
      int? activeSessionId,
      AsyncValue<List<Message>> messagesAsync,
      ScrollController controller,
      ) {
    if (activeSessionId != _previousSessionId) {
      _previousSessionId = activeSessionId;
      _previousMessageCount = null;
      _scrollToBottom(controller);
      return;
    }

    // ✅ null-safe 처리
    messagesAsync.whenData((messages) {
      final currentCount = messages.length;
      final prevCount = _previousMessageCount;

      if (prevCount != null && currentCount > prevCount) {
        _scheduleScrollToBottom(controller);
      }
    });
  }

  void _handleHeightChanges(BuildContext context, ScrollController controller) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final inputHeight = ref.watch(chatInputStateProvider.select((s) => s.height));

    if (keyboardHeight != _prevKeyboardHeight || inputHeight != _prevInputHeight) {
      _scrollToBottom(controller);
    }

    _prevKeyboardHeight = keyboardHeight;
    _prevInputHeight = inputHeight;
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

  const _ChatInputPositioned({
    required this.shouldShowExpanded,
  });

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
    return messages
        .expand((message) => MessageBubble(message: message).buildAsSliver(context))
        .toList();
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
              '새로운 대화 시작',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withAlpha(UIConstants.alpha50),
              ),
            ),
            const SizedBox(height: UIConstants.spacingSm),
            Text(
              'AI 모델과 채팅을 시작해보세요',
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

  const _ErrorState({
    required this.error,
  });

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
