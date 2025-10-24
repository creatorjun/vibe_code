// lib/presentation/screens/chat/widgets/left_buttons.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/utils/logger.dart';
import '../../../../domain/providers/chat_input_state_provider.dart';
import '../../../../domain/providers/chat_provider.dart';
import '../../../shared/widgets/error_dialog.dart';
import 'github_analysis_dialog.dart';

class LeftButtons extends ConsumerWidget {
  final bool isSending;
  final VoidCallback onRequestFocus;
  final TextEditingController textController;

  const LeftButtons({
    super.key,
    required this.isSending,
    required this.onRequestFocus,
    required this.textController,
  });

  // 파일 첨부 기능
  Future<void> _pickFile(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: false);
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) return;

      Logger.info('Uploading file: ${file.path}');
      final repository = ref.read(attachmentRepositoryProvider);
      final attachmentId = await repository.uploadFile(file.path!);
      Logger.info('File uploaded successfully: $attachmentId');

      if (context.mounted) {
        ref.read(chatInputStateProvider.notifier).addAttachment(attachmentId);
      }
    } catch (e) {
      if (context.mounted) {
        await ErrorDialog.show(
          context: context,
          title: '파일 첨부 실패',
          message: ErrorHandler.getErrorMessage(e),
        );
      }
    } finally {
      onRequestFocus();
    }
  }

  // GitHub 프로젝트 분석 기능
  Future<void> _analyzeProject(
    BuildContext context,
    WidgetRef ref,
    TextEditingController controller,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const GitHubAnalysisDialog(),
    );

    if (result == null || !context.mounted) {
      onRequestFocus();
      return;
    }

    Directory? tempDir;
    try {
      tempDir = Directory.systemTemp.createTempSync('github_analysis_');
      final file = File('${tempDir.path}/github_analysis.md');
      await file.writeAsString(result);

      final repository = ref.read(attachmentRepositoryProvider);
      final attachmentId = await repository.uploadFile(file.path);

      if (context.mounted) {
        ref.read(chatInputStateProvider.notifier).addAttachment(attachmentId);
        controller.text = '프로젝트 분석 결과를 요약해주세요.';
      }
    } catch (e) {
      if (context.mounted) {
        await ErrorDialog.show(
          context: context,
          title: '분석 결과 첨부 실패',
          message: ErrorHandler.getErrorMessage(e),
        );
      }
    } finally {
      await tempDir?.delete(recursive: true);
      onRequestFocus();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.attach_file),
          iconSize: UIConstants.iconMd,
          onPressed: isSending ? null : () => _pickFile(context, ref),
          tooltip: '파일 첨부',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: UIConstants.iconLg + UIConstants.spacingSm,
            minHeight: UIConstants.iconLg + UIConstants.spacingSm,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.code),
          iconSize: UIConstants.iconMd,
          onPressed: isSending
              ? null
              : () => _analyzeProject(context, ref, textController),
          tooltip: 'GitHub 프로젝트 분석',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: UIConstants.iconLg + UIConstants.spacingSm,
            minHeight: UIConstants.iconLg + UIConstants.spacingSm,
          ),
        ),
      ],
    );
  }
}
