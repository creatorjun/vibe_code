// lib/domain/mutations/send_message/message_history_builder.dart

import '../../../core/utils/logger.dart';
import '../../../data/models/api_request.dart';
import '../../../data/repositories/chat_repository.dart';

class MessageHistoryBuilder {
  final ChatRepository chatRepository;

  const MessageHistoryBuilder(this.chatRepository);

  /// DB에서 메시지 히스토리를 불러와 API 메시지 형식으로 변환
  Future<List<ChatMessage>> buildMessageHistory(int sessionId) async {
    final dbMessages = await chatRepository.getMessages(sessionId);
    return dbMessages.map((msg) {
      return ChatMessage.text(
        role: msg.role,
        text: msg.content,
      );
    }).toList();
  }

  /// 현재 사용자 메시지를 API 메시지 형식으로 추가
  void addCurrentUserMessage({
    required List<ChatMessage> apiMessages,
    required String fullContent,
    required List<String> base64Images,
  }) {
    if (base64Images.isNotEmpty) {
      // 이미지가 있는 경우: Vision API 형식
      apiMessages.add(ChatMessage.withImages(
        role: 'user',
        text: fullContent.isEmpty ? '이미지를 분석해주세요' : fullContent,
        base64Images: base64Images,
      ));
      Logger.info('[Vision API] Sending ${base64Images.length} image(s) with message');
    } else {
      // 텍스트만 있는 경우
      apiMessages.add(ChatMessage.text(
        role: 'user',
        text: fullContent,
      ));
    }
  }
}
