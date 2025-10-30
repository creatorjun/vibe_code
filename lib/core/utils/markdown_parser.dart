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

/// 마크다운 파서 유틸리티
class MarkdownParser {
  /// 텍스트를 일반 텍스트와 코드 블록으로 분리
  static List<MessagePart> parseMessage(String text) {
    final List<MessagePart> parts = [];
    final blocks = _parseCodeBlocks(text);

    if (blocks.isEmpty) {
      // 코드 블록이 없으면 전체를 텍스트로 반환
      if (text.trim().isNotEmpty) {
        parts.add(TextPart(content: text));
      }
      return parts;
    }

    int lastIndex = 0;
    for (final block in blocks) {
      // 코드 블록 이전의 텍스트 추가
      if (block.startIndex > lastIndex) {
        final textContent = text.substring(lastIndex, block.startIndex);
        if (textContent.trim().isNotEmpty) {
          parts.add(TextPart(content: textContent.trim()));
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
    if (lastIndex < text.length) {
      final textContent = text.substring(lastIndex);
      if (textContent.trim().isNotEmpty) {
        parts.add(TextPart(content: textContent.trim()));
      }
    }

    return parts;
  }

  /// 백틱 3개로 시작하는 코드 블록 파싱 (스택 기반)
  static List<CodeBlock> _parseCodeBlocks(String text) {
    final List<CodeBlock> blocks = [];
    final List<_CodeFenceInfo> stack = []; // 여는 태그의 정보를 저장

    int i = 0;
    while (i < text.length) {
      // 백틱 3개 연속 찾기
      if (i + 2 < text.length &&
          text[i] == '`' &&
          text[i + 1] == '`' &&
          text[i + 2] == '`') {

        // 백틱 3개 이후의 내용 확인
        int nextIdx = i + 3;
        String restOfLine = '';

        // 현재 줄의 끝까지 읽기
        while (nextIdx < text.length && text[nextIdx] != '\n') {
          restOfLine += text[nextIdx];
          nextIdx++;
        }

        // 여는 태그인지 닫는 태그인지 판단
        final trimmedRest = restOfLine.trim();

        if (trimmedRest.isEmpty) {
          // 닫는 태그: 백틱 3개 뒤에 공백/줄바꿈만 있음
          if (stack.isNotEmpty) {
            // 최상위 레벨의 코드 블록만 추출 (중첩 무시)
            final openingInfo = stack.removeLast();

            // 스택이 비어있으면 (최상위 레벨) 코드 블록으로 추가
            if (stack.isEmpty) {
              final openingEnd = _findLineEnd(text, openingInfo.index);
              final closingStart = i;

              if (openingEnd < closingStart) {
                // 코드 내용 추출
                final codeContent = text.substring(openingEnd + 1, closingStart);

                blocks.add(CodeBlock(
                  language: openingInfo.language.isEmpty ? 'text' : openingInfo.language,
                  code: codeContent,
                  startIndex: openingInfo.index,
                  endIndex: nextIdx < text.length ? nextIdx : text.length,
                ));
              }
            }
          }
          // 스택이 비어있으면 무시 (매칭되지 않은 닫는 태그)
          i = nextIdx < text.length ? nextIdx + 1 : text.length;
        } else {
          // 여는 태그: 백틱 3개 뒤에 언어명이나 다른 텍스트가 있음
          stack.add(_CodeFenceInfo(
            index: i,
            language: trimmedRest,
          ));
          i = nextIdx < text.length ? nextIdx + 1 : text.length;
        }
      } else {
        i++;
      }
    }

    return blocks;
  }

  /// 주어진 인덱스부터 줄바꿈을 찾거나 문자열 끝을 반환
  static int _findLineEnd(String text, int startIndex) {
    for (int i = startIndex; i < text.length; i++) {
      if (text[i] == '\n') {
        return i;
      }
    }
    return text.length;
  }
}

/// 코드 펜스 정보를 저장하는 내부 클래스
class _CodeFenceInfo {
  final int index;
  final String language;

  _CodeFenceInfo({
    required this.index,
    required this.language,
  });
}
