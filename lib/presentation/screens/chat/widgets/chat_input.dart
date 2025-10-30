// lib/presentation/screens/chat/widgets/chat_input.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:vibe_code/presentation/screens/settings/widgets/custom_snack_bar.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../domain/notifiers/chat_input/chat_input_action_notifier.dart';
import '../../../../domain/notifiers/chat_input/paste_handler_notifier.dart';
import '../../../../domain/notifiers/chat_input/drop_handler_notifier.dart';
import '../../../../domain/notifiers/chat_input/message_send_actions.dart';
import '../../../../domain/mutations/send_message/send_message_mutation.dart';
import '../../../../domain/providers/chat_input_state_provider.dart';
import 'attachment_preview_section.dart';
import 'chat_text_field.dart';
import 'left_buttons.dart';
import 'right_buttons.dart';

/// ✅ Riverpod 3.0 패턴: UI 조합만 담당
/// 비즈니스 로직은 모두 Notifier로 분리
class ChatInput extends ConsumerStatefulWidget {
  const ChatInput({super.key});

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _containerKey = GlobalKey();

  static const _borderRadius = BorderRadius.all(
    Radius.circular(UIConstants.radiusLg),
  );
  static const _shadowOffset = Offset(0, -4);
  static const _padding = EdgeInsets.all(UIConstants.spacingMd);

  @override
  void initState() {
    super.initState();
    // ✅ ChatInputActionNotifier 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatInputActionProvider.notifier).initialize(
        context: context,
        textController: _controller,
        focusNode: _focusNode,
        containerKey: _containerKey,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// ✅ 붙여넣기 처리 (단순 호출 + 결과 처리)
  Future<void> _handlePaste() async {
    final result = await ref.read(pasteHandlerProvider.notifier).handlePaste();

    if (!mounted) return;

    // ✅ sealed class 패턴 매칭
    switch (result) {
      case PasteError(:final message):
        _showSnackBar(message, isError: true);
      case PasteSuccess():
      case PasteNoContent():
      case PasteCancelled():
        break;
    }
  }

  /// ✅ 드롭 처리 (단순 호출 + 결과 처리)
  Future<void> _handleDrop(PerformDropEvent event) async {
    final result = await ref.read(dropHandlerProvider.notifier).handleDrop(event);

    if (!mounted) return;

    switch (result) {
      case DropSuccess(:final fileName):
        _showSnackBar('파일이 첨부되었습니다: $fileName');
      case DropError(:final message):
        _showSnackBar('파일 첨부 실패: $message', isError: true);
      case DropCancelled():
        break;
    }
  }

  /// ✅ 메시지 전송 (단순 호출 + 결과 처리)
  Future<void> _handleSend() async {
    // ✅ .notifier 추가
    final result = await ref.read(messageSendActionsProvider.notifier).sendMessage();

    if (!mounted) return;

    if (result is SendActionError) {
      _showSnackBar('전송 실패: ${result.message}', isError: true);
    }
  }

  /// ✅ SnackBar 표시 (UI 피드백)
  void _showSnackBar(String message, {bool isError = false}) {
    isError ? CustomSnackBar.showError(context, message):
    CustomSnackBar.showSuccess(context, message);
  }

  /// 첨부파일 제거
  void _removeAttachment(String attachmentId) {
    ref.read(chatInputStateProvider.notifier).removeAttachment(attachmentId);
    ref.read(chatInputActionProvider.notifier).scheduleHeightUpdate();
  }

  /// 높이 업데이트 트리거
  void _updateHeight() {
    ref.read(chatInputActionProvider.notifier).scheduleHeightUpdate();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Riverpod 3.0: select로 필요한 상태만 구독
    final isSending = ref.watch(
      sendMessageMutationProvider.select(
            (state) =>
        state.status == SendMessageStatus.sending ||
            state.status == SendMessageStatus.streaming,
      ),
    );
    final inputState = ref.watch(chatInputStateProvider);
    final isDragging = ref.watch(dropHandlerProvider.select((s) => s.isDragging));

    // ✅ 첨부파일 변경 시 높이 업데이트 (ref.listen)
    ref.listen(
      chatInputStateProvider.select((s) => s.attachmentIds.length),
          (previous, next) {
        if (previous != next) {
          ref.read(chatInputActionProvider.notifier).scheduleHeightUpdate();
        }
      },
    );

    final theme = Theme.of(context);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): _handlePaste,
        const SingleActivator(LogicalKeyboardKey.keyV, meta: true): _handlePaste,
      },
      child: RepaintBoundary(
        // ✅ DropRegion: 드래그앤드롭 영역
        child: DropRegion(
          formats: Formats.standardFormats,
          onDropOver: ref.read(dropHandlerProvider.notifier).onDropOver,
          onDropEnter: (_) => ref.read(dropHandlerProvider.notifier).onDropEnter(),
          onDropLeave: (_) => ref.read(dropHandlerProvider.notifier).onDropLeave(),
          onPerformDrop: _handleDrop,
          child: Container(
            key: _containerKey,
            margin: const EdgeInsets.all(UIConstants.spacingMd),
            decoration: BoxDecoration(
              borderRadius: _borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(UIConstants.alpha10),
                  blurRadius: UIConstants.glassBlur,
                  offset: _shadowOffset,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: _borderRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: UIConstants.glassBlur,
                  sigmaY: UIConstants.glassBlur,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDragging
                        ? theme.colorScheme.primary.withAlpha(UIConstants.alpha20)
                        : theme.colorScheme.surface.withAlpha(UIConstants.alpha90),
                    border: Border.all(
                      color: isDragging
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withAlpha(UIConstants.alpha20),
                      width: isDragging ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ 드래그 중 오버레이
                      if (isDragging)
                        Padding(
                          padding: const EdgeInsets.all(UIConstants.spacingMd),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.upload_file,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: UIConstants.spacingSm),
                              Text(
                                '파일을 여기에 놓으세요',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // ✅ 첨부파일 미리보기
                      if (inputState.attachmentIds.isNotEmpty)
                        AttachmentPreviewSection(
                          attachmentIds: inputState.attachmentIds,
                          onRemove: _removeAttachment,
                        ),
                      // ✅ 입력 필드 + 버튼
                      Padding(
                        padding: _padding,
                        child: SafeArea(
                          top: false,
                          child: Column(
                            children: [
                              ChatTextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                isSending: isSending,
                                canSend: inputState.canSend,
                                onSend: _handleSend,
                                onChanged: (_) => _updateHeight(),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  LeftButtons(
                                    isSending: isSending,
                                    onRequestFocus: () {
                                      ref.read(chatInputActionProvider.notifier).requestFocus();
                                    },
                                    textController: _controller,
                                  ),
                                  RightButtons(
                                    isSending: isSending,
                                    canSend: inputState.canSend,
                                    onSend: _handleSend,
                                    onCancel: () {
                                      // ✅ .notifier 추가
                                      ref.read(messageSendActionsProvider.notifier).cancelStreaming();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
