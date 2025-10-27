// lib/presentation/screens/chat/widgets/export_dialog.dart

import 'package:flutter/material.dart';
import 'package:vibe_code/core/theme/app_colors.dart';
import 'package:vibe_code/core/constants/ui_constants.dart';
import 'package:vibe_code/core/utils/markdown_exporter.dart';
import 'package:vibe_code/data/database/app_database.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class ExportDialog extends StatelessWidget {
  final ChatSession session;
  final List<Message> messages;

  const ExportDialog({
    super.key,
    required this.session,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.download, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('대화 내보내기'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이 대화를 마크다운 형식으로 내보낼 수 있습니다.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: UIConstants.spacingMd),
          _buildInfoCard(
            icon: Icons.message,
            label: '메시지 수',
            value: '${messages.length}개',
          ),
          const SizedBox(height: UIConstants.spacingXs),
          _buildInfoCard(
            icon: Icons.calendar_today,
            label: '생성일',
            value: session.createdAt.toString().split(' ')[0],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton.icon(
          onPressed: () => _copyToClipboard(context),
          icon: const Icon(Icons.copy),
          label: const Text('클립보드에 복사'),
        ),
        ElevatedButton.icon(
          onPressed: () => _saveAsFile(context),
          icon: const Icon(Icons.save),
          label: const Text('파일로 저장'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacingSm),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(UIConstants.alpha10),
        borderRadius: BorderRadius.circular(UIConstants.radiusSm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    final markdown = MarkdownExporter.exportSessionToMarkdown(
      session: session,
      messages: messages,
    );

    final success = await MarkdownExporter.copyToClipboard(markdown);

    if (context.mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '클립보드에 복사되었습니다 (${markdown.length} 자)'
                : '복사 실패',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? AppColors.primary : Colors.red,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _saveAsFile(BuildContext context) async {
    try {
      final markdown = MarkdownExporter.exportSessionToMarkdown(
        session: session,
        messages: messages,
      );

      final filename = MarkdownExporter.generateFilename(session.title);

      // 파일 저장 위치 선택
      final path = await FilePicker.platform.saveFile(
        dialogTitle: '마크다운 파일 저장',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['md'],
      );

      if (path != null) {
        final file = File(path);
        await file.writeAsString(markdown);

        if (context.mounted) {
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('파일 저장 완료: $filename'),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.primary,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
