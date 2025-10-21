import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/chat_sessions_table.dart';
import '../tables/messages_table.dart';

part 'chat_dao.g.dart';

@DriftAccessor(tables: [ChatSessions, Messages])
class ChatDao extends DatabaseAccessor<AppDatabase> with _$ChatDaoMixin {
  ChatDao(super.db);

  // 세션 생성
  Future<int> createSession(String title) async {
    return into(chatSessions).insert(
      ChatSessionsCompanion.insert(
        title: title,
      ),
    );
  }

  // 활성 세션 목록 스트림
  Stream<List<ChatSession>> watchActiveSessions() {
    return (select(chatSessions)
      ..where((t) => t.isArchived.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  // 특정 세션 조회
  Future<ChatSession?> getSession(int sessionId) async {
    return (select(chatSessions)..where((t) => t.id.equals(sessionId)))
        .getSingleOrNull();
  }

  // 세션 제목 업데이트
  Future<void> updateSessionTitle(int sessionId, String title) async {
    await (update(chatSessions)..where((t) => t.id.equals(sessionId))).write(
      ChatSessionsCompanion(
        title: Value(title),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // 세션 updatedAt 갱신
  Future<void> touchSession(int sessionId) async {
    await (update(chatSessions)..where((t) => t.id.equals(sessionId))).write(
      ChatSessionsCompanion(
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // 세션 삭제
  Future<void> deleteSession(int sessionId) async {
    await (delete(chatSessions)..where((t) => t.id.equals(sessionId))).go();
  }

  // 세션 아카이브
  Future<void> archiveSession(int sessionId) async {
    await (update(chatSessions)..where((t) => t.id.equals(sessionId))).write(
      ChatSessionsCompanion(
        isArchived: const Value(true),
      ),
    );
  }

  // 특정 세션의 메시지 스트림
  Stream<List<Message>> watchMessagesForSession(int sessionId) {
    return (select(messages)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  // 특정 세션의 메시지 목록 조회
  Future<List<Message>> getMessagesForSession(int sessionId) async {
    return (select(messages)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  // 메시지 추가
  Future<int> addMessage({
    required int sessionId,
    required String content,
    required String role,
    String? model,
    bool isStreaming = false,
  }) async {
    return into(messages).insert(
      MessagesCompanion.insert(
        sessionId: sessionId,
        content: content,
        role: role,
        model: Value(model),
        isStreaming: Value(isStreaming),
      ),
    );
  }

  // 메시지 내용 업데이트 (스트리밍 중)
  Future<void> updateMessageContent(int messageId, String content) async {
    await (update(messages)..where((t) => t.id.equals(messageId))).write(
      MessagesCompanion(
        content: Value(content),
      ),
    );
  }

  // 스트리밍 완료 처리
  Future<void> completeStreaming(int messageId) async {
    await (update(messages)..where((t) => t.id.equals(messageId))).write(
      const MessagesCompanion(
        isStreaming: Value(false),
      ),
    );
  }

  // 메시지 삭제
  Future<void> deleteMessage(int messageId) async {
    await (delete(messages)..where((t) => t.id.equals(messageId))).go();
  }

  // 세션의 모든 메시지 삭제
  Future<void> deleteAllMessagesInSession(int sessionId) async {
    await (delete(messages)..where((t) => t.sessionId.equals(sessionId))).go();
  }

  // 마지막 메시지 조회
  Future<Message?> getLastMessage(int sessionId) async {
    return (select(messages)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1))
        .getSingleOrNull();
  }
}
