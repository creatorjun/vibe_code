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
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(UIConstants.messageBubblePadding),
              decoration: BoxDecoration(
                color: isUser
                    ? (isDark ? AppColors.userBubbleDark : AppColors.userBubbleLight)
                    : (isDark ? AppColors.aiBubbleDark : AppColors.aiBubbleLight),
                borderRadius: BorderRadius.circular(UIConstants.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.content.isEmpty ? '생각 중...' : message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : null,
                      fontStyle: message.content.isEmpty ? FontStyle.italic : null,
                    ),
                  ),
                  if (message.isStreaming)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isUser ? Colors.white : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '응답 생성 중...',
                            style: TextStyle(
                              fontSize: UIConstants.fontSizeSm,
                              color: isUser ? Colors.white70 : Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormatter.formatMessageTime(message.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (!isUser && !message.isStreaming) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _copyToClipboard(context, message.content),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.copy,
                          size: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('클립보드에 복사되었습니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
