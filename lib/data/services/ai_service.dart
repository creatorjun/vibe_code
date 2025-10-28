// lib/data/services/ai_service.dart

import '../models/api_request.dart';

/// AI 서비스 인터페이스
abstract class AIService {
  /// 스트리밍 채팅
  Stream<String> streamChat({
    required List<ChatMessage> messages,
    required String model,
    Function(int inputTokens, int outputTokens)? onTokenUsage, // ✅ 추가
  });

  /// 리소스 정리
  void dispose();
}
