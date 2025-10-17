import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_code/common/constants/app_colors.dart';
import '../../models/message.dart';
import '../../common/constants/ui_constants.dart';
import '../../common/utils/ui_helpers.dart';
import '../../providers/chat_provider.dart';
import 'sticky_code_snippet.dart';

// 파싱된 콘텐츠 조각의 타입을 정의합니다.
enum _ContentType { text, code }
typedef _ContentSegment = ({
String content,
_ContentType type,
String language
});

/// 채팅 메시지 버블 위젯
///
/// 사용자 메시지와 AI 메시지를 Sliver 리스트로 변환하여 반환합니다.
/// AI 메시지의 경우, 텍스트와 코드 블록을 하나의 말풍선으로 통합하여 표시합니다.
class ChatBubble {
  final Message message;

  const ChatBubble({required this.message});

  /// 메시지 종류에 따라 Sliver 리스트를 빌드하여 반환합니다.
  List<Widget> buildSlivers(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isUser) {
      return [_buildUserMessageSliver(isDark)];
    } else {
      return _buildAssistantMessageSlivers(isDark);
    }
  }

  /// 사용자 메시지 Sliver를 빌드합니다. (3줄 초과 시 폴딩 기능 포함)
  Widget _buildUserMessageSliver(bool isDark) {
    return SliverToBoxAdapter(
      child: Align(
        alignment: Alignment.centerRight,
        child: _UserMessageBubble(
          message: message,
          isDark: isDark,
        ),
      ),
    );
  }

  /// AI 메시지 Sliver 리스트를 빌드합니다.
  List<Widget> _buildAssistantMessageSlivers(bool isDark) {
    final segments = _segmentContent(message.content);

    if (segments.isEmpty) {
      return [];
    }

    // 홀수 개의 백틱 경고 처리
    if (segments.any((s) => s.type == _ContentType.text && s.content.contains('__ODD_BACKTICK_WARNING__'))) {
      return [_buildOddBacktickWarningSliver(isDark)];
    }

    final slivers = <Widget>[];
    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final isFirst = i == 0;
      final isLast = i == segments.length - 1;

      if (segment.type == _ContentType.code) {
        slivers.add(
          StickyCodeSnippet(
            code: segment.content,
            language: segment.language,
            isFirstInSection: isFirst,
            isLastInSection: isLast,
          ),
        );
      } else {
        slivers.add(
          _buildTextSliver(
            segment.content,
            isDark,
            isFirstInSection: isFirst,
            isLastInSection: isLast,
          ),
        );
      }
    }
    return slivers;
  }

  /// 콘텐츠를 텍스트와 코드 조각으로 분할합니다.
  List<_ContentSegment> _segmentContent(String content) {
    final segments = <_ContentSegment>[];
    content = content.trim();

    final backtickPattern = RegExp(r'```');
        final matches = backtickPattern.allMatches(content).toList();

    // 백틱 개수가 홀수이면 경고와 함께 원본 텍스트 반환
    if (matches.length % 2 != 0) {
      return [
        (content: '${content}__ODD_BACKTICK_WARNING__', type: _ContentType.text, language: '')
      ];
    }

    int lastIndex = 0;

    for (int i = 0; i < matches.length; i += 2) {
      final startMatch = matches[i];
      final endMatch = matches[i + 1];

      // 코드 블록 이전 텍스트
      if (startMatch.start > lastIndex) {
        final text = content.substring(lastIndex, startMatch.start).trim();
        if (text.isNotEmpty) {
          segments.add((
          content: text,
          type: _ContentType.text,
          language: ''
          ));
        }
      }

      // 코드 블록
      final codeBlockFull = content.substring(startMatch.start, endMatch.end);
      final extracted = _extractCodeAndLanguage(codeBlockFull);
      if (extracted.code.isNotEmpty) {
        segments.add((
        content: extracted.code,
        type: _ContentType.code,
        language: extracted.language
        ));
      }
      lastIndex = endMatch.end;
    }

    // 마지막 텍스트
    if (lastIndex < content.length) {
      final text = content.substring(lastIndex).trim();
      if (text.isNotEmpty) {
        segments.add((
        content: text,
        type: _ContentType.text,
        language: ''
        ));
      }
    }

    return segments;
  }

  /// 코드와 언어를 추출합니다.
  ({String code, String language}) _extractCodeAndLanguage(String codeBlockFull) {
    final firstLineEnd = codeBlockFull.indexOf('\n');
    if (firstLineEnd == -1) return (code: '', language: 'code');

    final firstLine = codeBlockFull.substring(0, firstLineEnd);
    final languageMatch = RegExp(r'```(\w*)').firstMatch(firstLine);

    String language = 'code';
    if (languageMatch != null) {
      final captured = languageMatch.group(1);
      if (captured != null && captured.isNotEmpty) {
        language = captured;
      }
    }

    final code = codeBlockFull
        .substring(firstLineEnd + 1)
        .replaceAll(RegExp(r'```$'), '').trim();

    return (code: code, language: language);
    }

  /// 텍스트 조각을 위한 Sliver를 빌드합니다.
  Widget _buildTextSliver(String text, bool isDark,
      {required bool isFirstInSection, required bool isLastInSection}) {

    final Radius cornerRadius = Radius.circular(UIConstants.radiusXXLarge);

    return SliverToBoxAdapter(
      child: UIHelpers.buildFloatingGlass(
        isDark: isDark,
        alpha: UIConstants.glassAlphaMedium,
        borderRadius: 0,
        customBorderRadius: BorderRadius.vertical(
          top: isFirstInSection ? cornerRadius : Radius.zero,
          bottom: isLastInSection ? cornerRadius : Radius.zero,
        ),
        blurSigma: UIConstants.blurSigmaMedium,
        padding: const EdgeInsets.all(UIConstants.spacing16),
        margin: EdgeInsets.only(
          left: UIConstants.spacing16,
          right: UIConstants.spacing16,
          top: isFirstInSection ? UIConstants.spacing4 : 0,
          bottom: isLastInSection ? UIConstants.spacing4 : 0,
        ),
        child: Text(
          text,
          style: UIHelpers.getTextStyle(
            isDark: isDark,
            fontSize: UIConstants.fontNormal,
          ),
        ),
      ),
    );
  }

  /// 홀수 백틱 경고를 위한 Sliver 위젯을 빌드합니다.
  Widget _buildOddBacktickWarningSliver(bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(UIConstants.spacing12),
        margin: const EdgeInsets.symmetric(
          horizontal: UIConstants.spacing16,
          vertical: UIConstants.spacing4,
        ),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha(UIConstants.glassAlphaLow),
          borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
          border: Border.all(
            color: Colors.orange.withAlpha(UIConstants.glassAlphaVeryHigh),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
              size: UIConstants.iconMedium,
            ),
            const SizedBox(width: UIConstants.spacing8),
            Expanded(
              child: Text(
                '코드 블록이 올바르게 닫히지 않았습니다.',
                style: UIHelpers.getTextStyle(
                  isDark: isDark,
                  fontSize: UIConstants.fontSmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 유저 메시지 버블 위젯 (3줄 초과 시 폴딩 기능 포함)
class _UserMessageBubble extends ConsumerStatefulWidget {
  final Message message;
  final bool isDark;

  const _UserMessageBubble({
    required this.message,
    required this.isDark,
  });

  @override
  ConsumerState<_UserMessageBubble> createState() => _UserMessageBubbleState();
}

class _UserMessageBubbleState extends ConsumerState<_UserMessageBubble> {
  bool _needsFolding = false;

  @override
  Widget build(BuildContext context) {
    // Provider에서 확장 상태 가져오기
    final isExpanded = ref.watch(chatBubbleExpansionProvider.select(
          (state) => state[widget.message.id] ?? false,
    ));

    return LayoutBuilder(
      builder: (context, constraints) {
        // 텍스트 스타일 정의
        final textStyle = UIHelpers.getTextStyle(
          isDark: widget.isDark,
          fontSize: UIConstants.fontNormal,
        );

        // TextPainter로 실제 줄 수 계산
        final textPainter = TextPainter(
          text: TextSpan(text: widget.message.content, style: textStyle),
          maxLines: null,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth - UIConstants.chatBubbleMaxWidth - UIConstants.spacing16 * 3);

        final lineHeight = textStyle.fontSize! * (textStyle.height ?? 1.2);
        final totalLines = (textPainter.height / lineHeight).ceil();

        // 3줄 초과 여부 확인
        if (totalLines > 3 && !_needsFolding) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _needsFolding = true);
            }
          });
        }

        return GestureDetector(
          onTap: _needsFolding
              ? () {
            ref.read(chatBubbleExpansionProvider.notifier).toggleExpanded(widget.message.id);
          }
              : null,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(UIConstants.radiusXXLarge),
            ),
            margin: const EdgeInsets.only(
              left: UIConstants.chatBubbleMaxWidth,
              right: UIConstants.spacing16,
              top: UIConstants.spacing4,
              bottom: UIConstants.spacing4,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: UIConstants.spacing16,
              vertical: UIConstants.spacing12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.message.content,
                  style: textStyle,
                  maxLines: (_needsFolding && !isExpanded) ? 3 : null,
                  overflow: (_needsFolding && !isExpanded) ? TextOverflow.ellipsis : null,
                ),
                if (_needsFolding) ...[
                  const SizedBox(height: UIConstants.spacing6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: UIConstants.spacing8,
                          vertical: UIConstants.spacing3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(UIConstants.glassAlphaLow),
                          borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isExpanded ? '접기' : '더보기',
                              style: UIHelpers.getTextStyle(
                                isDark: widget.isDark,
                                fontSize: UIConstants.fontTiny,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: UIConstants.spacing3),
                            Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              size: UIConstants.iconSmall,
                              color: Colors.white.withAlpha(UIConstants.glassAlphaVeryHigh),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
