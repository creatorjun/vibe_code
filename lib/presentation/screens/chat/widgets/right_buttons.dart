// lib/presentation/screens/chat/widgets/right_buttons.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/ui_constants.dart';
import 'pipeline_depth_selector.dart';
import 'preset_selector.dart';

class RightButtons extends ConsumerWidget {
  final bool isSending;
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback onCancel;

  const RightButtons({
    super.key,
    required this.isSending,
    required this.canSend,
    required this.onSend,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 파이프라인 깊이 선택기
        IntrinsicWidth(
          child: PipelineDepthSelector(),
        ),
        const SizedBox(width: UIConstants.spacingMd),
        // 프리셋 선택기
        IntrinsicWidth(
          child: PresetSelector(),
        ),
        const SizedBox(width: UIConstants.spacingMd),
        // 전송/취소 버튼
        _buildSendButton(context),
      ],
    );
  }

  Widget _buildSendButton(BuildContext context) {
    if (isSending) {
      return IconButton(
        icon: const Icon(Icons.stop_circle),
        onPressed: onCancel,
        tooltip: '전송 취소',
        color: Theme.of(context).colorScheme.error,
      );
    }

    return IconButton(
      icon: const Icon(Icons.send),
      onPressed: canSend && !isSending ? onSend : null,
      tooltip: '전송',
      color: canSend ? Theme.of(context).colorScheme.primary : null,
    );
  }
}
