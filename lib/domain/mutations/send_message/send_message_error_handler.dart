// lib/domain/mutations/send_message/send_message_error_handler.dart

import '../../../core/utils/logger.dart';
import '../../../data/repositories/chat_repository.dart';

class SendMessageErrorHandler {
  final ChatRepository chatRepository;

  const SendMessageErrorHandler(this.chatRepository);

  /// AI 메시지를 정리 (에러 발생 시)
  Future<void> handleError(
      int sessionId,
      int? userMessageId,
      int? aiMessageId,
      ) async {
    if (aiMessageId != null) {
      try {
        await chatRepository.deleteMessage(aiMessageId);
        Logger.debug('Cleaned up AI message: $aiMessageId');
      } catch (e) {
        Logger.error('Failed to delete AI message', e);
      }
    }
  }

  /// AI 메시지에 에러 내용 추가
  Future<void> appendErrorToMessage(
      int sessionId,
      int aiMessageId,
      String errorMessage,
      ) async {
    String existingContent = '';
    try {
      final messages = await chatRepository.getMessages(sessionId);
      final currentMessage = messages.firstWhere((m) => m.id == aiMessageId);
      existingContent = currentMessage.content;
    } catch (_) {}

    final errorContent = existingContent.trim().isNotEmpty
        ? '$existingContent\n\n⚠️ 파이프라인 오류\n\n$errorMessage'
        : '⚠️ 메시지 전송 실패\n\n$errorMessage';

    await chatRepository.updateMessageContent(aiMessageId, errorContent);
    await chatRepository.completeStreaming(aiMessageId);
    Logger.info(
        'Error message ${existingContent.isEmpty ? "saved" : "appended"} to database: $aiMessageId');
  }
}
