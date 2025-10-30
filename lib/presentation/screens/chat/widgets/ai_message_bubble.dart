import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibe_code/core/theme/app_colors.dart';
import 'package:vibe_code/core/utils/date_formatter.dart';
import 'package:vibe_code/core/utils/logger.dart';
import 'package:vibe_code/core/utils/markdown_parser.dart';
import 'package:vibe_code/data/database/app_database.dart';
import 'package:vibe_code/core/constants/ui_constants.dart';
import 'package:vibe_code/presentation/shared/widgets/loading_indicator.dart';
import 'code_snippet_widget.dart';
import 'markdown_text_widget.dart';

class AiMessageBubble {
  final Message message;

  const AiMessageBubble({required this.message});

  List<Widget> buildAsSliver(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bubbleColor = isDark
        ? AppColors.aiBubbleDark
        : AppColors.aiBubbleLight;
    final isThinking = message.content.trim().isEmpty && message.isStreaming;
    final parts = isThinking
        ? <dynamic>[]
        : MarkdownParser.parseMessage(message.content);

    Logger.warning('[AiMessageBubble] Building AI message: ${message.id}');
    Logger.warning(
      '[AiMessageBubble] Content length: ${message.content.length}',
    );
    Logger.warning('[AiMessageBubble] Is streaming: ${message.isStreaming}');
    Logger.warning(
      '[AiMessageBubble] Raw content:\n${'=' * 60}\n${message.content}\n${'=' * 60}',
    );
    if (!isThinking) {
      Logger.warning('[AiMessageBubble] Parsed ${parts.length} parts:');
      for (int i = 0; i < parts.length; i++) {
        if (parts[i] is TextPart) {
          final textPart = parts[i] as TextPart;
          Logger.warning('  [$i] TextPart (${textPart.content.length} chars):');
          Logger.warning(
            '    Content: ${textPart.content.substring(0, textPart.content.length > 100 ? 100 : textPart.content.length)}${textPart.content.length > 100 ? "..." : ""}',
          );
        } else if (parts[i] is CodePart) {
          final codePart = parts[i] as CodePart;
          Logger.warning(
            '  [$i] CodePart (language: ${codePart.language}, ${codePart.code.length} chars):',
          );
          Logger.warning(
            '    Code:\n${'-' * 40}\n${codePart.code}\n${'-' * 40}',
          );
        }
      }
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.only(
          left: UIConstants.spacingMd,
          right: UIConstants.spacingMd,
          top: UIConstants.spacingSm,
        ),
        sliver: AiMessageBubbleSliver(
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
          color: theme.textTheme.bodySmall?.color?.withAlpha(
            UIConstants.alpha70,
          ),
        ),
      ),
    );
  }
}

class AiMessageBubbleSliver extends StatelessWidget {
  final Color bubbleColor;
  final bool isDark;
  final List<dynamic> parts;
  final Message message;
  final ThemeData theme;
  final bool isThinking;

  const AiMessageBubbleSliver({
    super.key,
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
        ...(isThinking
            ? _buildThinkingSlivers(context)
            : _buildContentSlivers(context)),
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
              const LoadingIndicator(size: 20, useGradient: true),
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
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('복사되었습니다'),
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
    if (message.content.trim().isEmpty) return <Widget>[];

    if (parts.isEmpty) {
      return <Widget>[
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            color: bubbleColor,
            padding: const EdgeInsets.symmetric(
              horizontal: UIConstants.spacingMd,
              vertical: UIConstants.spacingSm,
            ),
            child: MarkdownTextWidget(
              // ⭐ 변경
              data: message.content,
              baseStyle: theme.textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.white : Colors.black87,
                height: 1.6,
              ),
              textColor: isDark ? Colors.white : Colors.black87,
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
              child: MarkdownTextWidget(
                // ⭐ 변경
                data: part.content,
                baseStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.6,
                ),
                textColor: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
      } else if (part is CodePart && part.code.trim().isNotEmpty) {
        slivers.addAll(
          CodeSnippetSliver(
            code: part.code,
            language: part.language,
          ).buildAsSliverWithBackground(context),
        );
      }
    }

    if (slivers.isEmpty) {
      return <Widget>[
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            color: bubbleColor,
            padding: const EdgeInsets.symmetric(
              horizontal: UIConstants.spacingMd,
              vertical: UIConstants.spacingSm,
            ),
            child: MarkdownTextWidget(
              // ⭐ 변경
              data: message.content,
              baseStyle: theme.textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.white : Colors.black87,
                height: 1.6,
              ),
              textColor: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ];
    }
    return slivers;
  }
}
