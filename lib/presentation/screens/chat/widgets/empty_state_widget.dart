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
            size: UIConstants.iconLg * 2.5, // 80px
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(height: UIConstants.spacingLg),
          Text(
            '새로운 대화 시작',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: UIConstants.spacingSm),
          Text(
            '메시지를 입력해 대화를 시작하세요',
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
