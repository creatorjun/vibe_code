// lib/presentation/screens/chat/widgets/message_bubble.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/markdown_parser.dart';
import '../../../../data/database/app_database.dart';
import 'code_snippet_widget.dart';

/// 메시지 버블 (User/AI 모두 처리)
class MessageBubble {
  final Message message;

  const MessageBubble({required this.message});

  /// Sliver 리스트로 변환
  List<Widget> buildAsSliver(BuildContext context) {
    if (message.role == 'user') {
      return [
        SliverToBoxAdapter(
          child: _UserMessageBubble(message: message),
        ),
      ];
    } else {
      return _buildAiMessageSlivers(context);
    }
  }

  /// AI 메시지를 여러 Sliver로 분리
  List<Widget> _buildAiMessageSlivers(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor =
    isDark ? AppColors.aiBubbleDark : AppColors.aiBubbleLight;

    final parts = MarkdownParser.parseMessage(message.content);

    return [
      // ✅ 전체 AI 메시지를 감싸는 SliverPadding
      SliverPadding(
        padding: const EdgeInsets.only(
          left: UIConstants.spacingMd,
          right: UIConstants.spacingMd,
          top: UIConstants.spacingSm,
        ),
        sliver: _AiMessageBubbleSliver(
          bubbleColor: bubbleColor,
          isDark: isDark,
          parts: parts,
          message: message,
        ),
      ),

      // 타임스탬프
      SliverToBoxAdapter(
        child: _buildTimestamp(context),
      ),
    ];
  }

  Widget _buildTimestamp(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        left: UIConstants.spacingMd,
        right: UIConstants.spacingMd,
        bottom: UIConstants.spacingSm,
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: UIConstants.spacingXs),
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
    );
  }
}

/// AI 메시지 버블 Sliver (배경색 통일)
class _AiMessageBubbleSliver extends StatelessWidget {
  final Color bubbleColor;
  final bool isDark;
  final List<dynamic> parts;
  final Message message;

  const _AiMessageBubbleSliver({
    required this.bubbleColor,
    required this.isDark,
    required this.parts,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        // AI 헤더
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: bubbleColor,
              border: Border(),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(UIConstants.radiusLg),
                topRight: Radius.circular(UIConstants.radiusLg),
              ),
            ),
            child: _buildAiHeader(context),
          ),
        ),

        // 컨텐츠 (텍스트 + 코드)
        ..._buildContentSlivers(context),

        // 하단 여백
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(UIConstants.radiusLg),
                bottomRight: Radius.circular(UIConstants.radiusLg),
              ),
            ),
            height: UIConstants.spacingSm,
            width: double.infinity,
          ),
        ),
      ],
    );
  }

  Widget _buildAiHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacingMd,
        vertical: UIConstants.spacingSm,
      ),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(UIConstants.radiusLg),
          topRight: Radius.circular(UIConstants.radiusLg),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text(
            'AI Assistant',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: message.content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('전체 내용이 복사되었습니다'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            borderRadius: BorderRadius.circular(UIConstants.radiusSm),
            child: Padding(
              padding: const EdgeInsets.all(UIConstants.spacingXs),
              child: Icon(
                Icons.copy_all,
                size: UIConstants.iconSm,
                color: isDark
                    ? Colors.white.withAlpha(UIConstants.alpha70)
                    : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContentSlivers(BuildContext context) {
    final slivers = <Widget>[];

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];

      if (part is TextPart) {
        slivers.add(
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              color: bubbleColor,
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.spacingMd,
                vertical: UIConstants.spacingSm,
              ),
              child: SelectableText(
                part.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.6,
                ),
              ),
            ),
          ),
        );
      } else if (part is CodePart) {
        slivers.addAll(
          CodeSnippetSliver(
            code: part.code,
            language: part.language,
            backgroundColor: bubbleColor,
            isIntegrated: true,
          ).buildAsSliverWithBackground(context),
        );
      }
    }

    return slivers;
  }
}

/// 사용자 메시지 버블
class _UserMessageBubble extends StatefulWidget {
  final Message message;

  const _UserMessageBubble({required this.message});

  @override
  State<_UserMessageBubble> createState() => _UserMessageBubbleState();
}

class _UserMessageBubbleState extends State<_UserMessageBubble> {
  bool _isExpanded = false;
  bool _needsExpansion = false;

  @override
  Widget build(BuildContext context) {
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
                    color: AppColors.gradientStart.withAlpha(
                      UIConstants.alpha30,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    widget.message.content,
                    maxLines: _isExpanded || !_needsExpansion ? null : 3,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                color: Colors.white.withAlpha(
                                  UIConstants.alpha90,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: UIConstants.iconSm,
                              color: Colors.white.withAlpha(
                                UIConstants.alpha90,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
