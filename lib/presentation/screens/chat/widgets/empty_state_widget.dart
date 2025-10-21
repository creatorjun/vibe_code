import 'package:flutter/material.dart';
import '../../../../core/constants/ui_constants.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(height: UIConstants.spacingLg),
          Text(
            '새 대화를 시작하세요',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: UIConstants.spacingSm),
          Text(
            '아래 입력란에 메시지를 입력하면\n자동으로 새 대화방이 생성됩니다',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
