import 'package:drift/drift.dart';
import 'messages_table.dart';
import 'attachments_table.dart';

class MessageAttachments extends Table {
  IntColumn get messageId => integer().references(Messages, #id, onDelete: KeyAction.cascade)();
  TextColumn get attachmentId => text().references(Attachments, #id, onDelete: KeyAction.cascade)();
  IntColumn get orderIndex => integer()(); // 첨부파일 순서
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {messageId, attachmentId};
}
