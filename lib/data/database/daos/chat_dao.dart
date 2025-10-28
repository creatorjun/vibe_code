import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/chat_sessions_table.dart';
import '../tables/messages_table.dart';

part 'chat_dao.g.dart';

@DriftAccessor(tables: [ChatSessions, Messages])
class ChatDao extends DatabaseAccessor<AppDatabase> with _$ChatDaoMixin {
  ChatDao(super.db);

  // ============ Session Methods ============

  Future<int> createSession(String title) async {
    return into(chatSessions).insert(ChatSessionsCompanion.insert(
      title: title,
    ));
  }

  // ✅ 최적화 1: 최근 N개만 가져오기 (무한 리스트 방지)
  Stream<List<ChatSession>> watchActiveSessions({int limit = 50}) {
    return (select(chatSessions)
      ..where((t) => t.isArchived.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(limit)) // ✅ 최근 50개만
        .watch();
  }

  Stream<ChatSession?> watchSession(int sessionId) {
    return (select(chatSessions)..where((t) => t.id.equals(sessionId)))
        .watchSingleOrNull();
  }

  Future<ChatSession?> getSession(int sessionId) async {
    return (select(chatSessions)..where((t) => t.id.equals(sessionId)))
        .getSingleOrNull();
  }

  Future<void> updateSessionTitle(int sessionId, String title) async {
    await (update(chatSessions)..where((t) => t.id.equals(sessionId))).write(
      ChatSessionsCompanion(
        title: Value(title),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> touchSession(int sessionId) async {
    await (update(chatSessions)..where((t) => t.id.equals(sessionId))).write(
      ChatSessionsCompanion(
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteSession(int sessionId) async {
    // ✅ 최적화 2: CASCADE 삭제 활용 (메시지 자동 삭제)
    await (delete(chatSessions)..where((t) => t.id.equals(sessionId))).go();
  }

  Future<void> archiveSession(int sessionId) async {
    await (update(chatSessions)..where((t) => t.id.equals(sessionId))).write(
      const ChatSessionsCompanion(
        isArchived: Value(true),
      ),
    );
  }

  // ============ Message Methods ============

  Stream<List<Message>> watchMessagesForSession(int sessionId) {
    return (select(messages)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Stream<List<Message>> watchCompletedMessagesForSession(int sessionId) {
    return (select(messages)
      ..where((t) =>
      t.sessionId.equals(sessionId) & t.isStreaming.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Future<List<Message>> getMessagesForSession(int sessionId) async {
    return (select(messages)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<int> addMessage({
    required int sessionId,
    required String content,
    required String role,
    String? model,
    bool isStreaming = false,
    int inputTokens = 0,
    int outputTokens = 0,
  }) async {
    return into(messages).insert(MessagesCompanion.insert(
      sessionId: sessionId,
      content: content,
      role: role,
      model: Value(model),
      isStreaming: Value(isStreaming),
      inputTokens: Value(inputTokens),
      outputTokens: Value(outputTokens),
    ));
  }

  Future<void> updateMessageContent(
      int messageId,
      String content, {
        int? inputTokens,
        int? outputTokens,
      }) async {
    await (update(messages)..where((t) => t.id.equals(messageId))).write(
      MessagesCompanion(
        content: Value(content),
        inputTokens: inputTokens != null ? Value(inputTokens) : const Value.absent(),
        outputTokens: outputTokens != null ? Value(outputTokens) : const Value.absent(),
      ),
    );
  }

  Future<void> updateMessageTokens(
      int messageId, {
        int? inputTokens,
        int? outputTokens,
      }) async {
    final companion = MessagesCompanion(
      inputTokens: inputTokens != null ? Value(inputTokens) : const Value.absent(),
      outputTokens: outputTokens != null ? Value(outputTokens) : const Value.absent(),
    );
    await (update(messages)..where((t) => t.id.equals(messageId))).write(companion);
  }

  Future<void> completeStreaming(int messageId) async {
    await (update(messages)..where((t) => t.id.equals(messageId))).write(
      const MessagesCompanion(
        isStreaming: Value(false),
      ),
    );
  }

  Future<void> deleteMessage(int messageId) async {
    await (delete(messages)..where((t) => t.id.equals(messageId))).go();
  }

  Future<void> deleteAllMessagesInSession(int sessionId) async {
    await (delete(messages)..where((t) => t.sessionId.equals(sessionId))).go();
  }

  Future<Message?> getLastMessage(int sessionId) async {
    return (select(messages)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1))
        .getSingleOrNull();
  }

  // ✅ 최적화 3: DB 레벨 집계 쿼리로 성능 향상
  Future<TokenUsageSummary> getSessionTokenUsage(int sessionId) async {
    final result = await (selectOnly(messages)
      ..addColumns([
        messages.inputTokens.sum(),
        messages.outputTokens.sum(),
      ])
      ..where(messages.sessionId.equals(sessionId)))
        .getSingleOrNull();

    final inputTotal = result?.read(messages.inputTokens.sum()) ?? 0;
    final outputTotal = result?.read(messages.outputTokens.sum()) ?? 0;

    return TokenUsageSummary(
      inputTokens: inputTotal,
      outputTokens: outputTotal,
      totalTokens: inputTotal + outputTotal,
    );
  }

  // ✅ 최적화 4: 메시지 개수만 카운트 (전체 데이터 로드 안 함)
  Future<int> getSessionMessageCount(int sessionId) async {
    final result = await (selectOnly(messages)
      ..addColumns([messages.id.count()])
      ..where(messages.sessionId.equals(sessionId)))
        .getSingleOrNull();

    return result?.read(messages.id.count()) ?? 0;
  }

  // ============ Cleanup Methods ============

  Future<void> deleteAllSessions() async {
    await delete(chatSessions).go();
  }

  Future<void> deleteAllMessages() async {
    await delete(messages).go();
  }
}

class TokenUsageSummary {
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;

  const TokenUsageSummary({
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
  });
}
