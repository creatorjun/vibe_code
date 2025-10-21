import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/attachments_table.dart';
import '../tables/message_attachments_table.dart';

part 'attachment_dao.g.dart';

@DriftAccessor(tables: [Attachments, MessageAttachments])
class AttachmentDao extends DatabaseAccessor<AppDatabase>
    with _$AttachmentDaoMixin {
  AttachmentDao(super.db);

  // 첨부파일 생성 (중복 체크 포함)
  Future<String> createAttachment({
    required String id,
    required String fileName,
    required String filePath,
    required String mimeType,
    required int fileSize,
    required String fileHash,
  }) async {
    // 동일한 해시를 가진 파일이 있는지 확인
    final existing = await (select(attachments)
      ..where((t) => t.fileHash.equals(fileHash)))
        .getSingleOrNull();

    if (existing != null) {
      return existing.id;
    }

    // 새 첨부파일 생성
    await into(attachments).insert(
      AttachmentsCompanion.insert(
        id: id,
        fileName: fileName,
        filePath: filePath,
        mimeType: mimeType,
        fileSize: fileSize,
        fileHash: fileHash,
      ),
    );

    return id;
  }

  // 첨부파일 조회
  Future<Attachment?> getAttachment(String attachmentId) async {
    return (select(attachments)..where((t) => t.id.equals(attachmentId)))
        .getSingleOrNull();
  }

  // 메시지에 첨부파일 연결
  Future<void> linkAttachmentToMessage({
    required int messageId,
    required String attachmentId,
    required int orderIndex,
  }) async {
    await into(messageAttachments).insert(
      MessageAttachmentsCompanion.insert(
        messageId: messageId,
        attachmentId: attachmentId,
        orderIndex: orderIndex,
      ),
    );
  }

  // 특정 메시지의 첨부파일 조회
  Future<List<Attachment>> getAttachmentsForMessage(int messageId) async {
    final query = select(attachments).join([
      innerJoin(
        messageAttachments,
        messageAttachments.attachmentId.equalsExp(attachments.id),
      ),
    ])
      ..where(messageAttachments.messageId.equals(messageId))
      ..where(messageAttachments.isActive.equals(true))
      ..orderBy([OrderingTerm.asc(messageAttachments.orderIndex)]);

    final results = await query.get();
    return results.map((row) => row.readTable(attachments)).toList();
  }

  // 첨부파일 비활성화
  Future<void> deactivateAttachment({
    required int messageId,
    required String attachmentId,
  }) async {
    await (update(messageAttachments)
      ..where((t) =>
      t.messageId.equals(messageId) &
      t.attachmentId.equals(attachmentId)))
        .write(
      const MessageAttachmentsCompanion(
        isActive: Value(false),
      ),
    );
  }

  // 첨부파일 삭제
  Future<void> deleteAttachment(String attachmentId) async {
    await (delete(attachments)..where((t) => t.id.equals(attachmentId))).go();
  }

  // 미사용 첨부파일 정리 (어떤 메시지에도 연결되지 않은 파일)
  Future<List<Attachment>> getUnusedAttachments() async {
    final usedIds = await (selectOnly(messageAttachments)
      ..addColumns([messageAttachments.attachmentId]))
        .map((row) => row.read(messageAttachments.attachmentId)!)
        .get();

    return (select(attachments)..where((t) => t.id.isNotIn(usedIds))).get();
  }

  // 모든 첨부파일 조회
  Future<List<Attachment>> getAllAttachments() async {
    return select(attachments).get();
  }

// 모든 첨부파일 삭제
  Future<void> deleteAllAttachments() async {
    await delete(messageAttachments).go();
    await delete(attachments).go();
  }
}
