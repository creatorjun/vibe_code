// lib/presentation/screens/chat/widgets/chat_input.dart
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

    // TextEditingController 변경 시 Provider 업데이트
    _controller.addListener(() {
      ref.read(chatInputStateProvider.notifier).updateContent(_controller.text);
    });

    // 초기 높이 측정
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateHeight());

    // 포커스 감시 - 포커스를 잃으면 다시 복원
    _focusNode.addListener(_ensureFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_ensureFocus);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 포커스 유지 함수
  void _ensureFocus() {
    if (!_focusNode.hasFocus && mounted) {
      // 짧은 지연 후 포커스 복원 (다이얼로그 등의 경우 예외 처리)
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _focusNode.requestFocus();
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

  Future<void> _sendMessage() async {
    final inputState = ref.read(chatInputStateProvider);

    if (!inputState.canSend) return;

    final activeSession = ref.read(activeSessionProvider);
    if (activeSession == null) {
      // 새 세션 생성
      final sessionCreator = ref.read(sessionCreatorProvider.notifier);
      final newSessionId = await sessionCreator.createSession('New Chat');
      ref.read(activeSessionProvider.notifier).select(newSessionId);
    }

    final sessionId = ref.read(activeSessionProvider)!;
    final content = inputState.content.trim();
    final attachmentIds = List<String>.from(inputState.attachmentIds);

    // 입력 필드 클리어
    _controller.clear();
    ref.read(chatInputStateProvider.notifier).clear();

    // 메시지 전송 (await 제거 - 비동기 실행)
    ref
        .read(sendMessageMutationProvider.notifier)
        .sendMessage(
          sessionId: sessionId,
          content: content.isEmpty ? '[첨부파일]' : content,
          attachmentIds: attachmentIds,
        )
        .catchError((e) {
          if (mounted) {
            ErrorDialog.show(
              context: context,
              title: '메시지 전송 실패',
              message: ErrorHandler.getErrorMessage(e),
            );
          }
        });

    // 즉시 포커스 복원
    Future.microtask(() {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
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
            _focusNode.requestFocus();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.show(
          context: context,
          title: '파일 업로드 실패',
          message: ErrorHandler.getErrorMessage(e),
        );
      }
    }
  }

  Future<void> _analyzeProject() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const GitHubAnalysisDialog(),
    );

    if (result != null && mounted) {
      final tempDir = Directory.systemTemp.createTempSync('github_analysis_');
      final file = File('${tempDir.path}/github_analysis.md');
      await file.writeAsString(result);

      try {
        final repository = ref.read(attachmentRepositoryProvider);
        final attachmentId = await repository.uploadFile(file.path);

        ref.read(chatInputStateProvider.notifier).addAttachment(attachmentId);
        _controller.text = '프로젝트 분석 결과를 첨부했습니다. 코드 리뷰나 개선 사항을 요청해주세요.';
        _focusNode.requestFocus();

        await tempDir.delete(recursive: true);
      } catch (e) {
        await tempDir.delete(recursive: true);
        if (mounted) {
          await ErrorDialog.show(
            context: context,
            title: '첨부파일 업로드 실패',
            message: ErrorHandler.getErrorMessage(e),
          );
        }
      }
    }
  }

  void _removeAttachment(String attachmentId) {
    ref.read(chatInputStateProvider.notifier).removeAttachment(attachmentId);
  }

  void _cancelStreaming() {
    ref.read(sendMessageMutationProvider.notifier).cancel();
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
        // 파이프라인 깊이 선택기
        const PipelineDepthSelector(),

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
                // 첨부 파일 버튼
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: isSending ? null : _pickFile,
                  tooltip: '파일 첨부',
                ),

                // GitHub 분석 버튼
                IconButton(
                  icon: const Icon(Icons.code),
                  onPressed: isSending ? null : _analyzeProject,
                  tooltip: 'GitHub 분석',
                ),

                const SizedBox(width: UIConstants.spacingSm),

                // 텍스트 입력 필드
                Expanded(
                  child: Focus(
                    onKeyEvent: (node, event) {
                      // Enter 키 이벤트 처리
                      if (event is KeyDownEvent) {
                        // Shift 없이 Enter만 눌렀을 때
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
                        autofocus: true,
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

                // 전송/취소 버튼
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
