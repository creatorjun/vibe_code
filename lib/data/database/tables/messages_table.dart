import 'package:drift/drift.dart';
import 'chat_sessions_table.dart';

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(ChatSessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get content => text()();
  TextColumn get role => text().withLength(min: 1, max: 20)(); // 'user', 'assistant', 'system'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isStreaming => boolean().withDefault(const Constant(false))();
  TextColumn get model => text().nullable()(); // 사용된 모델명
}
