import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../common/constants/ui_constants.dart';
import '../../common/utils/ui_helpers.dart';
import 'sticky_code_snippet.dart';

/// 파싱된 콘텐츠를 담는 데이터 클래스
class ParsedContent {
  final List<Widget> normalWidgets;
  final List<Widget> sliverWidgets;

  ParsedContent({required this.normalWidgets, required this.sliverWidgets});
}

/// 채팅 메시지 버블 위젯
///
/// 사용자 메시지와 AI 메시지를 다르게 표시하며,
/// 마크다운 형식의 코드 블록을 파싱하여 StickyCodeSnippet으로 렌더링합니다.
class ChatBubble extends StatelessWidget {
  final Message message;

  const ChatBubble({super.key, required this.message});

  /// 콘텐츠 파싱 - 메인 진입점
  ParsedContent _parseContent(String content, bool isDark) {
    final normalWidgets = <Widget>[];
    final sliverWidgets = <Widget>[];

    // 앞뒤 공백 제거
    content = content.trim();

    // 모든 백틱 2개의 위치 찾기
    final backtickPattern = RegExp(r'```');
    final allBackticks = <int>[];
    for (final match in backtickPattern.allMatches(content)) {
      allBackticks.add(match.start);
    }

    // 백틱이 2개 미만이면 코드 블록 없음
    if (allBackticks.length < 2) {
      normalWidgets.add(_buildTextWidget(content, isDark));
      return ParsedContent(
        normalWidgets: normalWidgets,
        sliverWidgets: sliverWidgets,
      );
    }

    // 홀수 개 백틱 경고
    if (allBackticks.length % 2 != 0) {
      normalWidgets.add(_buildOddBacktickWarning(isDark));
      normalWidgets.add(_buildTextWidget(content, isDark));
      return ParsedContent(
        normalWidgets: normalWidgets,
        sliverWidgets: sliverWidgets,
      );
    }

    // 첫 번째 코드 블록의 언어 확인
    final isMarkdownMode = _isMarkdownMode(content, allBackticks[0]);

    if (isMarkdownMode) {
      // Markdown 모드: 맨 처음-맨 마지막만 쌍으로
      return _parseMarkdownMode(
        content,
        allBackticks,
        isDark,
        normalWidgets,
        sliverWidgets,
      );
    } else {
      // 일반 모드: 순차적 쌍으로 (1-2, 3-4, 5-6...)
      return _parseNormalMode(
        content,
        allBackticks,
        isDark,
        normalWidgets,
        sliverWidgets,
      );
    }
  }

  /// Markdown 모드 체크
  bool _isMarkdownMode(String content, int firstBacktickPos) {
    final firstLineEnd = content.indexOf('\n', firstBacktickPos);
    final firstLine = firstLineEnd != -1
        ? content.substring(firstBacktickPos, firstLineEnd)
        : content.substring(
      firstBacktickPos,
      firstBacktickPos + 20 < content.length
          ? firstBacktickPos + 20
          : content.length,
    );

    return firstLine.toLowerCase().contains('```markdown');
  }

  /// Markdown 모드 파싱: 맨 처음-맨 마지막 쌍
  ParsedContent _parseMarkdownMode(
      String content,
      List<int> allBackticks,
      bool isDark,
      List<Widget> normalWidgets,
      List<Widget> sliverWidgets,
      ) {
    final startPos = allBackticks.first;
    final endPos = allBackticks.last;

    // 코드 블록 이전 텍스트
    if (startPos > 0) {
      final text = content.substring(0, startPos).trim();
      if (text.isNotEmpty) {
        normalWidgets.add(_buildTextWidget(text, isDark, bottomPadding: true));
      }
    }

    // 코드 블록 추출
    final codeBlockFull = content.substring(startPos, endPos + 2);
    final extracted = _extractCodeAndLanguage(codeBlockFull);

    if (extracted.code.isNotEmpty) {
      sliverWidgets.add(
        StickyCodeSnippet(code: extracted.code, language: extracted.language),
      );
      normalWidgets.add(const SizedBox(height: UIConstants.spacing12));
    }

    // 코드 블록 이후 텍스트
    if (endPos + 2 < content.length) {
      final text = content.substring(endPos + 2).trim();
      if (text.isNotEmpty) {
        normalWidgets.add(_buildTextWidget(text, isDark));
      }
    }

    return ParsedContent(
      normalWidgets: normalWidgets,
      sliverWidgets: sliverWidgets,
    );
  }

  /// 일반 모드 파싱: 순차적 쌍 (1-2, 3-4, 5-6...)
  ParsedContent _parseNormalMode(
      String content,
      List<int> allBackticks,
      bool isDark,
      List<Widget> normalWidgets,
      List<Widget> sliverWidgets,
      ) {
    int lastIndex = 0;

    // 백틱을 2개씩 쌍으로 묶기
    for (int i = 0; i < allBackticks.length - 1; i += 2) {
      final startPos = allBackticks[i];
      final endPos = allBackticks[i + 1];

      // 코드 블록 이전 텍스트
      if (startPos > lastIndex) {
        final text = content.substring(lastIndex, startPos).trim();
        if (text.isNotEmpty) {
          normalWidgets.add(
            _buildTextWidget(text, isDark, bottomPadding: true),
          );
        }
      }

      // 코드 블록 추출
      final codeBlockFull = content.substring(startPos, endPos + 2);
      final extracted = _extractCodeAndLanguage(codeBlockFull);

      if (extracted.code.isNotEmpty) {
        sliverWidgets.add(
          StickyCodeSnippet(code: extracted.code, language: extracted.language),
        );
        normalWidgets.add(const SizedBox(height: UIConstants.spacing12));
      }

      lastIndex = endPos + 2;
    }

    // 마지막 텍스트
    if (lastIndex < content.length) {
      final text = content.substring(lastIndex).trim();
      if (text.isNotEmpty) {
        normalWidgets.add(_buildTextWidget(text, isDark));
      }
    }

    // 콘텐츠가 비어있으면 원본 표시
    if (normalWidgets.isEmpty && sliverWidgets.isEmpty) {
      normalWidgets.add(_buildTextWidget(content, isDark));
    }

    return ParsedContent(
      normalWidgets: normalWidgets,
      sliverWidgets: sliverWidgets,
    );
  }

