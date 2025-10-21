import '../../core/utils/logger.dart';
import '../database/daos/chat_dao.dart';
import '../database/app_database.dart';

class ChatRepository {
  final ChatDao _chatDao;

  ChatRepository(this._chatDao);

  // 세션 관리
  Future<int> createSession(String title) async {
    Logger.info('Creating new session: $title');
    return await _chatDao.createSession(title);
  }

  Stream<List<ChatSession>> watchSessions() {
    return _chatDao.watchActiveSessions();
  }

  Future<ChatSession?> getSession(int sessionId) async {
    return await _chatDao.getSession(sessionId);
  }

  Future<void> updateSessionTitle(int sessionId, String title) async {
    Logger.info('Updating session title: $sessionId -> $title');
    await _chatDao.updateSessionTitle(sessionId, title);
  }

  Future<void> deleteSession(int sessionId) async {
    Logger.info('Deleting session: $sessionId');
    await _chatDao.deleteSession(sessionId);
  }

  Future<void> archiveSession(int sessionId) async {
    Logger.info('Archiving session: $sessionId');
    await _chatDao.archiveSession(sessionId);
  }

  // 메시지 관리
  Stream<List<Message>> watchMessages(int sessionId) {
    return _chatDao.watchMessagesForSession(sessionId);
  }

  Future<List<Message>> getMessages(int sessionId) async {
    return await _chatDao.getMessagesForSession(sessionId);
  }

  Future<int> addUserMessage({
    required int sessionId,
    required String content,
  }) async {
    Logger.info('Adding user message to session: $sessionId');
    await _chatDao.touchSession(sessionId);
    return await _chatDao.addMessage(
      sessionId: sessionId,
      content: content,
      role: 'user',
    );
  }

  Future<int> addAssistantMessage({
    required int sessionId,
    required String model,
    bool isStreaming = true,
  }) async {
    Logger.info('Adding assistant message to session: $sessionId');
    return await _chatDao.addMessage(
      sessionId: sessionId,
      content: '',
      role: 'assistant',
      model: model,
      isStreaming: isStreaming,
    );
  }

  Future<void> updateMessageContent(int messageId, String content) async {
    await _chatDao.updateMessageContent(messageId, content);
  }

  Future<void> completeStreaming(int messageId) async {
    Logger.info('Completing streaming for message: $messageId');
    await _chatDao.completeStreaming(messageId);
  }

  Future<void> deleteMessage(int messageId) async {
    Logger.info('Deleting message: $messageId');
    await _chatDao.deleteMessage(messageId);
  }

  Future<Message?> getLastMessage(int sessionId) async {
    return await _chatDao.getLastMessage(sessionId);
  }
}
