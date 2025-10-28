// lib/core/utils/token_counter.dart

/// 토큰 수 추정 유틸리티
class TokenCounter {
  TokenCounter._();

  // ✅ 모델별 토큰 비율 매핑
  static const Map<String, double> modelTokenRatios = {
    'gpt': 4.0,
    'claude': 3.8,
    'gemini': 4.2,
    'llama': 4.0,
    'mistral': 4.0,
    'deepseek': 3.5,
    'qwen': 3.8,
  };

  /// ✅ 개선: 모델별 토큰 추정
  static int estimateTokensForModel(String text, String modelId) {
    if (text.isEmpty) return 0;

    final charCount = text.length;
    final koreanCount = _countKoreanChars(text);
    final codeCount = _countCodeChars(text);

    // 모델별 기본 비율 찾기
    var ratio = 4.0; // 기본값
    for (var entry in modelTokenRatios.entries) {
      if (modelId.toLowerCase().contains(entry.key)) {
        ratio = entry.value;
        break;
      }
    }

    // 한글이 많으면 비율 조정 (한글은 토큰을 더 많이 소모)
    if (koreanCount / charCount > 0.3) {
      ratio *= 0.6; // 한글: 약 2.4자 = 1토큰
    }

    // 코드가 많으면 비율 조정
    if (codeCount / charCount > 0.3) {
      ratio *= 0.8; // 코드: 약 3.2자 = 1토큰
    }

    return (charCount / ratio).ceil();
  }

  /// 기본 토큰 추정 (모델 무관)
  static int estimateTokens(String text) {
    if (text.isEmpty) return 0;

    final charCount = text.length;
    final koreanCount = _countKoreanChars(text);
    final codeCount = _countCodeChars(text);

    // 한글이 많으면 2글자당 1토큰
    if (koreanCount / charCount > 0.3) {
      return (charCount / 2).ceil();
    }

    // 코드가 많으면 3글자당 1토큰
    if (codeCount / charCount > 0.3) {
      return (charCount / 3).ceil();
    }

    // 기본: 4글자당 1토큰 (영어 기준)
    return (charCount / 4).ceil();
  }

  /// 파일 크기에서 토큰 수 추정 (바이트 단위)
  static int estimateTokensFromBytes(int bytes) {
    return (bytes / 2 / 4).ceil();
  }

  /// ✅ 신규: 메시지 리스트의 총 토큰 수 계산 (모델별)
  static int estimateMessagesTokensForModel(
      List<String> messages,
      String modelId,
      ) {
    int total = 0;
    for (final message in messages) {
      total += estimateTokensForModel(message, modelId);
      total += 4; // 메시지당 오버헤드 (role, formatting 등)
    }
    return total;
  }

  /// 메시지 리스트의 총 토큰 수 계산
  static int estimateMessagesTokens(List<String> messages) {
    int total = 0;
    for (final message in messages) {
      total += estimateTokens(message);
      total += 4; // 메시지당 오버헤드
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

  /// 코드 문자 개수
  static int _countCodeChars(String text) {
    final codeChars = RegExp(r'[{}()\[\];=<>]');
    return codeChars.allMatches(text).length;
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

  @override
  String toString() {
    return 'Total: ${TokenCounter.formatTokenCount(totalTokens)} '
        '(Messages: ${TokenCounter.formatTokenCount(messageTokens)}, '
        'Attachments: ${TokenCounter.formatTokenCount(attachmentTokens)})';
  }
}
