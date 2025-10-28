import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/ui_constants.dart';

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
      child: Focus(
        onKeyEvent: (FocusNode node, KeyEvent event) {
          // Enter (down)
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter) {
            // Shift (X)
            if (!HardwareKeyboard.instance.isShiftPressed) {
              if (canSend && !isSending) {
                onSend();
              }
              return KeyEventResult.handled;
            }
            // Shift+Enter (O)
            return KeyEventResult.ignored;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          maxLines: null,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            hintText: '메시지를 입력하세요...',
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            hoverColor: Colors.transparent,
            filled: false,
            contentPadding: EdgeInsets.symmetric(
              horizontal: UIConstants.spacingMd,
              vertical: UIConstants.spacingSm,
            ),
          ),
          style: Theme.of(context).textTheme.bodyLarge,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
