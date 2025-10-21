// lib/presentation/screens/chat/widgets/chat_input.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/utils/logger.dart';
import '../../../../domain/mutations/send_message_mutation.dart';
import '../../../../domain/providers/chat_provider.dart';
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
  final List<String> _attachmentIds = [];
  bool _isComposing = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final activeSession = ref.read(activeSessionProvider);
    if (activeSession == null) {
      // 새 세션 생성
      final sessionCreator = ref.read(sessionCreatorProvider.notifier);
      final newSessionId = await sessionCreator.createSession('New Chat');
      ref.read(activeSessionProvider.notifier).select(newSessionId);
    }

    final sessionId = ref.read(activeSessionProvider)!;
    final attachmentIds = List<String>.from(_attachmentIds);

    // 입력 필드 클리어
    _controller.clear();
    _attachmentIds.clear();
    setState(() {
      _isComposing = false;
    });

    // 메시지 전송
    try {
      await ref
          .read(sendMessageMutationProvider.notifier)
          .sendMessage(
            sessionId: sessionId,
            content: text,
            attachmentIds: attachmentIds,
          );
    } catch (e) {
      if (mounted) {
        await ErrorDialog.show(
          context: context,
          title: '메시지 전송 실패',
          message: ErrorHandler.getErrorMessage(e),
        );
      }
    }
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
            setState(() {
              _attachmentIds.add(attachmentId);
            });
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

        setState(() {
          _attachmentIds.add(attachmentId);
          _controller.text = '프로젝트 분석 결과를 첨부했습니다. 코드 리뷰나 개선 사항을 요청해주세요.';
          _isComposing = true;
        });

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
    setState(() {
      _attachmentIds.remove(attachmentId);
    });
  }

  void _cancelStreaming() {
    ref.read(sendMessageMutationProvider.notifier).cancel();
  }

  @override
  Widget build(BuildContext context) {
    final activeSession = ref.watch(activeSessionProvider);
    final sendState = ref.watch(sendMessageMutationProvider);
    final isSending =
        sendState.status == SendMessageStatus.sending ||
        sendState.status == SendMessageStatus.streaming;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🆕 파이프라인 깊이 선택기
        const PipelineDepthSelector(),

        // 첨부파일 미리보기
        if (_attachmentIds.isNotEmpty)
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
                children: _attachmentIds
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
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: UIConstants.chatInputMinHeight,
                      maxHeight: UIConstants.chatInputMaxHeight,
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
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
                      onChanged: (text) {
                        setState(() {
                          _isComposing = text.trim().isNotEmpty;
                        });
                      },
                      onSubmitted: (_) {
                        if (_isComposing && !isSending) {
                          _sendMessage();
                        }
                      },
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
                    onPressed: _isComposing && !isSending ? _sendMessage : null,
                    tooltip: '전송',
                    color: _isComposing
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
