import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_code/core/utils/logger.dart';
import 'package:vibe_code/domain/providers/chat_input_state_provider.dart';

/// Riverpod 3.0 - NotifierProvider 사용 (watch, listen 가능)
/// UI 이벤트 처리, 포커스 관리
class ChatInputActionNotifier extends Notifier<void> {
  TextEditingController? _textController;
  FocusNode? _focusNode;
  Timer? _heightDebounce;
  GlobalKey? _containerKey;

  @override
  void build() {
    // Riverpod 3.0 - ref.onDispose()로 리소스 정리
    ref.onDispose(() {
      Logger.debug('[ChatInputAction] Disposing resources');
      _heightDebounce?.cancel();
      _textController?.removeListener(_onTextChanged);
      // ✅ FocusNode 리스너 제거 (자동 포커스 복귀 로직 삭제)
      _focusNode?.removeListener(_onFocusChanged);
    });
  }

  /// 초기화 메서드
  void initialize({
    required TextEditingController textController,
    required FocusNode focusNode,
    required GlobalKey containerKey,
    required BuildContext context,
  }) {
    _textController = textController;
    _focusNode = focusNode;
    _containerKey = containerKey;

    // 텍스트 변경 리스너만 등록 (포커스 리스너 제거)
    _textController!.addListener(_onTextChanged);
    // ✅ 포커스 자동 복귀 로직 완전 제거
    // _focusNode!.addListener(_onFocusChanged);

    Logger.info('[ChatInputAction] Initialized without auto-focus');
  }

  /// 텍스트 변경 리스너
  void _onTextChanged() {
    if (!ref.mounted) return; // Riverpod 3.0 - mounted 체크

    ref.read(chatInputStateProvider.notifier).updateContent(_textController!.text);
    scheduleHeightUpdate();
  }

  /// ✅ 포커스 변경 리스너 (비활성화)
  void _onFocusChanged() {
    // 더 이상 자동으로 포커스를 복귀하지 않음
    // 이 메서드는 호출되지 않지만 호환성을 위해 유지
  }

  /// 높이 업데이트 스케줄링 (디바운스)
  void scheduleHeightUpdate() {
    _heightDebounce?.cancel();
    _heightDebounce = Timer(const Duration(milliseconds: 50), _updateHeight);
  }

  /// 높이 업데이트 실행
  void _updateHeight() {
    if (!ref.mounted || _containerKey == null) return;

    final renderBox = _containerKey!.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final actualHeight = renderBox.size.height;
    final inputState = ref.read(chatInputStateProvider);
    final maxHeight = inputState.attachmentIds.isNotEmpty ? 500.0 : 300.0;
    final newHeight = actualHeight.clamp(72.0, maxHeight);

    final currentHeight = inputState.height;
    if ((newHeight - currentHeight).abs() > 2.0) {
      ref.read(chatInputStateProvider.notifier).updateHeight(newHeight);
    }
  }

  /// ✅ 명시적 포커스 요청 (특정 이벤트에서만 호출)
  /// - 전송 완료 후
  /// - 다이얼로그/모달 닫힘
  /// - 화면 재진입 (앱 포그라운드)
  void requestFocus() {
    if (!ref.mounted || _focusNode == null) return;

    Future.microtask(() {
      if (ref.mounted && _focusNode!.canRequestFocus) {
        _focusNode!.requestFocus();
        Logger.debug('[ChatInputAction] Focus requested explicitly');
      }
    });
  }

  /// 높이 즉시 업데이트
  void updateHeightImmediate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.mounted) _updateHeight();
    });
  }

  /// 텍스트 삽입
  void insertText(String text) {
    if (!ref.mounted || _textController == null) return;

    final selection = _textController!.selection;
    final newText = _textController!.text.replaceRange(
      selection.start,
      selection.end,
      text,
    );

    _textController!.text = newText;
    _textController!.selection = TextSelection.collapsed(
      offset: selection.start + text.length,
    );
  }

  /// 입력 초기화
  void clearInput() {
    if (!ref.mounted) return;

    _textController?.clear();
    ref.read(chatInputStateProvider.notifier).clear();
  }
}

/// Provider 정의
final chatInputActionProvider = NotifierProvider<ChatInputActionNotifier, void>(
  ChatInputActionNotifier.new,
);
