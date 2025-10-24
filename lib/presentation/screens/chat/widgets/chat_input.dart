// lib/presentation/screens/chat/widgets/chat_input.dart

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
import '../../../../domain/providers/sidebar_state_provider.dart';
import '../../../shared/widgets/error_dialog.dart';
import 'attachment_preview_section.dart';
import 'chat_text_field.dart';
import 'left_buttons.dart';
import 'right_buttons.dart';

class ChatInput extends ConsumerStatefulWidget {
  const ChatInput({super.key});

  @override
  ConsumerState createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState {
  // ✅ 컨트롤러 및 키
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _containerKey = GlobalKey();

  // ✅ 캐싱된 상수
  static const _borderRadius = BorderRadius.all(Radius.circular(UIConstants.radiusLg));
  static const _shadowOffset = Offset(0, -4);

  // ✅ 높이 업데이트 제한을 위한 플래그
  bool _isHeightUpdateScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    // ✅ initState에서만 초기 높이 업데이트
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateHeight());
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ✅ 텍스트 변경 핸들러 분리
  void _onTextChanged() {
    ref.read(chatInputStateProvider.notifier).updateContent(_controller.text);
  }

  // ✅ 포커스 변경 핸들러 최적화
  void _onFocusChanged() {
    if (!_focusNode.hasFocus && mounted) {
      Future.delayed(UIConstants.shortDuration, () {
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
          Logger.debug('ChatInput Listener: Requesting focus.');
          _focusNode.requestFocus();
        }
      });
    }
  }

  // ✅ 높이 업데이트 최적화 (중복 호출 방지)
  void _updateHeight() {
    if (_isHeightUpdateScheduled) return;
    _isHeightUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        ref.read(chatInputStateProvider.notifier).updateHeight(renderBox.size.height);
      }
      _isHeightUpdateScheduled = false;
    });
  }

  // ✅ 포커스 요청 메서드 통합 및 최적화
  void _requestFocus() {
    if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
      Future.microtask(() {
        if (mounted) {
          Logger.debug('ChatInput: Explicitly requesting focus.');
          _focusNode.requestFocus();
        }
      });
    }
  }

  // ✅ 메시지 전송 최적화
  Future<void> _sendMessage() async {
    final inputState = ref.read(chatInputStateProvider);
    if (!inputState.canSend) return;

    final activeSession = ref.read(activeSessionProvider);
    final int sessionId;

    if (activeSession == null) {
      sessionId = await createNewSession(ref, '새로운 대화');
      Logger.info('New session created and selected: $sessionId');
    } else {
      sessionId = activeSession;
    }

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

  // ✅ 첨부파일 제거 최적화
  void _removeAttachment(String attachmentId) {
    ref.read(chatInputStateProvider.notifier).removeAttachment(attachmentId);
    _updateHeight(); // ✅ 높이 변경이 필요한 시점에만 호출
    _requestFocus();
  }

  // ✅ 스트리밍 취소 최적화
  void _cancelStreaming() {
    ref.read(sendMessageMutationProvider.notifier).cancel();
    _requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Provider 감시 최적화 (.select() 사용)
    final sendStatus = ref.watch(
        sendMessageMutationProvider.select((state) => state.status)
    );
    final inputState = ref.watch(chatInputStateProvider);
    final sidebarWidth = ref.watch(
        sidebarStateProvider.select((state) =>
        state.shouldShowExpanded
            ? UIConstants.sessionListWidth + (UIConstants.spacingMd * 2)
            : UIConstants.sessionListCollapsedWidth + (UIConstants.spacingMd * 2)
        )
    );

    final isSending = sendStatus == SendMessageStatus.sending ||
        sendStatus == SendMessageStatus.streaming;

    return RepaintBoundary(
      child: AnimatedContainer(
        key: _containerKey,
        duration: UIConstants.sidebarAnimationDuration,
        curve: Curves.easeInOut,
        margin: EdgeInsets.fromLTRB(
          sidebarWidth,
          UIConstants.spacingMd,
          UIConstants.spacingMd,
          UIConstants.spacingMd,
        ),
        decoration: _buildContainerDecoration(context),
        child: ClipRRect(
          borderRadius: _borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: UIConstants.glassBlur,
              sigmaY: UIConstants.glassBlur,
            ),
            child: Container(
              decoration: _buildInnerDecoration(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 첨부파일 미리보기
                  if (inputState.attachmentIds.isNotEmpty)
                    AttachmentPreviewSection(
                      attachmentIds: inputState.attachmentIds,
                      onRemove: _removeAttachment,
                    ),

                  // 입력 영역
                  Container(
                    padding: const EdgeInsets.all(UIConstants.spacingMd),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          // 텍스트 입력 필드
                          ChatTextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            isSending: isSending,
                            canSend: inputState.canSend,
                            onSend: _sendMessage,
                            onChanged: (_) => _updateHeight(),
                          ),
                          // 왼쪽 액션 버튼들만 표시
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              LeftButtons(
                                isSending: isSending,
                                onRequestFocus: _requestFocus,
                                textController: _controller,
                              ),

                              // 오른쪽 버튼 섹션 (파이프라인 + 프리셋 + 전송 버튼)
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

  // ✅ BoxDecoration 빌더 메서드 (재사용성 향상)
  BoxDecoration _buildContainerDecoration(BuildContext context) {
    return BoxDecoration(
      borderRadius: _borderRadius,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(UIConstants.alpha10),
          blurRadius: UIConstants.glassBlur,
          offset: _shadowOffset,
        ),
      ],
    );
  }

  BoxDecoration _buildInnerDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.surface.withAlpha(UIConstants.alpha90),
      borderRadius: _borderRadius,
      border: Border.all(
        color: theme.colorScheme.outline.withAlpha(UIConstants.alpha20),
        width: 1,
      ),
    );
  }
}
