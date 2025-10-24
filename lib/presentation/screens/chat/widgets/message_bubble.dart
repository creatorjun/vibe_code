import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/database/app_database.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/markdown_parser.dart';
import 'code_snippet_widget.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return isUser ? _buildUserMessage(context) : Container();
  }

  /// AI 메시지를 Sliver 리스트로 렌더링
  List<Widget> buildAsSliver(BuildContext context) {
    final isUser = message.role == 'user';

    if (!isUser) {
      return _buildAiMessageSlivers(context);
    } else {
      return [
        SliverToBoxAdapter(
          child: _buildUserMessage(context),
        ),
      ];
    }
  }

  List<Widget> _buildAiMessageSlivers(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parts = MarkdownParser.parseMessage(message.content);
    final slivers = <Widget>[];

    final bubbleColor = isDark ? AppColors.aiBubbleDark : AppColors.aiBubbleLight;

    // 버블 상단 (복사 버튼 포함)
    slivers.add(
      SliverToBoxAdapter(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(
            left: UIConstants.spacingMd,
            right: UIConstants.spacingMd,
            top: UIConstants.spacingSm,
          ),
          padding: const EdgeInsets.only(
            left: UIConstants.spacingMd,
            right: UIConstants.spacingMd,
            top: UIConstants.spacingSm,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(UIConstants.radiusLg),
              topRight: Radius.circular(UIConstants.radiusLg),
            ),
          ),
          child: Row(
            children: [
              const Spacer(),
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
      ),
    );

    // 메시지 파트별 렌더링
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];

      if (part is TextPart) {
        // 텍스트 파트 - 버블 배경 유지
        slivers.add(
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(
                horizontal: UIConstants.spacingMd,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.spacingMd,
                vertical: UIConstants.spacingSm,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
              ),
              child: SelectableText(
                part.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        );
      } else if (part is CodePart) {
        // 코드 블록 - 여백 0으로 시각적으로 통합
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: UIConstants.spacingMd,
            ),
            sliver: CodeSnippetSliver(
              code: part.code,
              language: part.language,
              backgroundColor: bubbleColor, // 버블 색상 전달
            ),
          ),
        );
      }
    }

    // 버블 하단 닫기
    slivers.add(
      SliverToBoxAdapter(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(
            horizontal: UIConstants.spacingMd,
          ),
          padding: const EdgeInsets.only(
            bottom: UIConstants.spacingSm,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(UIConstants.radiusLg),
              bottomRight: Radius.circular(UIConstants.radiusLg),
            ),
          ),
        ),
      ),
    );

    // 타임스탬프
    slivers.add(
      SliverToBoxAdapter(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(
            left: UIConstants.spacingMd,
            right: UIConstants.spacingMd,
            bottom: UIConstants.spacingSm,
          ),
          alignment: Alignment.center,
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
      ),
    );

    return slivers;
  }

  Widget _buildUserMessage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
