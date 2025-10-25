// lib/presentation/screens/chat/chat_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/providers/chat_input_state_provider.dart';
import '../../../domain/providers/database_provider.dart';
import '../../../domain/providers/scroll_controller_provider.dart';
import '../../../domain/providers/sidebar_state_provider.dart';
import '../../../domain/providers/chat_provider.dart';
import 'widgets/chat_app_bar.dart';
import 'widgets/chat_input.dart';
import 'widgets/message_bubble.dart';
import 'widgets/session_list.dart';

/// 채팅 화면 메인
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  int? _previousSessionId;
  Timer? _scrollDebounce;

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sidebarState = ref.watch(sidebarStateProvider);
    final activeSessionId = ref.watch(activeSessionProvider);
    final messagesAsync = activeSessionId != null
        ? ref.watch(sessionMessagesProvider(activeSessionId))
        : const AsyncValue.data(<Message>[]);
    final scrollController = ref.watch(messageScrollProvider);

    // 세션 변경 감지 및 스크롤
    if (activeSessionId != _previousSessionId) {
      _previousSessionId = activeSessionId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(scrollController);
      });
    }

    // 메시지 변경 감지 및 스크롤
    ref.listen<AsyncValue<List<Message>>>(
      activeSessionId != null
          ? sessionMessagesProvider(activeSessionId)
          : Provider((ref) => const AsyncValue.data(<Message>[])),
          (previous, next) {
        if (next.hasValue && previous?.hasValue == true) {
          final prevLength = previous?.value?.length ?? 0;
          final nextLength = next.value?.length ?? 0;

          if (prevLength != nextLength) {
            _scrollDebounce?.cancel();
            _scrollDebounce = Timer(const Duration(milliseconds: 100), () {
              _scrollToBottom(scrollController);
            });
          }
        }
      },
    );

    return Scaffold(
      // ✅ ChatInput 추가
      bottomNavigationBar: const ChatInput(),
      body: Stack(
        children: [
          // 메인 채팅 영역
          Positioned.fill(
            left: sidebarState.shouldShowExpanded
                ? UIConstants.sessionListWidth + UIConstants.spacingMd * 2
                : UIConstants.sessionListCollapsedWidth +
                UIConstants.spacingMd * 2,
            child: messagesAsync.when(
              data: (messages) => _buildChatContent(
                context,
                ref,
                messages,
                scrollController,
                activeSessionId,
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    Text('오류: $error'),
                  ],
                ),
              ),
            ),
          ),

          // 세션 리스트 (왼쪽)
          const Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: SessionList(),
          ),
        ],
      ),
    );
  }

  /// 채팅 콘텐츠 빌드 (CustomScrollView 사용)
  Widget _buildChatContent(
      BuildContext context,
      WidgetRef ref,
      List<Message> messages,
      ScrollController scrollController,
      int? activeSessionId,
      ) {
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        // ✅ AppBar를 Sliver로 통합
        SliverAppBar(
          pinned: true,
          floating: false,
          toolbarHeight: UIConstants.appBarHeight,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          flexibleSpace: ChatAppBarContent(sessionId: activeSessionId),
        ),

        // ✅ 메시지 리스트
        if (messages.isEmpty)
          _buildEmptyState(context, ref)
        else
          ...messages.expand((message) {
            return MessageBubble(message: message).buildAsSliver(context);
          }),

        // ✅ 하단 여백 (ChatInput 높이만큼)
        SliverToBoxAdapter(
          child: SizedBox(
            height: ref.watch(
              chatInputStateProvider.select((s) => s.height),
            ),
          ),
        ),
      ],
    );
  }

  /// 빈 상태 표시
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

  /// 스크롤을 하단으로 이동
  void _scrollToBottom(ScrollController controller) {
    if (!controller.hasClients) return;

    controller.animateTo(
      controller.position.maxScrollExtent,
      duration: UIConstants.scrollDuration,
      curve: Curves.easeOut,
    );
  }
}