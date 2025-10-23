// lib/presentation/screens/chat/widgets/chat_action_buttons.dart
import 'package:flutter/material.dart';

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
          onPressed: isSending ? null : onPickFile,
          tooltip: '파일 첨부',
        ),
        IconButton(
          icon: const Icon(Icons.code),
          onPressed: isSending ? null : onAnalyzeProject,
          tooltip: 'GitHub 프로젝트 분석',
        ),
      ],
    );
  }
}
