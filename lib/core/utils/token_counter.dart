// lib/core/utils/token_counter.dart

/// 토큰 수 추정 유틸리티
///
/// 정확한 토큰 계산은 tiktoken 등의 라이브러리가 필요하지만,
/// 대략적인 추정을 위해 간단한 규칙 사용:
/// - 영어: 평균 4글자 = 1토큰
/// - 한글: 평균 2글자 = 1토큰
/// - 코드: 평균 3글자 = 1토큰
class TokenCounter {
  TokenCounter._();

  /// 텍스트의 대략적인 토큰 수 계산
  static int estimateTokens(String text) {
    if (text.isEmpty) return 0;

    // 간단한 추정 로직
    // GPT 계열: 평균 1토큰 ≈ 4글자 (영어 기준)
    // 한글/일본어: 평균 1토큰 ≈ 2글자

    final charCount = text.length;
    final koreanCount = _countKoreanChars(text);
    final codeCount = _countCodeChars(text);

    // 한글이 많으면 2글자당 1토큰
    if (koreanCount > charCount * 0.3) {
      return (charCount / 2).ceil();
    }

    // 코드가 많으면 3글자당 1토큰
    if (codeCount > charCount * 0.3) {
      return (charCount / 3).ceil();
    }

    // 기본: 4글자당 1토큰 (영어 기준)
    return (charCount / 4).ceil();
  }

  /// 파일 크기에서 토큰 수 추정 (바이트 단위)
  static int estimateTokensFromBytes(int bytes) {
    // 1바이트 ≈ 1글자로 가정
    // UTF-8 기준 영어 1글자 = 1바이트, 한글 1글자 = 3바이트
    // 평균 2바이트 = 1글자, 4글자 = 1토큰
    return (bytes / 2 / 4).ceil();
  }

  /// 메시지 리스트의 총 토큰 수 계산
  static int estimateMessagesTokens(List<String> messages) {
    int total = 0;
    for (final message in messages) {
      total += estimateTokens(message);
      total += 4; // 메시지당 오버헤드 (role, formatting 등)
    }
    return total;
  }

  /// 세션의 토큰 사용량 추정
  static SessionTokenUsage estimateSessionTokens({
    required List<String> messageContents,
    required List<int> attachmentSizes,
  }) {
    int messageTokens = 0;
    for (final content in messageContents) {
      messageTokens += estimateTokens(content);
      messageTokens += 4; // 메시지 오버헤드
    }

    int attachmentTokens = 0;
    for (final size in attachmentSizes) {
      attachmentTokens += estimateTokensFromBytes(size);
    }

    return SessionTokenUsage(
      messageTokens: messageTokens,
      attachmentTokens: attachmentTokens,
      totalTokens: messageTokens + attachmentTokens,
    );
  }

  /// 한글 문자 개수
  static int _countKoreanChars(String text) {
    int count = 0;
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      // 한글 유니코드 범위: 0xAC00 ~ 0xD7A3
      if (code >= 0xAC00 && code <= 0xD7A3) {
        count++;
      }
    }
    return count;
  }

  static int _countCodeChars(String text) {
    int count = 0;
    final codeChars = RegExp(r'[{}()\[\];=<>]');
    // ✅ match 변수 제거
    count = codeChars.allMatches(text).length;
    return count;
  }

  /// 토큰 수를 읽기 쉬운 형식으로 포맷
  static String formatTokenCount(int tokens) {
    if (tokens < 1000) {
      return '$tokens';
    } else if (tokens < 1000000) {
      final k = (tokens / 1000).toStringAsFixed(1);
      return '${k}K';
    } else {
      final m = (tokens / 1000000).toStringAsFixed(1);
      return '${m}M';
    }
  }

  /// 모델의 컨텍스트 한계 대비 사용률 계산
  static double calculateUsagePercentage({
    required int usedTokens,
    required int contextLimit,
  }) {
    return (usedTokens / contextLimit * 100).clamp(0, 100);
  }
}

/// 세션 토큰 사용량
class SessionTokenUsage {
  final int messageTokens;
  final int attachmentTokens;
  final int totalTokens;

  const SessionTokenUsage({
    required this.messageTokens,
    required this.attachmentTokens,
    required this.totalTokens,
  });

  /// 읽기 쉬운 형식으로 출력
  @override
  String toString() {
    return 'Total: ${TokenCounter.formatTokenCount(totalTokens)} '
        '(Messages: ${TokenCounter.formatTokenCount(messageTokens)}, '
        'Attachments: ${TokenCounter.formatTokenCount(attachmentTokens)})';
  }
}
