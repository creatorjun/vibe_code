// lib/domain/mutations/send_message/session_manager.dart

import '../../../core/utils/logger.dart';
import '../../../data/repositories/chat_repository.dart';

class SessionManager {
  final ChatRepository chatRepository;

  const SessionManager(this.chatRepository);

  /// 세션 제목이 기본값일 경우 메시지 내용으로 업데이트
  Future<void> updateSessionTitleIfNeeded(
      int sessionId,
      String content,
      ) async {
    final session = await chatRepository.getSession(sessionId);
    if (session != null &&
        (session.title == '새로운 대화' || session.title.isEmpty)) {
      final title =
      content.length > 50 ? '${content.substring(0, 50)}...' : content;
      await chatRepository.updateSessionTitle(sessionId, title);
      Logger.info('Session title updated: $title');
    }
  }
}
