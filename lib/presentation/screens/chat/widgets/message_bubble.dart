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

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return isUser ? _buildUserMessage(context) : Container();
  }

  // Sliver 버전
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
    final bubbleColor =
    isDark ? AppColors.aiBubbleDark : AppColors.aiBubbleLight;

    // 복사 버튼이 있는 상단
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
                      content: Text('복사되었습니다'),
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

    // 본문 파트들 - 여백 0으로 완전 통합
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];

      if (part is TextPart) {
        // 텍스트 파트 - 버블 배경 유지, 여백 0
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
        // 코드 블록 - 여백 0, 라운딩 없음 (완전 통합)
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: UIConstants.spacingMd,
            ),
            sliver: CodeSnippetSliver(
              code: part.code,
              language: part.language,
              backgroundColor: bubbleColor,
              isIntegrated: true, // ✅ 통합 모드 활성화
            ),
          ),
        );
      }
    }

    // 하단 라운딩
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
    return _UserMessageBubble(message: message);
  }
}

// 새로운 사용자 메시지 버블 위젯
class _UserMessageBubble extends StatefulWidget {
  final Message message;

  const _UserMessageBubble({
    required this.message,
  });

  @override
  State<_UserMessageBubble> createState() => _UserMessageBubbleState();
}

class _UserMessageBubbleState extends State<_UserMessageBubble> {
  bool _isExpanded = false;
  bool _needsExpansion = false;

  @override
  Widget build(BuildContext context) {
    // 3줄 이상인지 체크
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.message.content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      maxLines: 3,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: UIConstants.messageBubbleMaxWidth - 32);

    _needsExpansion = textPainter.didExceedMaxLines;

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
            // 메시지 버블
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.spacingMd,
                vertical: UIConstants.spacingSm,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                borderRadius: BorderRadius.circular(UIConstants.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gradientStart.withAlpha(UIConstants.alpha30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 메시지 텍스트
                  SelectableText(
                    widget.message.content,
                    maxLines: _isExpanded || !_needsExpansion ? null : 3,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // 확장/축소 버튼
                  if (_needsExpansion) ...[
                    const SizedBox(height: UIConstants.spacingXs),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(UIConstants.radiusSm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: UIConstants.spacingXs,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isExpanded ? '접기' : '더보기',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withAlpha(UIConstants.alpha90),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: UIConstants.iconSm,
                              color: Colors.white.withAlpha(UIConstants.alpha90),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 타임스탬프
            const SizedBox(height: UIConstants.spacingXs),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.spacingXs,
              ),
              child: Text(
                DateFormatter.formatMessageTime(widget.message.createdAt),
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
