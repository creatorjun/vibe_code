// lib/presentation/screens/chat/widgets/message_bubble.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:vibe_code/core/theme/app_colors.dart';
import 'package:vibe_code/core/utils/date_formatter.dart';
import 'package:vibe_code/core/utils/logger.dart';
import 'package:vibe_code/core/utils/markdown_parser.dart';
import 'package:vibe_code/data/database/app_database.dart';
import 'package:vibe_code/core/constants/ui_constants.dart';
import 'code_snippet_widget.dart';

/// 사용자 및 AI 메시지 버블
class MessageBubble {
  final Message message;

  const MessageBubble({required this.message});

  /// 메시지를 Sliver로 변환
  List<Widget> buildAsSliver(BuildContext context) {
    Logger.debug('[MessageBubble] Building message ${message.id}, role: ${message.role}');

    if (message.role == 'user') {
      return [SliverToBoxAdapter(child: UserMessageBubble(message: message))];
    } else {
      return _buildAiMessageSlivers(context);
    }
  }

  /// AI 메시지 Sliver 생성
  List<Widget> _buildAiMessageSlivers(BuildContext context) {
    Logger.debug('[MessageBubble] Building AI message ${message.id}');
    Logger.debug('[MessageBubble] Content length: ${message.content.length}');
    Logger.debug('[MessageBubble] Is streaming: ${message.isStreaming}');
    Logger.debug('[MessageBubble] Content preview: ${message.content.substring(0, message.content.length > 50 ? 50 : message.content.length)}...');

    // 최적화: Theme 정보를 한 번만 가져오기
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bubbleColor = isDark ? AppColors.aiBubbleDark : AppColors.aiBubbleLight;

    // ✅ 수정: 스트리밍 중이고 비어있을 때만 "생각 중"
    final isThinking = message.content.trim().isEmpty && message.isStreaming;
    Logger.debug('[MessageBubble] Is thinking: $isThinking');

    // ✅ 수정: isThinking일 때만 파싱 건너뛰기
    final parts = isThinking ? <dynamic>[] : MarkdownParser.parseMessage(message.content);
    Logger.debug('[MessageBubble] Parts count: ${parts.length}');

    if (parts.isNotEmpty) {
      Logger.debug('[MessageBubble] Parts types: ${parts.map((p) => p.runtimeType).toList()}');
    }

    return [
      // AI 메시지 버블
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
    Logger.debug('[AiMessageBubbleSliver] Building for message ${message.id}');

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
    Logger.debug('[AiMessageBubbleSliver] Building thinking indicator');

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
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
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
    Logger.debug('[AiMessageBubbleSliver] Building content slivers');
    Logger.debug('[AiMessageBubbleSliver] Message content empty: ${message.content.trim().isEmpty}');
    Logger.debug('[AiMessageBubbleSliver] Parts length: ${parts.length}');

    // ✅ 첫 번째 체크: 메시지가 비어있으면 빈 배열 반환
    if (message.content.trim().isEmpty) {
      Logger.debug('[AiMessageBubbleSliver] Message content is empty, returning empty list');
      return [];
    }

    // ✅ 두 번째 체크: parts가 비어있으면 원본 텍스트 표시
    if (parts.isEmpty) {
      Logger.debug('[AiMessageBubbleSliver] Parts is empty, showing raw content');

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

    // ✅ parts 처리
    Logger.debug('[AiMessageBubbleSliver] Processing ${parts.length} parts');
    final slivers = <Widget>[];

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      Logger.debug('[AiMessageBubbleSliver] Processing part $i: ${part.runtimeType}');

      if (part is TextPart) {
        Logger.debug('[AiMessageBubbleSliver] TextPart content length: ${part.content.length}');

        if (part.content.trim().isNotEmpty) {
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
        }
      } else if (part is CodePart) {
        Logger.debug('[AiMessageBubbleSliver] CodePart language: ${part.language}, code length: ${part.code.length}');

        if (part.code.trim().isNotEmpty) {
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
    }

    // ✅ 세 번째 체크: 처리된 slivers가 비어있으면 원본 텍스트 표시
    if (slivers.isEmpty) {
      Logger.debug('[AiMessageBubbleSliver] Slivers is empty after processing, showing raw content as fallback');

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

    Logger.debug('[AiMessageBubbleSliver] Returning ${slivers.length} slivers');
    return slivers;
  }
}

/// 사용자 메시지 버블
class UserMessageBubble extends StatefulWidget {
  final Message message;

  const UserMessageBubble({super.key, required this.message});

  @override
  State<UserMessageBubble> createState() => _UserMessageBubbleState();
}

class _UserMessageBubbleState extends State<UserMessageBubble> {
  bool isExpanded = false;
  bool needsExpansion = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.message.content,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      maxLines: 3,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: UIConstants.messageBubbleMaxWidth - 32);

    needsExpansion = textPainter.didExceedMaxLines;

    return RepaintBoundary(
      child: Align(
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: UIConstants.spacingMd,
                        vertical: UIConstants.spacingSm,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(UIConstants.alpha20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Creator Jun',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: widget.message.content),
                              );
                            },
                            borderRadius: BorderRadius.circular(UIConstants.radiusSm),
                            child: Padding(
                              padding: const EdgeInsets.all(UIConstants.spacingXs),
                              child: Icon(
                                Icons.copy_all,
                                size: UIConstants.iconSm,
                                color: Colors.white.withAlpha(UIConstants.alpha70),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: UIConstants.spacingMd,
                        vertical: UIConstants.spacingSm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            widget.message.content,
                            maxLines: isExpanded || !needsExpansion ? null : 3,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (needsExpansion) ...[
                            const SizedBox(height: UIConstants.spacingXs),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  isExpanded = !isExpanded;
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
                                      isExpanded ? '접기' : '더 보기',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withAlpha(UIConstants.alpha90),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      isExpanded
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
                  ],
                ),
              ),
              const SizedBox(height: UIConstants.spacingXs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacingXs),
                child: Text(
                  DateFormatter.formatMessageTime(widget.message.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withAlpha(UIConstants.alpha70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
