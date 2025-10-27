// lib/domain/mutations/send_message/attachment_processor.dart

import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';

import '../../../core/utils/logger.dart';
import '../../../data/repositories/attachment_repository.dart';

class AttachmentProcessor {
  final AttachmentRepository attachmentRepository;

  const AttachmentProcessor(this.attachmentRepository);

  /// 첨부파일을 이미지(Base64)와 텍스트로 분리 처리
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
            Logger.debug('[Attachment] MIME type: $mimeType for ${attachment.fileName}');

            if (mimeType != null && mimeType.startsWith('image/')) {
              // 이미지 파일: Base64 인코딩
              final bytes = await file.readAsBytes();
              final base64String = base64Encode(bytes);
              base64Images.add(base64String);
              Logger.info('[Attachment] Image encoded: ${attachment.fileName} (${bytes.length} bytes)');
            } else {
              // 텍스트 파일: 내용 읽기
              try {
                final fileContent = await file.readAsString();
                textAttachments.add('''
---
📎 첨부파일: ${attachment.fileName}
---
$fileContent
---
''');
                Logger.info('[Attachment] Text file loaded: ${attachment.fileName} (${fileContent.length} chars)');
              } catch (e) {
                Logger.warning('[Attachment] Failed to read as text: ${attachment.fileName}');
              }
            }
          }
        }
      } catch (e, stack) {
        Logger.error('[Attachment] Failed to load: $attachmentId', e, stack);
      }
    }

    return AttachmentResult(
      base64Images: base64Images,
      textAttachments: textAttachments,
    );
  }

  /// 텍스트 첨부파일을 메시지 내용에 결합
  String buildFullContent(String content, List<String> textAttachments) {
    if (textAttachments.isEmpty) {
      return content;
    }

    final fullContent = '''
$content

${textAttachments.join('\n')}
''';
    Logger.info('Full content with text attachments: ${fullContent.length} chars');
    return fullContent;
  }
}

class AttachmentResult {
  final List<String> base64Images;
  final List<String> textAttachments;

  const AttachmentResult({
    required this.base64Images,
    required this.textAttachments,
  });
}
