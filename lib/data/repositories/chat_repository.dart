import 'dart:io';
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

  Stream<List<Message>> watchCompletedMessagesForSession(int sessionId) {
    return _chatDao.watchCompletedMessagesForSession(sessionId);
  }

  // ✅ 모든 대화 내역 삭제 (첨부파일 포함)
  Future<void> deleteAllConversations() async {
    Logger.info('Deleting all conversations...');

    // 1. 모든 첨부파일의 물리적 파일 삭제
    try {
      // ✅ attachmentDao 접근 (_chatDao.attachedDatabase)
      final allAttachments = await _chatDao.attachedDatabase.attachmentDao.getAllAttachments();
      Logger.info('Found ${allAttachments.length} attachments to delete');

      for (final attachment in allAttachments) {
        try {
          final file = File(attachment.filePath);
          if (await file.exists()) {
            await file.delete();
            Logger.debug('Deleted file: ${attachment.fileName}');
          }
        } catch (e) {
          Logger.warning('Failed to delete file: ${attachment.filePath}', e);
        }
      }

      // 2. DB에서 첨부파일 삭제
      await _chatDao.attachedDatabase.attachmentDao.deleteAllAttachments();
      Logger.info('Deleted all attachments from database');
    } catch (e) {
      Logger.error('Failed to delete attachments', e);
    }

    // 3. 메시지 삭제
    await _chatDao.deleteAllMessages();
    Logger.info('Deleted all messages');

    // 4. 세션 삭제
    await _chatDao.deleteAllSessions();
    Logger.info('Deleted all sessions');

    Logger.info('✅ All conversations deleted successfully');
  }
}