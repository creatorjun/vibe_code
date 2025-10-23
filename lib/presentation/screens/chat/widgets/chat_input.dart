// lib/presentation/screens/chat/widgets/chat_input.dart

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/constants/ui_constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/utils/logger.dart';
import '../../../../domain/mutations/create_session_mutation.dart';
import '../../../../domain/mutations/send_message_mutation.dart';
import '../../../../domain/providers/chat_provider.dart';
import '../../../../domain/providers/chat_input_state_provider.dart';
import '../../../shared/widgets/error_dialog.dart';
import 'attachment_preview_section.dart';
import 'chat_action_buttons.dart';
import 'chat_text_field.dart';
import 'github_analysis_dialog.dart';
import 'pipeline_preset_section.dart';

class ChatInput extends ConsumerStatefulWidget {
  const ChatInput({super.key});

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _containerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      ref.read(chatInputStateProvider.notifier).updateContent(_controller.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateHeight());
    _focusNode.addListener(_ensureFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_ensureFocus);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _ensureFocus() {
    if (!_focusNode.hasFocus && mounted) {
      Future.delayed(UIConstants.shortDuration, () {
        if (mounted) {
          if (ModalRoute.of(context)?.isCurrent ?? false) {
            Logger.debug('ChatInput Listener: No dialog detected, requesting focus.');
            _focusNode.requestFocus();
          } else if (mounted) {
            Logger.debug('ChatInput Listener: Dialog detected, skipping focus request.');
          }
        }
      });
    }
  }

  void _updateHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox =
      _containerKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        ref
            .read(chatInputStateProvider.notifier)
            .updateHeight(renderBox.size.height);
      }
    });
  }

  void _requestChatInputFocus() {
    Future.microtask(() {
      if (mounted) {
        Logger.debug('ChatInput: Explicitly requesting focus.');
        _focusNode.requestFocus();
      }
    });
  }

  Future<void> _sendMessage() async {
    final inputState = ref.read(chatInputStateProvider);
    if (!inputState.canSend) return;

    final activeSession = ref.read(activeSessionProvider);
    int sessionId;

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

    ref
        .read(sendMessageMutationProvider.notifier)
        .sendMessage(
      sessionId: sessionId,
      content: content.isEmpty ? '첨부파일' : content,
      attachmentIds: attachmentIds,
    )
        .catchError((e, stackTrace) {
      Logger.error('Send message mutation failed', e, stackTrace);
      if (mounted) {
        ErrorDialog.show(
          context: context,
          title: '메시지 전송 실패',
          message: ErrorHandler.getErrorMessage(e),
        ).then((_) => ErrorDialog);
      }
    });

    _requestChatInputFocus();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: false);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          Logger.info('Uploading file: ${file.path}');
          final repository = ref.read(attachmentRepositoryProvider);
          final attachmentId = await repository.uploadFile(file.path!);
          Logger.info('File uploaded successfully: $attachmentId');
          if (mounted) {
            ref
                .read(chatInputStateProvider.notifier)
                .addAttachment(attachmentId);
          }
          _requestChatInputFocus();
        } else {
          _requestChatInputFocus();
        }
      } else {
        _requestChatInputFocus();
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.show(
          context: context,
          title: '파일 첨부 실패',
          message: ErrorHandler.getErrorMessage(e),
        ).then((_) => ErrorDialog);
      }
      _requestChatInputFocus();
    }
  }

  Future<void> _analyzeProject() async {
    await showDialog(
      context: context,
      builder: (context) => const GitHubAnalysisDialog(),
    ).then((result) async {
      if (result != null && mounted) {
        final tempDir = Directory.systemTemp.createTempSync('github_analysis_');
        final file = File('${tempDir.path}/github_analysis.md');
        await file.writeAsString(result);

        try {
          final repository = ref.read(attachmentRepositoryProvider);
          final attachmentId = await repository.uploadFile(file.path);
          ref.read(chatInputStateProvider.notifier).addAttachment(attachmentId);
          _controller.text = '프로젝트 분석 결과를 요약해주세요.';
          await tempDir.delete(recursive: true);
        } catch (e) {
          await tempDir.delete(recursive: true);
          if (mounted) {
            await ErrorDialog.show(
              context: context,
              title: '분석 결과 첨부 실패',
              message: ErrorHandler.getErrorMessage(e),
            ).then((_) => ErrorDialog);
          }
        }
      }
    }).then((_) => _requestChatInputFocus());
  }

  void _removeAttachment(String attachmentId) {
    ref.read(chatInputStateProvider.notifier).removeAttachment(attachmentId);
    _requestChatInputFocus();
  }

  void _cancelStreaming() {
    ref.read(sendMessageMutationProvider.notifier).cancel();
    _requestChatInputFocus();
  }

  @override
  Widget build(BuildContext context) {
    final sendState = ref.watch(sendMessageMutationProvider);
    final inputState = ref.watch(chatInputStateProvider);
    final isSending = sendState.status == SendMessageStatus.sending ||
        sendState.status == SendMessageStatus.streaming;

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateHeight());

    return Container(
      key: _containerKey,
      margin: const EdgeInsets.all(UIConstants.spacingMd),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(UIConstants.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(UIConstants.alpha10),
            blurRadius: UIConstants.glassBlur,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(UIConstants.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: UIConstants.glassBlur,
            sigmaY: UIConstants.glassBlur,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surface
                  .withAlpha(UIConstants.alpha90),
              borderRadius: BorderRadius.circular(UIConstants.radiusLg),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withAlpha(UIConstants.alpha20),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 첨부파일 미리보기
                if (inputState.attachmentIds.isNotEmpty)
                  AttachmentPreviewSection(
                    attachmentIds: inputState.attachmentIds,
                    onRemove: _removeAttachment,
                  ),

                // 파이프라인 깊이 선택기 + 프리셋 선택기
                const PipelinePresetSection(),

                // 입력 영역
                Container(
                  padding: const EdgeInsets.all(UIConstants.spacingMd),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // 액션 버튼들
                        ChatActionButtons(
                          isSending: isSending,
                          onPickFile: _pickFile,
                          onAnalyzeProject: _analyzeProject,
                        ),
                        const SizedBox(width: UIConstants.spacingSm),

                        // 텍스트 입력 필드
                        Expanded(
                          child: ChatTextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            isSending: isSending,
                            canSend: inputState.canSend,
                            onSend: _sendMessage,
                            onChanged: (_) => _updateHeight(),
                          ),
                        ),
                        const SizedBox(width: UIConstants.spacingSm),

                        // 전송/취소 버튼
                        if (isSending)
                          IconButton(
                            icon: const Icon(Icons.stop_circle),
                            onPressed: _cancelStreaming,
                            tooltip: '전송 취소',
                            color: Theme.of(context).colorScheme.error,
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed:
                            inputState.canSend && !isSending ? _sendMessage : null,
                            tooltip: '전송',
                            color: inputState.canSend
                                ? Theme.of(context).colorScheme.primary
                                : null,
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
    );
  }
}
