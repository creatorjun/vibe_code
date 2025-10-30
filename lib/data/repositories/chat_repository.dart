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
    try {
      return await chatDao.createSession(title);
    } catch (e, stack) {
      Logger.error('Failed to create session', e, stack);
      rethrow;
    }
  }

  Stream<List<ChatSession>> watchSessions() {
    return chatDao.watchActiveSessions();
  }

  Future<ChatSession?> getSession(int sessionId) async {
    try {
      return await chatDao.getSession(sessionId);
    } catch (e, stack) {
      Logger.error('Failed to get session: $sessionId', e, stack);
      return null;
    }
  }

  Future<void> updateSessionTitle(int sessionId, String title) async {
    Logger.info('Updating session title: $sessionId - $title');
    try {
      await chatDao.updateSessionTitle(sessionId, title);
    } catch (e, stack) {
      Logger.error('Failed to update session title', e, stack);
      rethrow;
    }
  }

  Future<void> deleteSession(int sessionId) async {
    Logger.info('Deleting session: $sessionId');
    try {
      await chatDao.deleteSession(sessionId);
    } catch (e, stack) {
      Logger.error('Failed to delete session', e, stack);
      rethrow;
    }
  }

  Future<void> archiveSession(int sessionId) async {
    Logger.info('Archiving session: $sessionId');
    try {
      await chatDao.archiveSession(sessionId);
    } catch (e, stack) {
      Logger.error('Failed to archive session', e, stack);
      rethrow;
    }
  }

  // ===== Message Methods =====

  Stream<List<Message>> watchMessages(int sessionId) {
    return chatDao.watchMessagesForSession(sessionId);
  }

  Future<List<Message>> getMessages(int sessionId) async {
    try {
      return await chatDao.getMessagesForSession(sessionId);
    } catch (e, stack) {
      Logger.error('Failed to get messages for session: $sessionId', e, stack);
      return [];
    }
  }

  Future<int> addUserMessage({
    required int sessionId,
    required String content,
    int inputTokens = 0,
  }) async {
    Logger.info('Adding user message to session: $sessionId (${content.length} chars)');
    try {
      await chatDao.touchSession(sessionId);
      return await chatDao.addMessage(
        sessionId: sessionId,
        content: content,
        role: 'user',
        inputTokens: inputTokens,
      );
    } catch (e, stack) {
      Logger.error('Failed to add user message', e, stack);
      rethrow;
    }
  }

  Future<int> addAiMessage({
    required int sessionId,
    required String model,
    bool isStreaming = true,
  }) async {
    Logger.info('Adding AI message to session: $sessionId (model: $model)');
    try {
      return await chatDao.addMessage(
        sessionId: sessionId,
        content: '',
        role: 'assistant',
        model: model,
        isStreaming: isStreaming,
      );
    } catch (e, stack) {
      Logger.error('Failed to add AI message', e, stack);
      rethrow;
    }
  }

  Future<void> updateMessageContent(int messageId, String content) async {
    try {
      await chatDao.updateMessageContent(messageId, content);
    } catch (e, stack) {
      Logger.error('Failed to update message content: $messageId', e, stack);
      // 스트리밍 중 에러는 조용히 처리
    }
  }

  Future<void> completeStreaming(
      int messageId, {
        int? inputTokens,
        int? outputTokens,
      }) async {
    Logger.info('Completing streaming for message: $messageId');
    try {
      if (inputTokens != null || outputTokens != null) {
        await chatDao.updateMessageTokens(
          messageId,
          inputTokens: inputTokens,
          outputTokens: outputTokens,
        );
        Logger.debug('Tokens updated - input: $inputTokens, output: $outputTokens');
      }

      await chatDao.completeStreaming(messageId);
      Logger.info('Streaming completed successfully: $messageId');
    } catch (e, stack) {
      Logger.error('Failed to complete streaming', e, stack);
      rethrow;
    }
  }

  Future<void> deleteMessage(int messageId) async {
    Logger.info('Deleting message: $messageId');
    try {
      await chatDao.deleteMessage(messageId);
    } catch (e, stack) {
      Logger.error('Failed to delete message', e, stack);
      rethrow;
    }
  }

  Future<Message?> getLastMessage(int sessionId) async {
    try {
      return await chatDao.getLastMessage(sessionId);
    } catch (e, stack) {
      Logger.error('Failed to get last message', e, stack);
      return null;
    }
  }

  Stream<List<Message>> watchCompletedMessagesForSession(int sessionId) {
    return chatDao.watchCompletedMessagesForSession(sessionId);
  }

  Future<void> touchSession(int sessionId) async {
    try {
      await chatDao.touchSession(sessionId);
    } catch (e, stack) {
      Logger.error('Failed to touch session', e, stack);
      // 비중요 작업이므로 에러 무시
    }
  }

  AppDatabase get database => chatDao.attachedDatabase;

  // ===== Cleanup Methods =====

  /// ✅ 개선: 모든 대화 삭제 (배치 최적화만 적용)
  Future<void> deleteAllConversations() async {
    Logger.info('Deleting all conversations...');

    try {
      // 1. 첨부파일 파일 삭제 (병렬 처리)
      final allAttachments = await chatDao.attachedDatabase.attachmentDao.getAllAttachments();
      Logger.info('Found ${allAttachments.length} attachments to delete');

      // ✅ 배치 처리: 병렬 삭제
      await _deleteAttachmentFilesBatch(allAttachments);

      // 2. DB에서 첨부파일 삭제
      await chatDao.attachedDatabase.attachmentDao.deleteAllAttachments();
      Logger.info('Deleted all attachments from database');

      // 3. 메시지 삭제
      await chatDao.deleteAllMessages();
      Logger.info('Deleted all messages');

      // 4. 세션 삭제
      await chatDao.deleteAllSessions();
      Logger.info('Deleted all sessions');

      Logger.info('✅ All conversations deleted successfully');
    } catch (e, stack) {
      Logger.error('Failed to delete all conversations', e, stack);
      rethrow;
    }
  }

  // ===== Private Helper Methods =====

  /// ✅ 배치 파일 삭제 (병렬 처리)
  Future<void> _deleteAttachmentFilesBatch(List<Attachment> attachments) async {
    if (attachments.isEmpty) return;

    // 파일 삭제를 병렬로 실행 (최대 10개씩)
    const batchSize = 10;

    for (var i = 0; i < attachments.length; i += batchSize) {
      final batch = attachments.skip(i).take(batchSize);

      await Future.wait(
        batch.map((attachment) async {
          try {
            final file = File(attachment.filePath);
            if (await file.exists()) {
              await file.delete();
              Logger.debug('Deleted file: ${attachment.fileName}');
            }
          } catch (e) {
            Logger.warning('Failed to delete file: ${attachment.filePath}', e);
          }
        }),
      );
    }
  }
}
