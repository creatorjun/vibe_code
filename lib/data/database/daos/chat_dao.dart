// lib/data/database/daos/chat_dao.dart

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/chat_sessions_table.dart';
import '../tables/messages_table.dart';

part 'chat_dao.g.dart';

@DriftAccessor(tables: [ChatSessions, Messages])
class ChatDao extends DatabaseAccessor<AppDatabase> with _$ChatDaoMixin {
  ChatDao(super.db);

  // ===== Session Methods =====

  /// 새 세션 생성
  Future<int> createSession(String title) async {
    return into(chatSessions).insert(
      ChatSessionsCompanion.insert(
        title: title,
      ),
    );
  }

  /// 활성 세션 목록을 스트림으로 반환
  Stream<List<ChatSession>> watchActiveSessions() {
    return (select(chatSessions)
      ..where((t) => t.isArchived.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  /// 특정 세션 정보를 스트림으로 반환
  Stream<ChatSession?> watchSession(int sessionId) {
    return (select(chatSessions)..where((t) => t.id.equals(sessionId)))
        .watchSingleOrNull();
  }

  /// 특정 세션 정보 조회
  Future<ChatSession?> getSession(int sessionId) async {
    return (select(chatSessions)..where((t) => t.id.equals(sessionId)))
        .getSingleOrNull();
  }

  /// 세션 제목 업데이트
  Future<void> updateSessionTitle(int sessionId, String title) async {
    await (update(chatSessions)..where((t) => t.id.equals(sessionId))).write(
      ChatSessionsCompanion(
        title: Value(title),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 세션의 updatedAt 갱신 (메시지 추가 시 호출)
  Future<void> touchSession(int sessionId) async {
    await (update(chatSessions)..where((t) => t.id.equals(sessionId))).write(
      ChatSessionsCompanion(
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 세션 삭제
  Future<void> deleteSession(int sessionId) async {
    await (delete(chatSessions)..where((t) => t.id.equals(sessionId))).go();
  }

  /// 세션 보관
  Future<void> archiveSession(int sessionId) async {
    await (update(chatSessions)..where((t) => t.id.equals(sessionId))).write(
      const ChatSessionsCompanion(
        isArchived: Value(true),
      ),
    );
  }

  // ===== Message Methods =====

  /// 특정 세션의 메시지 목록을 스트림으로 반환
  Stream<List<Message>> watchMessagesForSession(int sessionId) {
    return (select(messages)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  /// 완료된 메시지만 스트림으로 반환
  Stream<List<Message>> watchCompletedMessagesForSession(int sessionId) {
    return (select(messages)
      ..where((t) =>
      t.sessionId.equals(sessionId) & t.isStreaming.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  /// 특정 세션의 메시지 목록 조회
  Future<List<Message>> getMessagesForSession(int sessionId) async {
    return (select(messages)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// 메시지 추가 (===== 수정: 토큰 파라미터 추가 =====)
  Future<int> addMessage({
    required int sessionId,
    required String content,
    required String role,
    String? model,
    bool isStreaming = false,
    int inputTokens = 0,      // ===== 추가 =====
    int outputTokens = 0,     // ===== 추가 =====
  }) async {
    return into(messages).insert(
      MessagesCompanion.insert(
        sessionId: sessionId,
        content: content,
        role: role,
        model: Value(model),
        isStreaming: Value(isStreaming),
        inputTokens: Value(inputTokens),     // ===== 추가 =====
        outputTokens: Value(outputTokens),   // ===== 추가 =====
      ),
    );
  }

  /// 메시지 내용 업데이트 (===== 수정: 토큰 업데이트 추가 =====)
  Future<void> updateMessageContent(
      int messageId,
      String content, {
        int? inputTokens,    // ===== 추가 =====
        int? outputTokens,   // ===== 추가 =====
      }) async {
    await (update(messages)..where((t) => t.id.equals(messageId))).write(
      MessagesCompanion(
        content: Value(content),
        inputTokens: inputTokens != null ? Value(inputTokens) : const Value.absent(),    // ===== 추가 =====
        outputTokens: outputTokens != null ? Value(outputTokens) : const Value.absent(), // ===== 추가 =====
      ),
    );
  }

  // lib/data/database/daos/chat_dao.dart

  /// 토큰 정보만 업데이트
  Future<void> updateMessageTokens(
      int messageId, {
        int? inputTokens,
        int? outputTokens,
      }) async {
    // ✅ MessagesCompanion 올바른 사용법
    final companion = MessagesCompanion(
      inputTokens: inputTokens != null ? Value(inputTokens) : const Value.absent(),
      outputTokens: outputTokens != null ? Value(outputTokens) : const Value.absent(),
    );

    await (update(messages)..where((t) => t.id.equals(messageId))).write(companion);
  }


  /// 스트리밍 완료 처리
  Future<void> completeStreaming(int messageId) async {
    await (update(messages)..where((t) => t.id.equals(messageId))).write(
      const MessagesCompanion(
        isStreaming: Value(false),
      ),
    );
  }

  /// 메시지 삭제
  Future<void> deleteMessage(int messageId) async {
    await (delete(messages)..where((t) => t.id.equals(messageId))).go();
  }

  /// 세션의 모든 메시지 삭제
  Future<void> deleteAllMessagesInSession(int sessionId) async {
    await (delete(messages)..where((t) => t.sessionId.equals(sessionId))).go();
  }

  /// 마지막 메시지 조회
  Future<Message?> getLastMessage(int sessionId) async {
    return (select(messages)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1))
        .getSingleOrNull();
  }

  // ===== 추가: 세션의 토큰 합계 조회 =====
  /// 특정 세션의 총 토큰 사용량 조회
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
  // =========================================

  // ===== Cleanup Methods =====

  /// 모든 세션 삭제
  Future<void> deleteAllSessions() async {
    await delete(chatSessions).go();
  }

  /// 모든 메시지 삭제
  Future<void> deleteAllMessages() async {
    await delete(messages).go();
  }
}

// ===== 추가: 토큰 사용량 요약 클래스 =====
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
// ==========================================
