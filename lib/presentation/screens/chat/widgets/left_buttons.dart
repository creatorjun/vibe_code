// lib/presentation/screens/chat/widgets/left_buttons.dart

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
import 'package:vibe_code/domain/providers/project_folder_provider.dart';

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

  // ✅ 프로젝트 폴더 선택 및 저장
  Future<void> _pickProjectFolder(BuildContext context, WidgetRef ref) async {
    try {
      final folderPath = await FilePicker.platform.getDirectoryPath();
      if (folderPath == null) return; // 사용자가 취소한 경우

      Logger.info('Selected project folder: $folderPath');

      // ✅ ProjectFolderNotifier에 저장
      ref.read(projectFolderProvider.notifier).setFolder(folderPath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로젝트 폴더가 지정되었습니다\n$folderPath'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      Logger.error('Failed to select project folder', e);
      if (context.mounted) {
        await ErrorDialog.show(
          context: context,
          title: '폴더 선택 실패',
          message: '폴더 선택 중 오류가 발생했습니다:\n${e.toString()}',
        );
      }
    } finally {
      onRequestFocus();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 프로젝트 폴더 상태 감시
    final projectFolder = ref.watch(projectFolderProvider);
    final hasProjectFolder = projectFolder.hasFolder;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 파일 첨부 버튼
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.paperclip),
          iconSize: UIConstants.iconSm,
          onPressed: isSending ? null : () => _pickFile(context, ref),
          tooltip: '파일 첨부',
        ),
        const SizedBox(width: UIConstants.spacingXs),

        // GitHub 분석 버튼
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.github),
          iconSize: UIConstants.iconSm,
          onPressed: isSending
              ? null
              : () => _analyzeProject(context, ref, textController),
          tooltip: 'GitHub 분석',
        ),
        const SizedBox(width: UIConstants.spacingXs),

        // ✅ 프로젝트 폴더 선택 버튼 (상태에 따라 색상 변경)
        IconButton(
          icon: FaIcon(
            FontAwesomeIcons.folder,
            color: hasProjectFolder
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          iconSize: UIConstants.iconSm,
          onPressed: isSending ? null : () => _pickProjectFolder(context, ref),
          tooltip: hasProjectFolder
              ? '프로젝트 폴더: ${projectFolder.folderPath}\n(클릭하여 변경)'
              : '프로젝트 폴더 지정',
        ),
      ],
    );
  }
}
