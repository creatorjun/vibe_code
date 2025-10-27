// lib/presentation/screens/settings/widgets/delete_confirmation_dialog.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/ui_constants.dart';

Future<bool?> showDeleteConfirmationDialog(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(
        Icons.warning_rounded,
        color: colorScheme.error,
        size: UIConstants.iconLg * 1.5,
      ),
      title: const Text('모든 대화 삭제'),
      content: const Text(
        '정말로 모든 대화 내역을 삭제하시겠습니까?\n\n'
            '이 작업은 되돌릴 수 없습니다.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
          ),
          child: const Text('삭제'),
        ),
      ],
    ),
  );
}
