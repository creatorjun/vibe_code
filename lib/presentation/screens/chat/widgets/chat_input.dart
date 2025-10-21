import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../data/database/app_database.dart';
import '../../../../domain/providers/attachment_provider.dart';
import '../../../../domain/providers/chat_provider.dart';
import '../../../../domain/providers/streaming_state_provider.dart';
import '../../../../domain/providers/chat_input_state_provider.dart';
import '../../../../domain/mutations/send_message_mutation.dart';
import '../../../../domain/mutations/create_session_mutation.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/utils/logger.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/error_dialog.dart';
import '../../settings/settings_screen.dart';
import 'attachment_preview_list.dart';
import 'github_analysis_dialog.dart';

class ChatInput extends ConsumerStatefulWidget {
  final int? sessionId;

  const ChatInput({
    super.key,
    this.sessionId,
  });

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final List<String> _attachmentIds = [];
  final GlobalKey _containerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateHeight();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox =
      _containerKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        ref.read(chatInputHeightProvider.notifier).updateHeight(renderBox.size.height);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isStreaming = ref.watch(streamingStateProvider);
    final mutationState = ref.watch(sendMessageMutationProvider);

    final bool canSend = _controller.text.trim().isNotEmpty && !isStreaming;

    return GlassContainer(
      key: _containerKey,
      margin: const EdgeInsets.all(UIConstants.spacingMd),
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_attachmentIds.isNotEmpty)
            Consumer(
              builder: (context, ref, child) {
                final attachments = <Attachment>[];

                for (final id in _attachmentIds) {
                  final attachmentAsync = ref.watch(attachmentProvider(id));
                  if (attachmentAsync.hasValue && attachmentAsync.value != null) {
                    attachments.add(attachmentAsync.value!);
                  }
                }

                if (attachments.isEmpty) return const SizedBox.shrink();

                WidgetsBinding.instance.addPostFrameCallback((_) => _updateHeight());

                return AttachmentPreviewList(
                  attachments: attachments,
                  onRemove: isStreaming ? null : _removeAttachment,
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.all(UIConstants.spacingMd),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  tooltip: '파일 첨부',
                  onPressed: isStreaming ? null : _pickFile,
                ),
                IconButton(
                  icon: const Icon(Icons.code),
                  tooltip: 'GitHub 프로젝트 분석',
                  onPressed: isStreaming ? null : _analyzeProject,
                ),
                const SizedBox(width: UIConstants.spacingSm),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: UIConstants.chatInputMinHeight,
                      maxHeight: UIConstants.chatInputMaxHeight,
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: !isStreaming,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      autofocus: widget.sessionId == null,
                      decoration: InputDecoration(
                        hintText: isStreaming ? 'AI가 응답 중입니다...' : '메시지를 입력하세요...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(UIConstants.radiusMd),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: UIConstants.spacingMd,
                          vertical: UIConstants.spacingSm,
                        ),
                      ),
                      onChanged: (_) {
                        setState(() {});
                        _updateHeight();
                      },
                      onSubmitted: canSend ? (_) => _sendMessage() : null,
                    ),
                  ),
                ),
                const SizedBox(width: UIConstants.spacingSm),
                if (isStreaming)
                  IconButton(
                    icon: const Icon(Icons.stop),
                    tooltip: '중지',
                    onPressed: () {
                      ref.read(sendMessageMutationProvider.notifier).cancel();
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Colors.white,
                    ),
                  )
                else if (mutationState.status == SendMessageStatus.sending)
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.send),
                    tooltip: '전송',
                    onPressed: canSend ? _sendMessage : null,
                    style: IconButton.styleFrom(
                      backgroundColor: canSend ? Theme.of(context).colorScheme.primary : null,
                      foregroundColor: canSend ? Colors.white : null,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final attachmentIds = List<String>.from(_attachmentIds);

    _controller.clear();
    _attachmentIds.clear();
    setState(() {});
    _updateHeight();

    try {
      int sessionId = widget.sessionId ?? 0;

      if (widget.sessionId == null) {
        sessionId = await createNewSession(ref);
      }

      await ref.read(sendMessageMutationProvider.notifier).sendMessage(
        sessionId: sessionId,
        content: content,
        attachmentIds: attachmentIds,
      );

      final state = ref.read(sendMessageMutationProvider);
      if (state.status == SendMessageStatus.error && mounted) {
        await ErrorDialog.show(
          context: context,
          title: '메시지 전송 실패',
          message: state.error ?? '알 수 없는 오류가 발생했습니다',
          onRetry: () {
            _controller.text = content;
            _attachmentIds.addAll(attachmentIds);
            setState(() {});
            _updateHeight();
          },
          onDismiss: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          },
        );
      }
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
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
      );

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
            _updateHeight();
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
        });
        _updateHeight();

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
    _updateHeight();
  }
}
