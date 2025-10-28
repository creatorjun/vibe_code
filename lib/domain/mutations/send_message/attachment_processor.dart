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
              // 이미지 처리
              await _processImage(attachmentId, attachment.fileName, file, base64Images);
            } else {
              // 텍스트 파일 처리
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

  /// 이미지 파일 처리 (캐싱 + 스트리밍 적용)
  Future<void> _processImage(
      String attachmentId,
      String fileName,
      File file,
      List<String> base64Images,
      ) async {
    // 1. 캐시 확인
    var base64String = _cache.getCachedImage(attachmentId);

    if (base64String == null) {
      // 2. 캐시 미스: 파일 크기 확인
      final fileSize = await file.length();

      // ✅ 10MB 이상이면 스트리밍 방식 사용
      if (fileSize > 10 * 1024 * 1024) {
        Logger.info('[Attachment] Large image detected (${fileSize ~/ 1024 ~/ 1024}MB), using streaming encoding: $fileName');
        base64String = await _encodeImageStream(file);
      } else {
        // 작은 파일은 기존 방식
        final bytes = await file.readAsBytes();
        base64String = base64Encode(bytes);
      }

      // 3. 캐시에 저장
      _cache.cacheImage(attachmentId, base64String);

      Logger.info('[Attachment] Image encoded: $fileName (${fileSize ~/ 1024}KB)');
    } else {
      Logger.info('[Attachment] Image loaded from cache: $fileName');
    }

    base64Images.add(base64String);
  }

  /// ✅ 신규: 스트리밍 방식 이미지 인코딩
  Future<String> _encodeImageStream(File file) async {
    final buffer = StringBuffer();
    final chunks = <int>[];
    const chunkSize = 1024 * 1024; // 1MB 청크

    try {
      final stream = file.openRead();

      await for (final chunk in stream) {
        chunks.addAll(chunk);

        // 청크 크기에 도달하면 인코딩
        while (chunks.length >= chunkSize) {
          final toEncode = chunks.sublist(0, chunkSize);
          chunks.removeRange(0, chunkSize);

          // Base64는 3바이트 단위로 처리되므로 정렬
          final alignedSize = (toEncode.length ~/ 3) * 3;
          if (alignedSize > 0) {
            final aligned = toEncode.sublist(0, alignedSize);
            final remaining = toEncode.sublist(alignedSize);

            buffer.write(base64Encode(aligned));

            // 남은 바이트는 다시 추가
            chunks.insertAll(0, remaining);
          }
        }
      }

      // 남은 데이터 인코딩
      if (chunks.isNotEmpty) {
        buffer.write(base64Encode(chunks));
      }

      return buffer.toString();
    } catch (e, stackTrace) {
      Logger.error('Failed to stream encode image', e, stackTrace);
      rethrow;
    }
  }

  /// 텍스트 파일 처리 (크기 제한 + 캐싱 + 스트리밍 적용)
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
        // 2. 캐시 미스: 파일 크기 확인
        final fileSize = await file.length();

        // ✅ 5MB 이상이면 스트리밍 방식 사용
        if (fileSize > 5 * 1024 * 1024) {
          Logger.info('[Attachment] Large text file detected (${fileSize ~/ 1024 ~/ 1024}MB), using streaming read: $fileName');
          fileContent = await _readTextFileStream(file);
        } else {
          // 작은 파일은 기존 방식
          fileContent = await file.readAsString();
        }

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

  /// ✅ 신규: 스트리밍 방식 텍스트 파일 읽기
  Future<String> _readTextFileStream(File file) async {
    final buffer = StringBuffer();
    final stream = file.openRead();
    int totalChars = 0;

    try {
      await for (final chunk in stream) {
        final text = String.fromCharCodes(chunk);
        buffer.write(text);
        totalChars += text.length;

        // 최대 문자 수 제한 (메모리 보호)
        if (totalChars > AppConstants.maxCharsPerTextFile * 2) {
          Logger.info('[Attachment] Stream read limit reached, stopping');
          break;
        }
      }

      return buffer.toString();
    } catch (e, stackTrace) {
      Logger.error('Failed to stream read text file', e, stackTrace);
      rethrow;
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
