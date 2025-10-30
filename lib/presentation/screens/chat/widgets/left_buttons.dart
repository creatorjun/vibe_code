import 'dart:io';
import 'github_analysis_dialog.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vibe_code/core/utils/logger.dart';
import 'package:vibe_code/core/errors/error_handler.dart';
import 'package:vibe_code/core/constants/ui_constants.dart';
import 'package:vibe_code/domain/providers/chat_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vibe_code/presentation/shared/widgets/error_dialog.dart';
import 'package:vibe_code/domain/providers/chat_input_state_provider.dart';

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
          title: '파일 업로드 실패',
          message: ErrorHandler.getErrorMessage(e),
        );
      }
    } finally {
      onRequestFocus();
    }
  }

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
        controller.text = '첨부된 GitHub 분석 결과를 검토해 주세요.';
      }
    } catch (e) {
      if (context.mounted) {
        await ErrorDialog.show(
          context: context,
          title: '분석 실패',
          message: ErrorHandler.getErrorMessage(e),
        );
      }
    } finally {
      await tempDir?.delete(recursive: true);
      onRequestFocus();
    }
  }

  Future<void> _pickProjectFolder(BuildContext context) async {
    try {
      final folderPath = await FilePicker.platform.getDirectoryPath();
      if (folderPath == null) return; // 취소 시 동작 없음

      Logger.info('Selected project folder: $folderPath');

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('프로젝트 폴더 지정됨:\n$folderPath')));
      }

      // 필요하면 상태 저장 로직 추가 가능
    } catch (e) {
      if (context.mounted) {
        await ErrorDialog.show(
          context: context,
          title: '폴더 선택 실패',
          message: '폴더 선택 중 오류가 발생했습니다: ${e.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 파일 첨부 버튼
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest
                .withAlpha(UIConstants.alpha20),
            borderRadius: BorderRadius.circular(UIConstants.radiusSm),
          ),
          child: IconButton(
            icon: const FaIcon(FontAwesomeIcons.file),
            iconSize: UIConstants.iconSm,
            onPressed: isSending ? null : () => _pickFile(context, ref),
            tooltip: '파일 첨부',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: UIConstants.iconLg + UIConstants.spacingSm,
              minHeight: UIConstants.iconLg + UIConstants.spacingSm,
            ),
          ),
        ),
        const SizedBox(width: UIConstants.spacingSm),
        // 프로젝트 폴더 지정 버튼
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest
                .withAlpha(UIConstants.alpha20),
            borderRadius: BorderRadius.circular(UIConstants.radiusSm),
          ),
          child: IconButton(
            icon: const FaIcon(FontAwesomeIcons.folderOpen),
            iconSize: UIConstants.iconSm,
            onPressed: () => _pickProjectFolder(context),
            tooltip: '프로젝트 폴더 지정',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: UIConstants.iconLg + UIConstants.spacingSm,
              minHeight: UIConstants.iconLg + UIConstants.spacingSm,
            ),
          ),
        ),
        const SizedBox(width: UIConstants.spacingSm),
        // GitHub 분석 버튼
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest
                .withAlpha(UIConstants.alpha20),
            borderRadius: BorderRadius.circular(UIConstants.radiusSm),
          ),
          child: IconButton(
            icon: const FaIcon(FontAwesomeIcons.github),
            iconSize: UIConstants.iconSm,
            onPressed: isSending
                ? null
                : () => _analyzeProject(context, ref, textController),
            tooltip: 'GitHub 분석',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: UIConstants.iconLg + UIConstants.spacingSm,
              minHeight: UIConstants.iconLg + UIConstants.spacingSm,
            ),
          ),
        ),
      ],
    );
  }
}
