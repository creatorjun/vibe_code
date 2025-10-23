// lib/presentation/screens/chat/widgets/chat_text_field.dart
import 'package:flutter/material.dart';

import '../../../../../core/constants/ui_constants.dart';

class ChatTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final bool canSend;
  final VoidCallback onSend;
  final ValueChanged<String>? onChanged;

  const ChatTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.canSend,
    required this.onSend,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 40,
        maxHeight: 200,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(UIConstants.radiusMd),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(UIConstants.alpha30),
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: true,
        maxLines: null,
        enabled: !isSending,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(
          hintText: '메시지를 입력하세요...',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: UIConstants.spacingMd,
            vertical: UIConstants.spacingSm,
          ),
        ),
        style: Theme.of(context).textTheme.bodyLarge,
        onChanged: onChanged,
        onSubmitted: (value) {
          if (canSend && !isSending) {
            onSend();
          }
        },
      ),
    );
  }
}
