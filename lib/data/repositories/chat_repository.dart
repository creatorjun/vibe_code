// lib/data/repositories/chat_repository.dart

import 'dart:io';
import '../../core/utils/logger.dart';
import '../database/daos/chat_dao.dart';
import '../database/app_database.dart';

class ChatRepository {
  final ChatDao chatDao;

  ChatRepository(this.chatDao);

  // ===== Session Methods =====

  Future<int> createSession(String title) async {
    Logger.info('Creating new session: $title');
    return await chatDao.createSession(title);
  }

  Stream<List<ChatSession>> watchSessions() {
    return chatDao.watchActiveSessions();
  }

  Future<ChatSession?> getSession(int sessionId) async {
    return await chatDao.getSession(sessionId);
  }

  Future<void> updateSessionTitle(int sessionId, String title) async {
    Logger.info('Updating session title: $sessionId - $title');
    await chatDao.updateSessionTitle(sessionId, title);
  }

  Future<void> deleteSession(int sessionId) async {
    Logger.info('Deleting session: $sessionId');
    await chatDao.deleteSession(sessionId);
  }

  Future<void> archiveSession(int sessionId) async {
    Logger.info('Archiving session: $sessionId');
    await chatDao.archiveSession(sessionId);
  }

  // ===== Message Methods =====

  Stream<List<Message>> watchMessages(int sessionId) {
    return chatDao.watchMessagesForSession(sessionId);
  }

  Future<List<Message>> getMessages(int sessionId) async {
    return await chatDao.getMessagesForSession(sessionId);
  }

  /// 사용자 메시지 추가 (===== 수정: 토큰 파라미터 추가 =====)
  Future<int> addUserMessage({
    required int sessionId,
    required String content,
    int inputTokens = 0,  // ===== 추가 =====
  }) async {
    Logger.info('Adding user message to session: $sessionId');
    await chatDao.touchSession(sessionId);
    return await chatDao.addMessage(
      sessionId: sessionId,
      content: content,
      role: 'user',
      inputTokens: inputTokens,  // ===== 추가 =====
    );
  }

  /// AI 메시지 추가
  Future<int> addAiMessage({
    required int sessionId,
    required String model,
    bool isStreaming = true,
  }) async {
    Logger.info('Adding AI message to session: $sessionId');
    return await chatDao.addMessage(
      sessionId: sessionId,
      content: '',
      role: 'assistant',
      model: model,
      isStreaming: isStreaming,
    );
  }

  /// 메시지 내용 업데이트
  Future<void> updateMessageContent(int messageId, String content) async {
    await chatDao.updateMessageContent(messageId, content);
  }

  /// 스트리밍 완료 처리 (===== 수정: 토큰 파라미터 추가 =====)
  Future<void> completeStreaming(
      int messageId, {
        int? inputTokens,   // ===== 추가 =====
        int? outputTokens,  // ===== 추가 =====
      }) async {
    Logger.info('Completing streaming for message: $messageId');

    // ===== 추가: 토큰 정보와 함께 업데이트 =====
    if (inputTokens != null || outputTokens != null) {
      await chatDao.updateMessageContent(
        messageId,
        '', // 내용은 이미 updateMessageContent로 업데이트됨
        inputTokens: inputTokens,
        outputTokens: outputTokens,
      );
    }
    // ===========================================

    await chatDao.completeStreaming(messageId);
  }

  /// 메시지 삭제
  Future<void> deleteMessage(int messageId) async {
    Logger.info('Deleting message: $messageId');
    await chatDao.deleteMessage(messageId);
  }

  Future<Message?> getLastMessage(int sessionId) async {
    return await chatDao.getLastMessage(sessionId);
  }

  Stream<List<Message>> watchCompletedMessagesForSession(int sessionId) {
    return chatDao.watchCompletedMessagesForSession(sessionId);
  }

  /// 세션 업데이트 시간 갱신
  Future<void> touchSession(int sessionId) async {
    await chatDao.touchSession(sessionId);
  }

  /// 데이터베이스 접근 (DAO를 통한 접근)
  AppDatabase get database => chatDao.attachedDatabase;

  // ===== Cleanup Methods =====

  /// 모든 대화 삭제
  Future<void> deleteAllConversations() async {
    Logger.info('Deleting all conversations...');

    try {
      // 1. 첨부파일 파일 삭제
      final allAttachments = await chatDao.attachedDatabase.attachmentDao.getAllAttachments();
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
      await chatDao.attachedDatabase.attachmentDao.deleteAllAttachments();
      Logger.info('Deleted all attachments from database');
    } catch (e) {
      Logger.error('Failed to delete attachments', e);
    }

    // 3. 메시지 삭제
    await chatDao.deleteAllMessages();
    Logger.info('Deleted all messages');

    // 4. 세션 삭제
    await chatDao.deleteAllSessions();
    Logger.info('Deleted all sessions');

    Logger.info('✅ All conversations deleted successfully');
  }
}