  ({String code, String language}) _extractCodeAndLanguage(String codeBlockFull) {
    String language = 'code';
    String code = '';

    // 2개 백틱으로 감싼 코드 블록 검사
    final pattern = RegExp(
      r'^``````$',
      multiLine: true,
    );

    final match = pattern.firstMatch(codeBlockFull);

    if (match != null) {
      if (match.group(1) != null && match.group(1)!.isNotEmpty) {
        language = match.group(1)!;
      }
      code = match.group(2)?.replaceAll(RegExp(r'\n+$'), '') ?? '';
    } else {
      // 폴백: 첫 줄에서 언어 추출
      final firstLine = codeBlockFull.split('\n').first;
      final languageMatch = RegExp(r'```(\w+)').firstMatch(firstLine);

      if (languageMatch != null && languageMatch.group(1) != null) {
        language = languageMatch.group(1)!;
        final startIdx = firstLine.length + 1;
        final endIdx = codeBlockFull.length - 2;
        if (startIdx < endIdx) {
          code = codeBlockFull.substring(startIdx, endIdx).replaceAll(RegExp(r'\n+$'), '');

          final lines = codeBlockFull.split('\n');
          if (lines.length > 1) {
            code = lines.sublist(1, lines.length - 1).join('\n').replaceAll(RegExp(r'\n+$'), '');
          }

        }
      } else {
        final lines = codeBlockFull.split('\n');
        if (lines.length > 1) {
          code = lines.sublist(1, lines.length - 1).join('\n').replaceAll(RegExp(r'\n+$'), '');
          code = code.replaceAll(RegExp(r'\n+$'), '');
        }
      }
    }

    return (code: code, language: language);
  }

  /// 텍스트 위젯 빌더
  Widget _buildTextWidget(
      String text,
      bool isDark, {
        bool bottomPadding = false,
      }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomPadding ? UIConstants.spacing12 : 0,
      ),
      child: Text(
        text,
        style: UIHelpers.getTextStyle(
          isDark: isDark,
          fontSize: UIConstants.fontNormal,
        ),
      ),
    );
  }

  /// 홀수 백틱 경고 위젯 빌더
  Widget _buildOddBacktickWarning(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing12),
      margin: const EdgeInsets.only(bottom: UIConstants.spacing12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(UIConstants.glassOpacityLow),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        border: Border.all(
          color: Colors.orange.withOpacity(UIConstants.glassOpacityVeryHigh),
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
              '코드 블록이 올바르게 닫히지 않았습니다',
              style: UIHelpers.getTextStyle(
                isDark: isDark,
                fontSize: UIConstants.fontSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isUser) {
      return _buildUserMessage(isDark);
    } else {
      return _buildAssistantMessage(isDark);
    }
  }

  /// 사용자 메시지 빌더
  Widget _buildUserMessage(bool isDark) {
    return SliverToBoxAdapter(
      child: Align(
        alignment: Alignment.centerRight,
        child: UIHelpers.buildFloatingGlass(
          isDark: isDark,
          opacity: UIConstants.glassOpacityHigh,
          borderRadius: UIConstants.radiusXXLarge,
          blurSigma: UIConstants.blurSigmaMedium,
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.spacing16,
            vertical: UIConstants.spacing12,
          ),
          margin: const EdgeInsets.only(
            left: UIConstants.chatBubbleMaxWidth,
            right: UIConstants.spacing16,
            top: UIConstants.spacing4,
            bottom: UIConstants.spacing4,
          ),
          child: Text(
            message.content,
            style: UIHelpers.getTextStyle(
              isDark: isDark,
              fontSize: UIConstants.fontNormal,
            ),
          ),
        ),
      ),
    );
  }

  /// AI 메시지 빌더
  Widget _buildAssistantMessage(bool isDark) {
    final parsed = _parseContent(message.content, isDark);

    if (parsed.sliverWidgets.isNotEmpty) {
      return SliverMainAxisGroup(
        slivers: [
          if (parsed.normalWidgets.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.only(
                  left: UIConstants.spacing16,
                  right: UIConstants.spacing16,
                  top: UIConstants.spacing4,
                  bottom: UIConstants.spacing4,
                ),
                child: UIHelpers.buildFloatingGlass(
                  isDark: isDark,
                  opacity: UIConstants.glassOpacityMedium,
                  borderRadius: UIConstants.radiusXXLarge,
                  blurSigma: UIConstants.blurSigmaMedium,
                  padding: const EdgeInsets.all(UIConstants.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: parsed.normalWidgets,
                  ),
                ),
              ),
            ),
          ...parsed.sliverWidgets,
        ],
      );
    } else {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.only(
            left: UIConstants.spacing16,
            right: UIConstants.spacing16,
            top: UIConstants.spacing4,
            bottom: UIConstants.spacing4,
          ),
          child: UIHelpers.buildFloatingGlass(
            isDark: isDark,
            opacity: UIConstants.glassOpacityMedium,
            borderRadius: UIConstants.radiusXXLarge,
            blurSigma: UIConstants.blurSigmaMedium,
            padding: const EdgeInsets.all(UIConstants.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: parsed.normalWidgets,
            ),
          ),
        ),
      );
    }
  }
}
