import 'package:drift/drift.dart';

import 'chat_sessions_table.dart';

/// 메시지 테이블 정의
class Messages extends Table {
  // 기본 키
  IntColumn get id => integer().autoIncrement()();

  // 세션 ID (외래키)
  IntColumn get sessionId => integer().references(ChatSessions, #id, onDelete: KeyAction.cascade)();

  // 메시지 내용
  TextColumn get content => text()();

  // 역할 (user, assistant, system)
  TextColumn get role => text()();

  // 사용된 모델 (AI 응답에만 해당)
  TextColumn get model => text().nullable()();

  // 스트리밍 중 여부
  BoolColumn get isStreaming => boolean().withDefault(const Constant(false))();

  // ===== 추가: 토큰 저장 컬럼 =====
  // 입력 토큰 수 (사용자 메시지 + 히스토리)
  IntColumn get inputTokens => integer().withDefault(const Constant(0))();

  // 출력 토큰 수 (AI 응답)
  IntColumn get outputTokens => integer().withDefault(const Constant(0))();
  // ================================

  // 생성 시간
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
