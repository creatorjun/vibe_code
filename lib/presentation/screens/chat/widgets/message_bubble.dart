import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/database/app_database.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ AI 답변일 때 최대 크기 버블로 가운데 정렬
    if (!isUser) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(
          horizontal: UIConstants.spacingMd,
          vertical: UIConstants.spacingSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity, // 최대 너비 사용
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.spacingMd,
                vertical: UIConstants.spacingSm,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.aiBubbleDark
                    : AppColors.aiBubbleLight,
                borderRadius: BorderRadius.circular(UIConstants.radiusLg),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded( // Flexible 대신 Expanded로 전체 너비 사용
                    child: SelectableText(
                      message.content,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: UIConstants.spacingSm),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: message.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('클립보드에 복사되었습니다'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(UIConstants.radiusSm),
                    child: Padding(
                      padding: const EdgeInsets.all(UIConstants.spacingXs),
                      child: Icon(
                        Icons.copy,
                        size: UIConstants.iconSm,
                        color: isDark
                            ? Colors.white.withAlpha(UIConstants.alpha70)
                            : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: UIConstants.spacingXs),
            Text(
              DateFormatter.formatMessageTime(message.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withAlpha(UIConstants.alpha70),
              ),
            ),
          ],
        ),
      );
    }

    // ✅ 사용자 메시지는 기존대로 우측 정렬
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: UIConstants.spacingMd,
          vertical: UIConstants.spacingSm,
        ),
        constraints: const BoxConstraints(
          maxWidth: UIConstants.messageBubbleMaxWidth,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.spacingMd,
                vertical: UIConstants.spacingSm,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.userBubbleDark
                    : AppColors.userBubbleLight,
                borderRadius: BorderRadius.circular(UIConstants.radiusLg),
              ),
              child: SelectableText(
                message.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: UIConstants.spacingXs),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.spacingXs,
              ),
              child: Text(
                DateFormatter.formatMessageTime(message.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withAlpha(UIConstants.alpha70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
