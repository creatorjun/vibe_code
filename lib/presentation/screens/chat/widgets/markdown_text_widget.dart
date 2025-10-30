import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;

/// 마크다운 텍스트를 렌더링하는 위젯
class MarkdownTextWidget extends StatelessWidget {
  final String data;
  final TextStyle? baseStyle;
  final Color? textColor;

  const MarkdownTextWidget({
    super.key,
    required this.data,
    this.baseStyle,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // HTML로 변환
    final html = md.markdownToHtml(
      data,
      extensionSet: md.ExtensionSet.gitHubFlavored,
    );

    // HTML을 파싱해서 TextSpan으로 변환
    final spans = _parseHtmlToSpans(html, context);

    return SelectableText.rich(TextSpan(children: spans), style: baseStyle);
  }

  List<InlineSpan> _parseHtmlToSpans(String html, BuildContext context) {
    final spans = <InlineSpan>[];
    final theme = Theme.of(context);

    // 간단한 HTML 태그 파싱
    final pattern = RegExp(r'<(/?)(\w+)(?:\s+[^>]*)?>', multiLine: true);

    int lastIndex = 0;
    final tagStack = <String>[];
    final styleStack = <TextStyle>[baseStyle ?? const TextStyle()];

    for (final match in pattern.allMatches(html)) {
      // 태그 이전의 텍스트
      if (match.start > lastIndex) {
        final text = html.substring(lastIndex, match.start);
        final decoded = _decodeHtmlEntities(text);
        if (decoded.isNotEmpty) {
          spans.add(
            TextSpan(
              text: decoded,
              style: styleStack.last.copyWith(color: textColor),
            ),
          );
        }
      }

      final isClosing = match.group(1) == '/';
      final tagName = match.group(2)!.toLowerCase();

      if (isClosing) {
        // 닫는 태그
        if (tagStack.isNotEmpty && tagStack.last == tagName) {
          tagStack.removeLast();
          styleStack.removeLast();
        }

        // 블록 요소 닫을 때 줄바꿈 추가
        if (_isBlockElement(tagName) && spans.isNotEmpty) {
          spans.add(const TextSpan(text: '\n'));
        }
      } else {
        // 여는 태그
        // 블록 요소 시작 전 줄바꿈 (첫 요소가 아닐 때)
        if (_isBlockElement(tagName) && spans.isNotEmpty) {
          spans.add(const TextSpan(text: '\n'));
        }

        tagStack.add(tagName);
        final currentStyle = styleStack.last;

        switch (tagName) {
          case 'strong' || 'b':
            styleStack.add(currentStyle.copyWith(fontWeight: FontWeight.bold));
            break;
          case 'em' || 'i':
            styleStack.add(currentStyle.copyWith(fontStyle: FontStyle.italic));
            break;
          case 'code':
            styleStack.add(
              currentStyle.copyWith(
                fontFamily: 'monospace',
                backgroundColor: theme.brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
              ),
            );
            break;
          case 'del' || 's':
            styleStack.add(
              currentStyle.copyWith(decoration: TextDecoration.lineThrough),
            );
            break;
          case 'h1':
            styleStack.add(
              currentStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
            );
            break;
          case 'h2':
            styleStack.add(
              currentStyle.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
            );
            break;
          case 'h3':
            styleStack.add(
              currentStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
            );
            break;
          case 'h4':
            styleStack.add(
              currentStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
            );
            break;
          case 'li':
            // 리스트 아이템 시작 시 들여쓰기
            spans.add(
              TextSpan(
                text: '  • ',
                style: currentStyle.copyWith(color: textColor),
              ),
            );
            styleStack.add(currentStyle);
            break;
          default:
            styleStack.add(currentStyle);
        }
      }

      lastIndex = match.end;
    }

    // 마지막 텍스트
    if (lastIndex < html.length) {
      final text = html.substring(lastIndex);
      final decoded = _decodeHtmlEntities(text);
      if (decoded.isNotEmpty) {
        spans.add(
          TextSpan(
            text: decoded,
            style: styleStack.last.copyWith(color: textColor),
          ),
        );
      }
    }

    return spans;
  }

  bool _isBlockElement(String tagName) {
    return const [
      'p',
      'h1',
      'h2',
      'h3',
      'h4',
      'h5',
      'h6',
      'ul',
      'ol',
      'li',
      'blockquote',
      'pre',
      'div',
    ].contains(tagName);
  }

  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll('<br />', '\n')
        .trim();
  }
}
