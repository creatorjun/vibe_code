import 'package:drift/drift.dart';

class Attachments extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get fileName => text()();
  TextColumn get filePath => text()();
  TextColumn get mimeType => text()();
  IntColumn get fileSize => integer()();
  TextColumn get fileHash => text()(); // SHA256
  DateTimeColumn get uploadedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {fileHash},
  ];
}
