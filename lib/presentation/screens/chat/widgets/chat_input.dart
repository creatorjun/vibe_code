// lib/presentation/screens/chat/widgets/chat_input.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/utils/logger.dart';
import '../../../../domain/mutations/create_session_mutation.dart';
import '../../../../domain/mutations/send_message_mutation.dart';
import '../../../../domain/providers/chat_provider.dart';
import '../../../../domain/providers/chat_input_state_provider.dart';
import '../../../shared/widgets/error_dialog.dart';
import 'attachment_preview_section.dart';
import 'chat_text_field.dart';
import 'left_buttons.dart';
import 'right_buttons.dart';

class ChatInput extends ConsumerStatefulWidget {
  const ChatInput({super.key});

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _containerKey = GlobalKey();
  Timer? _heightDebounce;

  // ✅ const 상수로 변경
  static const _borderRadius = BorderRadius.all(Radius.circular(UIConstants.radiusLg));
  static const _shadowOffset = Offset(0, -4);
  static const _padding = EdgeInsets.all(UIConstants.spacingMd);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateHeight());
  }

  @override
  void dispose() {
    _heightDebounce?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    ref.read(chatInputStateProvider.notifier).updateContent(_controller.text);
    _heightDebounce?.cancel();
    _heightDebounce = Timer(const Duration(milliseconds: 50), _updateHeight);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && mounted) {
      Future.delayed(UIConstants.shortDuration, () {
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  void _updateHeight() {
    if (!mounted) return;

    final renderBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;
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

  void _requestFocus() {
    if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
      Future.microtask(() {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  Future<void> _sendMessage() async {
    final inputState = ref.read(chatInputStateProvider);
    if (!inputState.canSend) return;

    final activeSession = ref.read(activeSessionProvider);
    final sessionId = activeSession ?? await createNewSession(ref, '새로운 대화');

    final content = inputState.content.trim();
    final attachmentIds = List<String>.from(inputState.attachmentIds);

    _controller.clear();
    ref.read(chatInputStateProvider.notifier).clear();

    try {
      await ref.read(sendMessageMutationProvider.notifier).sendMessage(
        sessionId: sessionId,
        content: content.isEmpty ? '첨부파일' : content,
        attachmentIds: attachmentIds,
      );
    } catch (e, stackTrace) {
      Logger.error('Send message mutation failed', e, stackTrace);
      if (mounted) {
        await ErrorDialog.show(
          context: context,
          title: '메시지 전송 실패',
          message: ErrorHandler.getErrorMessage(e),
        );
      }
    } finally {
      _requestFocus();
    }
  }

  void _removeAttachment(String attachmentId) {
    ref.read(chatInputStateProvider.notifier).removeAttachment(attachmentId);
    _updateHeight();
    _requestFocus();
  }

  void _cancelStreaming() {
    ref.read(sendMessageMutationProvider.notifier).cancel();
    _requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isSending = ref.watch(
      sendMessageMutationProvider.select((state) =>
      state.status == SendMessageStatus.sending ||
          state.status == SendMessageStatus.streaming
      ),
    );
    final inputState = ref.watch(chatInputStateProvider);

    // ✅ 첨부파일 변경 감지
    ref.listen(
      chatInputStateProvider.select((s) => s.attachmentIds.length),
          (previous, next) {
        if (previous != next) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _heightDebounce?.cancel();
            _heightDebounce = Timer(const Duration(milliseconds: 100), _updateHeight);
          });
        }
      },
    );

    final theme = Theme.of(context);

    return RepaintBoundary(
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
                color: theme.colorScheme.surface.withAlpha(UIConstants.alpha90),
                border: Border.all(
                  color: theme.colorScheme.outline.withAlpha(UIConstants.alpha20),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (inputState.attachmentIds.isNotEmpty)
                    AttachmentPreviewSection(
                      attachmentIds: inputState.attachmentIds,
                      onRemove: _removeAttachment,
                    ),
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
                            onSend: _sendMessage,
                            onChanged: (_) => _updateHeight(),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              LeftButtons(
                                isSending: isSending,
                                onRequestFocus: _requestFocus,
                                textController: _controller,
                              ),
                              RightButtons(
                                isSending: isSending,
                                canSend: inputState.canSend,
                                onSend: _sendMessage,
                                onCancel: _cancelStreaming,
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
    );
  }
}
