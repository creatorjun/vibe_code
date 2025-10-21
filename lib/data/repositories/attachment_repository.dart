import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../core/utils/logger.dart';
import '../database/daos/attachment_dao.dart';
import '../database/app_database.dart';
import '../services/file_service.dart';

class AttachmentRepository {
  final AttachmentDao _attachmentDao;
  final FileService _fileService;
  final Uuid _uuid = const Uuid();

  AttachmentRepository(this._attachmentDao, this._fileService);

  /// 파일 업로드 및 첨부파일 생성
  Future<String> uploadFile(String filePath) async {
    final file = File(filePath);

    // 파일 검증
    await _fileService.validateFile(file);

    // 파일 정보 추출
    final fileName = filePath.split('/').last;
    final mimeType = _fileService.getMimeType(filePath) ?? 'application/octet-stream';
    final fileSize = await file.length();
    final fileHash = await _fileService.calculateHash(file);

    Logger.info('Uploading file: $fileName, ${fileSize ~/ 1024}KB');

    // 앱 디렉토리로 복사
    final savedPath = await _fileService.saveToAppDirectory(file);

    // DB에 저장
    final id = _uuid.v4();
    final attachmentId = await _attachmentDao.createAttachment(
      id: id,
      fileName: fileName,
      filePath: savedPath,
      mimeType: mimeType,
      fileSize: fileSize,
      fileHash: fileHash,
    );

    Logger.info('File uploaded successfully: $attachmentId');
    return attachmentId;
  }

  /// 첨부파일 조회
  Future<Attachment?> getAttachment(String attachmentId) async {
    return await _attachmentDao.getAttachment(attachmentId);
  }

  /// 메시지에 첨부파일 연결
  Future<void> linkToMessage({
    required int messageId,
    required List<String> attachmentIds,
  }) async {
    Logger.info('Linking ${attachmentIds.length} attachments to message: $messageId');

    for (var i = 0; i < attachmentIds.length; i++) {
      await _attachmentDao.linkAttachmentToMessage(
        messageId: messageId,
        attachmentId: attachmentIds[i],
        orderIndex: i,
      );
    }
  }

  /// 메시지의 첨부파일 목록 조회
  Future<List<Attachment>> getMessageAttachments(int messageId) async {
    return await _attachmentDao.getAttachmentsForMessage(messageId);
  }

  /// 첨부파일 읽기
  Future<String> readAttachment(String attachmentId) async {
    final attachment = await _attachmentDao.getAttachment(attachmentId);
    if (attachment == null) {
      throw Exception('첨부파일을 찾을 수 없습니다.');
    }

    return await _fileService.readFile(attachment.filePath);
  }

  /// 첨부파일 삭제
  Future<void> deleteAttachment(String attachmentId) async {
    Logger.info('Deleting attachment: $attachmentId');

    final attachment = await _attachmentDao.getAttachment(attachmentId);
    if (attachment != null) {
      await _fileService.deleteFile(attachment.filePath);
    }

    await _attachmentDao.deleteAttachment(attachmentId);
  }

  /// 미사용 첨부파일 정리
  Future<void> cleanupUnusedAttachments() async {
    Logger.info('Cleaning up unused attachments');

    final unused = await _attachmentDao.getUnusedAttachments();

    for (final attachment in unused) {
      await _fileService.deleteFile(attachment.filePath);
      await _attachmentDao.deleteAttachment(attachment.id);
    }

    Logger.info('Cleaned up ${unused.length} unused attachments');
  }
}
