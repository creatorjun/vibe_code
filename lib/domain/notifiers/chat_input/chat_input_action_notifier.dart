// lib/domain/notifiers/chat_input/chat_input_action_notifier.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_code/core/utils/logger.dart';
import 'package:vibe_code/domain/providers/chat_input_state_provider.dart';

/// ✅ Riverpod 3.0 NotifierProvider 패턴
/// 텍스트 컨트롤러, 포커스, 높이 관리를 중앙 집중화
class ChatInputActionNotifier extends Notifier<void> {
  TextEditingController? _textController;
  FocusNode? _focusNode;
  Timer? _heightDebounce;
  GlobalKey? _containerKey;
  BuildContext? _context; // ✅ BuildContext 저장

  @override
  void build() {
    // ✅ Riverpod 3.0: ref.onDispose로 자동 정리
    ref.onDispose(() {
      Logger.debug('[ChatInputAction] Disposing resources');
      _heightDebounce?.cancel();
      _textController?.removeListener(_onTextChanged);
      _focusNode?.removeListener(_onFocusChanged);
      _context = null; // ✅ Context 정리
    });
  }

  /// 초기화 (위젯에서 한 번만 호출)
  void initialize({
    required TextEditingController textController,
    required FocusNode focusNode,
    required GlobalKey containerKey,
    required BuildContext context, // ✅ Context 추가
  }) {
    _textController = textController;
    _focusNode = focusNode;
    _containerKey = containerKey;
    _context = context; // ✅ Context 저장

    _textController!.addListener(_onTextChanged);
    _focusNode!.addListener(_onFocusChanged);

    Logger.info('[ChatInputAction] Initialized');
  }

  /// 텍스트 변경 감지
  void _onTextChanged() {
    if (!ref.mounted) return; // ✅ Riverpod 3.0: mounted 체크

    ref.read(chatInputStateProvider.notifier).updateContent(_textController!.text);
    scheduleHeightUpdate();
  }

  /// ✅ 포커스 자동 복구 (다이얼로그 체크 추가)
  void _onFocusChanged() {
    if (!_focusNode!.hasFocus && ref.mounted) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (ref.mounted && _shouldRequestFocus()) {
          requestFocus();
        }
      });
    }
  }

  /// ✅ 포커스 요청 가능 여부 체크
  bool _shouldRequestFocus() {
    if (_context == null || !_context!.mounted) return false;

    // ✅ 현재 Route가 메인 화면인지 확인 (다이얼로그가 없는지)
    final currentRoute = ModalRoute.of(_context!);
    if (currentRoute == null || !currentRoute.isCurrent) return false;

    // ✅ 다이얼로그가 열려있는지 확인
    final navigator = Navigator.of(_context!, rootNavigator: false);
    if (navigator.canPop()) return false; // 다이얼로그 등이 열려있음

    return true;
  }

  /// 높이 업데이트 (디바운스)
  void scheduleHeightUpdate() {
    _heightDebounce?.cancel();
    _heightDebounce = Timer(const Duration(milliseconds: 50), _updateHeight);
  }

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

  /// ✅ 포커스 요청 (다이얼로그 체크 포함)
  void requestFocus() {
    if (!ref.mounted || _focusNode == null) return;

    // ✅ 다이얼로그 체크
    if (!_shouldRequestFocus()) {
      Logger.debug('[ChatInputAction] Skipping focus request - dialog or modal is open');
      return;
    }

    Future.microtask(() {
      if (ref.mounted && _focusNode!.canRequestFocus) {
        _focusNode!.requestFocus();
        Logger.debug('[ChatInputAction] Focus requested');
      }
    });
  }

  /// 초기화 완료 후 높이 업데이트
  void updateHeightImmediate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.mounted) _updateHeight();
    });
  }

  /// 텍스트 삽입 (붙여넣기용)
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

/// ✅ Provider 정의
final chatInputActionProvider = NotifierProvider<ChatInputActionNotifier, void>(
  ChatInputActionNotifier.new,
);
