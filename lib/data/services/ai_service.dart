// lib/domain/services/ai_service.dart
import '../../data/models/api_request.dart';

/// AI 서비스 추상 인터페이스
abstract class AIService {
  /// 스트리밍 채팅 요청
  Stream<String> streamChat({
    required List<ChatMessage> messages,
    required String model,
  });

  /// 리소스 정리
  void dispose();
}
