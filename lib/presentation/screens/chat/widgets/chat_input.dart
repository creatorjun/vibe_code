// lib/presentation/screens/chat/widgets/chat_input.dart (최종 수정)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/utils/logger.dart';
import '../../../../domain/mutations/send_message_mutation.dart';
import '../../../../domain/providers/chat_provider.dart';
import '../../../../domain/providers/chat_input_state_provider.dart';
import '../../../../presentation/shared/widgets/error_dialog.dart';
import 'attachment_item.dart';
import 'github_analysis_dialog.dart';
import 'pipeline_depth_selector.dart';
import 'preset_selector.dart';

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
    // 포커스 리스너 유지
    _focusNode.addListener(_ensureFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_ensureFocus);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // 다이얼로그 없을 때만 포커스 요청 (기존 로직 유지)
  void _ensureFocus() {
    if (!_focusNode.hasFocus && mounted) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
          Logger.debug('[ChatInput] Listener: No dialog detected, requesting focus.');
          _focusNode.requestFocus();
        } else if (mounted) {
          Logger.debug('[ChatInput] Listener: Dialog detected, skipping focus request.');
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

  // 포커스 요청 헬퍼 메서드
  void _requestChatInputFocus() {
    Future.microtask(() {
      if (mounted) {
        Logger.debug('[ChatInput] Explicitly requesting focus.');
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
      final sessionCreator = ref.read(sessionCreatorProvider.notifier);
      sessionId = await sessionCreator.createSession('New Chat');
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
      content: content.isEmpty ? '[첨부파일]' : content,
      attachmentIds: attachmentIds,
    )
        .catchError((e, stackTrace) {
      Logger.error('Send message mutation failed', e, stackTrace);
      if (mounted) {
        ErrorDialog.show(
          context: context,
          title: '메시지 전송 실패',
          message: ErrorHandler.getErrorMessage(e),
        ).then((_) {
          // ErrorDialog 닫힌 후 포커스 요청
          _requestChatInputFocus();
        });
      }
    });

    // 메시지 전송 시작 시 포커스 요청
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
            // 파일 첨부 완료 후 포커스 요청
            _requestChatInputFocus();
          }
        } else {
          // 파일 선택 취소 시 포커스 요청
          _requestChatInputFocus();
        }
      } else {
        // 파일 선택 취소 시 포커스 요청
        _requestChatInputFocus();
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.show(
          context: context,
          title: '파일 업로드 실패',
          message: ErrorHandler.getErrorMessage(e),
        ).then((_) {
          // ErrorDialog 닫힌 후 포커스 요청
          _requestChatInputFocus();
        });
      }
    }
  }

  Future<void> _analyzeProject() async {
    await showDialog<String>(
      context: context,
      builder: (context) => const GitHubAnalysisDialog(),
    ).then((result) async { // .then() 사용
      // 다이얼로그 닫힌 직후 포커스 요청
      _requestChatInputFocus();

      if (result != null && mounted) {
        final tempDir = Directory.systemTemp.createTempSync('github_analysis_');
        final file = File('${tempDir.path}/github_analysis.md');
        await file.writeAsString(result);

        try {
          final repository = ref.read(attachmentRepositoryProvider);
          final attachmentId = await repository.uploadFile(file.path);

          ref.read(chatInputStateProvider.notifier).addAttachment(attachmentId);
          _controller.text = '프로젝트 분석 결과를 첨부했습니다. 코드 리뷰나 개선 사항을 요청해주세요.';
          // 추가 포커스 요청 불필요

          await tempDir.delete(recursive: true);
        } catch (e) {
          await tempDir.delete(recursive: true);
          if (mounted) {
            await ErrorDialog.show(
              context: context,
              title: '첨부파일 업로드 실패',
              message: ErrorHandler.getErrorMessage(e),
            ).then((_) {
              // ErrorDialog 닫힌 후 포커스 요청
              _requestChatInputFocus();
            });
          }
        }
      }
    });
  }

  void _removeAttachment(String attachmentId) {
    ref.read(chatInputStateProvider.notifier).removeAttachment(attachmentId);
    // 첨부파일 제거 후 포커스 요청
    _requestChatInputFocus();
  }

  void _cancelStreaming() {
    ref.read(sendMessageMutationProvider.notifier).cancel();
    // 스트리밍 취소 후 포커스 요청
    _requestChatInputFocus();
  }

  @override
  Widget build(BuildContext context) {
    final activeSession = ref.watch(activeSessionProvider);
    final sendState = ref.watch(sendMessageMutationProvider);
    final inputState = ref.watch(chatInputStateProvider);

    final isSending =
        sendState.status == SendMessageStatus.sending ||
            sendState.status == SendMessageStatus.streaming;

    return Column(
      key: _containerKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        // PipelineDepthSelector와 PresetSelector Row
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.spacingMd,
            vertical: UIConstants.spacingSm,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
          ),
          child: const Row(
            children: [
              IntrinsicWidth(
                child: PipelineDepthSelector(),
              ),
              SizedBox(width: UIConstants.spacingMd),
              Expanded(child: PresetSelector()),
            ],
          ),
        ),

        // 첨부파일 미리보기
        if (inputState.attachmentIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(UIConstants.spacingMd),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: inputState.attachmentIds
                    .map(
                      (id) => FutureBuilder(
                    future: ref
                        .read(attachmentRepositoryProvider)
                        .getAttachment(id),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return AttachmentItem(
                          attachment: snapshot.data!,
                          onRemove: () => _removeAttachment(id),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                )
                    .toList(),
              ),
            ),
          ),

        // 입력 필드
        Container(
          padding: const EdgeInsets.all(UIConstants.spacingMd),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: isSending ? null : _pickFile,
                  tooltip: '파일 첨부',
                ),
                IconButton(
                  icon: const Icon(Icons.code),
                  onPressed: isSending ? null : _analyzeProject,
                  tooltip: 'GitHub 분석',
                ),
                const SizedBox(width: UIConstants.spacingSm),
                Expanded(
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.enter &&
                            !HardwareKeyboard.instance.isShiftPressed) {
                          if (inputState.canSend && !isSending) {
                            _sendMessage();
                            return KeyEventResult.handled;
                          }
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: UIConstants.chatInputMinHeight,
                        maxHeight: UIConstants.chatInputMaxHeight,
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true, // 앱 시작 시 자동 포커스
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        enabled: !isSending,
                        decoration: InputDecoration(
                          hintText: activeSession == null
                              ? '세션을 선택하거나 생성하세요'
                              : '메시지를 입력하세요...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              UIConstants.radiusMd,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: UIConstants.spacingMd,
                            vertical: UIConstants.spacingSm,
                          ),
                        ),
                        onChanged: (_) => _updateHeight(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: UIConstants.spacingSm),
                if (isSending)
                  IconButton(
                    icon: const Icon(Icons.stop_circle),
                    onPressed: _cancelStreaming,
                    tooltip: '취소',
                    color: Theme.of(context).colorScheme.error,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: inputState.canSend && !isSending
                        ? _sendMessage
                        : null,
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
    );
  }
}