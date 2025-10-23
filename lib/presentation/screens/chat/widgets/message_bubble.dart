import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/database/app_database.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: UIConstants.spacingMd,
          vertical: UIConstants.spacingSm,
        ),
        constraints: const BoxConstraints(
          maxWidth: UIConstants.messageBubbleMaxWidth,
        ),
        child: Column(
          crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(UIConstants.spacingMd),
              decoration: BoxDecoration(
                color: isUser
                    ? (isDark
                    ? AppColors.userBubbleDark
                    : AppColors.userBubbleLight)
                    : (isDark
                    ? AppColors.aiBubbleDark
                    : AppColors.aiBubbleLight),
                borderRadius: BorderRadius.circular(UIConstants.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 메시지 내용
                  SelectableText(
                    message.content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isUser
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),

                  // 시간 표시
                  const SizedBox(height: UIConstants.spacingSm),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormatter.formatMessageTime(message.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isUser
                              ? Colors.white.withAlpha(UIConstants.alpha70)
                              : Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color,
                        ),
                      ),
                      if (!isUser) ...[
                        const SizedBox(width: UIConstants.spacingSm),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: message.content));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('클립보드에 복사되었습니다'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.copy,
                            size: UIConstants.iconSm,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
