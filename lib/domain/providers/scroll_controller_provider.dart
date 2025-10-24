import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/logger.dart';

/// 메시지 리스트 스크롤 컨트롤러 Notifier (Riverpod 3.0)
class MessageScrollNotifier extends Notifier<ScrollController> {
  @override
  ScrollController build() {
    Logger.info('Initializing message scroll controller');
    final controller = ScrollController();

    // Notifier가 dispose될 때 ScrollController도 함께 dispose
    ref.onDispose(() {
      Logger.info('Disposing message scroll controller');
      controller.dispose();
    });

    return controller;
  }

  /// 스크롤을 최하단으로 이동
  void scrollToBottom() {
    if (!state.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.hasClients) {
        state.jumpTo(state.position.maxScrollExtent);
      }
    });
  }

  /// 부드럽게 스크롤
  void animateToBottom() {
    if (!state.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.hasClients) {
        state.animateTo(
          state.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 자동 스크롤 여부 확인 (하단 근처인지)
  bool shouldAutoScroll() {
    if (!state.hasClients) return false;
    final maxScroll = state.position.maxScrollExtent;
    final currentScroll = state.offset;
    return (maxScroll - currentScroll) < 100;
  }
}

final messageScrollProvider = NotifierProvider<MessageScrollNotifier, ScrollController>(
  MessageScrollNotifier.new,
);
