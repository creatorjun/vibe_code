/// 마크다운 코드 블록 정보
class CodeBlock {
  final String language;
  final String code;
  final int startIndex;
  final int endIndex;

  CodeBlock({
    required this.language,
    required this.code,
    required this.startIndex,
    required this.endIndex,
  });
}

/// 마크다운 파서 유틸리티
class MarkdownParser {
  /// 백틱 3개로 시작하는 코드 블록 파싱
  static List<CodeBlock> parseCodeBlocks(String text) {
    final List<CodeBlock> blocks = [];
    final regex = RegExp(r'```(\w*)\n([\s\S]*?)```', multiLine: true);

    for (final match in regex.allMatches(text)) {
      final language = match.group(1)?.trim() ?? 'text';
      final code = match.group(2)?.trim() ?? '';

      blocks.add(CodeBlock(
        language: language.isEmpty ? 'text' : language,
        code: code,
        startIndex: match.start,
        endIndex: match.end,
      ));
    }

    return blocks;
  }

  /// 백틱 개수 확인 및 자동 닫기
  static String fixUnclosedCodeBlocks(String text) {
    final backtickMatches = RegExp(r'```').allMatches(text);
    final count = backtickMatches.length;

    // 홀수개면 마지막에 백틱 3개 추가
    if (count.isOdd) {
      return '$text\n```';
    }

    return text;
  }

  /// 텍스트를 일반 텍스트와 코드 블록으로 분리
  static List<MessagePart> parseMessage(String text) {
    final List<MessagePart> parts = [];
    final fixedText = fixUnclosedCodeBlocks(text);
    final blocks = parseCodeBlocks(fixedText);

    if (blocks.isEmpty) {
      parts.add(TextPart(content: text));
      return parts;
    }

    int lastIndex = 0;

    for (final block in blocks) {
      // 코드 블록 이전의 텍스트 추가
      if (block.startIndex > lastIndex) {
        final textContent = fixedText.substring(lastIndex, block.startIndex).trim();
        if (textContent.isNotEmpty) {
          parts.add(TextPart(content: textContent));
        }
      }

      // 코드 블록 추가
      parts.add(CodePart(
        language: block.language,
        code: block.code,
      ));

      lastIndex = block.endIndex;
    }

    // 마지막 텍스트 추가
    if (lastIndex < fixedText.length) {
      final textContent = fixedText.substring(lastIndex).trim();
      if (textContent.isNotEmpty) {
        parts.add(TextPart(content: textContent));
      }
    }

    return parts;
  }
}

/// 메시지 파트 추상 클래스
abstract class MessagePart {
  const MessagePart();
}

/// 일반 텍스트 파트
class TextPart extends MessagePart {
  final String content;
  const TextPart({required this.content});
}

/// 코드 블록 파트
class CodePart extends MessagePart {
  final String language;
  final String code;
  const CodePart({required this.language, required this.code});
}
