// lib/domain/mutations/send_message/attachment_processor.dart

import 'dart:convert';
import 'dart:io';
import 'package:mime/mime.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/attachment_cache.dart';
import '../../../data/repositories/attachment_repository.dart';

class AttachmentProcessor {
  final AttachmentRepository attachmentRepository;
  final AttachmentCache _cache = AttachmentCache();

  AttachmentProcessor(this.attachmentRepository);

  /// 첨부 파일 처리: Base64 이미지 및 텍스트 파일 내용 추출
  /// ✅ 캐싱 및 파일 크기 제한 적용
  Future<AttachmentResult> processAttachments(
      List<String> attachmentIds,
      ) async {
    final base64Images = <String>[];
    final textAttachments = <String>[];

    if (attachmentIds.isEmpty) {
      return AttachmentResult(
        base64Images: base64Images,
        textAttachments: textAttachments,
      );
    }

    for (final attachmentId in attachmentIds) {
      try {
        final attachment = await attachmentRepository.getAttachment(attachmentId);
        if (attachment != null) {
          final file = File(attachment.filePath);
          if (await file.exists()) {
            // MIME 타입 확인
            final mimeType = lookupMimeType(attachment.filePath);
            Logger.debug('Attachment MIME type: $mimeType for ${attachment.fileName}');

            if (mimeType != null && mimeType.startsWith('image/')) {
              // ✅ 이미지 처리: 캐시 확인
              await _processImage(attachmentId, attachment.fileName, file, base64Images);
            } else {
              // ✅ 텍스트 파일 처리: 크기 제한 및 캐싱
              await _processTextFile(attachmentId, attachment.fileName, file, textAttachments);
            }
          }
        }
      } catch (e, stack) {
        Logger.error('Failed to load attachment: $attachmentId', e, stack);
      }
    }

    return AttachmentResult(
      base64Images: base64Images,
      textAttachments: textAttachments,
    );
  }

  /// ✅ 이미지 파일 처리 (캐싱 적용)
  Future<void> _processImage(
      String attachmentId,
      String fileName,
      File file,
      List<String> base64Images,
      ) async {
    // 1. 캐시 확인
    var base64String = _cache.getCachedImage(attachmentId);

    if (base64String == null) {
      // 2. 캐시 미스: 파일 읽기 및 Base64 인코딩
      final bytes = await file.readAsBytes();
      base64String = base64Encode(bytes);

      // 3. 캐시에 저장
      _cache.cacheImage(attachmentId, base64String);

      Logger.info('[Attachment] Image encoded: $fileName (${bytes.length} bytes)');
    } else {
      Logger.info('[Attachment] Image loaded from cache: $fileName');
    }

    base64Images.add(base64String);
  }

  /// ✅ 텍스트 파일 처리 (크기 제한 및 캐싱 적용)
  Future<void> _processTextFile(
      String attachmentId,
      String fileName,
      File file,
      List<String> textAttachments,
      ) async {
    try {
      // 1. 캐시 확인
      var fileContent = _cache.getCachedText(attachmentId);

      if (fileContent == null) {
        // 2. 캐시 미스: 파일 읽기
        fileContent = await file.readAsString();

        // 3. 파일 크기가 크면 요약 (토큰 절약)
        if (fileContent.length > AppConstants.maxCharsPerTextFile) {
          final truncated = fileContent.substring(0, AppConstants.maxCharsPerTextFile);
          final remaining = fileContent.length - AppConstants.maxCharsPerTextFile;
          fileContent = '$truncated\n\n... (생략: $remaining자 더 있음)';

          Logger.info(
            '[Attachment] Text file truncated: $fileName (${fileContent.length} chars shown)',
          );
        } else {
          Logger.info('[Attachment] Text file loaded: $fileName (${fileContent.length} chars)');
        }

        // 4. 캐시에 저장
        _cache.cacheText(attachmentId, fileContent);
      } else {
        Logger.info('[Attachment] Text loaded from cache: $fileName');
      }

      textAttachments.add('--- $fileName ---\n$fileContent\n---');
    } catch (e) {
      Logger.warning('[Attachment] Failed to read as text: $fileName', e);
    }
  }

  /// 전체 메시지 내용 구성: 사용자 텍스트 + 텍스트 첨부파일
  String buildFullContent(String content, List<String> textAttachments) {
    if (textAttachments.isEmpty) return content;

    final fullContent = '$content\n\n${textAttachments.join('\n\n')}';
    Logger.info('[Attachment] Full content with text attachments: ${fullContent.length} chars');

    return fullContent;
  }
}

/// 첨부 파일 처리 결과
class AttachmentResult {
  final List<String> base64Images;
  final List<String> textAttachments;

  const AttachmentResult({
    required this.base64Images,
    required this.textAttachments,
  });
}
