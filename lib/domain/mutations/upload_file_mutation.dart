import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/logger.dart';
import '../providers/chat_provider.dart';

/// 파일 업로드 간단 함수
Future<String> uploadAttachmentFile(WidgetRef ref, String filePath) async {
  Logger.info('Uploading file: $filePath');

  final repository = ref.read(attachmentRepositoryProvider);
  final attachmentId = await repository.uploadFile(filePath);

  Logger.info('File uploaded successfully: $attachmentId');
  return attachmentId;
}
