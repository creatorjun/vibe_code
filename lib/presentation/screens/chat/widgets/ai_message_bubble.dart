// lib/presentation/screens/chat/widgets/ai_message_bubble.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibe_code/core/theme/app_colors.dart';
import 'package:vibe_code/core/utils/date_formatter.dart';
import 'package:vibe_code/core/utils/logger.dart';
import 'package:vibe_code/core/utils/markdown_parser.dart';
import 'package:vibe_code/data/database/app_database.dart';
import 'package:vibe_code/core/constants/ui_constants.dart';
import 'code_snippet_widget.dart';

/// AI 메시지 버블
class AiMessageBubble {
  final Message message;

  const AiMessageBubble({required this.message});

  /// AI 메시지 Sliver 생성
  List<Widget> buildAsSliver(BuildContext context) {
    Logger.debug('[AiMessageBubble] Building AI message ${message.id}');
    Logger.debug('[AiMessageBubble] Content length: ${message.content.length}');
    Logger.debug('[AiMessageBubble] Is streaming: ${message.isStreaming}');

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bubbleColor = isDark ? AppColors.aiBubbleDark : AppColors.aiBubbleLight;

    final isThinking = message.content.trim().isEmpty && message.isStreaming;
    final parts = isThinking ? <dynamic>[] : MarkdownParser.parseMessage(message.content);

    return [
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
          theme: theme,
          isThinking: isThinking,
        ),
      ),
      SliverToBoxAdapter(child: _buildTimestamp(context, theme)),
    ];
  }

  Widget _buildTimestamp(BuildContext context, ThemeData theme) {
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
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.textTheme.bodySmall?.color?.withAlpha(UIConstants.alpha70),
        ),
      ),
    );
  }
}

/// AI 메시지 버블 Sliver
class _AiMessageBubbleSliver extends StatelessWidget {
  final Color bubbleColor;
  final bool isDark;
  final List<dynamic> parts;
  final Message message;
  final ThemeData theme;
  final bool isThinking;

  const _AiMessageBubbleSliver({
    required this.bubbleColor,
    required this.isDark,
    required this.parts,
    required this.message,
    required this.theme,
    required this.isThinking,
  });

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        // AI 헤더
        SliverToBoxAdapter(
          child: RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(UIConstants.radiusLg),
                  topRight: Radius.circular(UIConstants.radiusLg),
                ),
              ),
              child: _buildAiHeader(context),
            ),
          ),
        ),
        // 콘텐츠
        ...isThinking ? _buildThinkingSlivers(context) : _buildContentSlivers(context),
        // 하단
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

  List<Widget> _buildThinkingSlivers(BuildContext context) {
    return [
      SliverToBoxAdapter(
        child: Container(
          width: double.infinity,
          color: bubbleColor,
          padding: const EdgeInsets.all(UIConstants.spacingLg),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              const SizedBox(width: UIConstants.spacingMd),
              Text(
                '생각 중...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? Colors.white.withAlpha(UIConstants.alpha70)
                      : Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildAiHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacingMd,
        vertical: UIConstants.spacingSm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.android_outlined,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Vibe Code',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          if (!isThinking)
            InkWell(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: message.content));

                // ✅ 스낵바 표시
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('클립보드에 복사되었습니다'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.primary,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
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
    if (message.content.trim().isEmpty) {
      return [];
    }

    if (parts.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            color: bubbleColor,
            padding: const EdgeInsets.symmetric(
              horizontal: UIConstants.spacingMd,
              vertical: UIConstants.spacingSm,
            ),
            child: SelectableText(
              message.content,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.white : Colors.black87,
                height: 1.6,
              ),
            ),
          ),
        ),
      ];
    }

    final slivers = <Widget>[];

    for (final part in parts) {
      if (part is TextPart && part.content.trim().isNotEmpty) {
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
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.6,
                ),
              ),
            ),
          ),
        );
      } else if (part is CodePart && part.code.trim().isNotEmpty) {
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

    if (slivers.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            color: bubbleColor,
            padding: const EdgeInsets.symmetric(
              horizontal: UIConstants.spacingMd,
              vertical: UIConstants.spacingSm,
            ),
            child: SelectableText(
              message.content,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.white : Colors.black87,
                height: 1.6,
              ),
            ),
          ),
        ),
      ];
    }

    return slivers;
  }
}
