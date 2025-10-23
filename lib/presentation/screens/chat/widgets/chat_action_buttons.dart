// lib/presentation/screens/chat/widgets/chat_action_buttons.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/ui_constants.dart';

class ChatActionButtons extends StatelessWidget {
  final bool isSending;
  final VoidCallback onPickFile;
  final VoidCallback onAnalyzeProject;

  const ChatActionButtons({
    super.key,
    required this.isSending,
    required this.onPickFile,
    required this.onAnalyzeProject,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.attach_file),
          iconSize: UIConstants.iconMd,
          onPressed: isSending ? null : onPickFile,
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
          onPressed: isSending ? null : onAnalyzeProject,
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
