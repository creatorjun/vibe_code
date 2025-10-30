// lib/domain/providers/attachment_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../core/utils/logger.dart';
import 'chat_provider.dart';

/// ✅ Riverpod 3.0 개선: autoDispose 추가
/// 첨부파일 Provider - 특정 첨부파일 ID로 첨부파일 정보를 가져옵니다.
///
/// 사용하지 않을 때 자동으로 메모리에서 해제되어 대용량 파일이나
/// 이미지 첨부파일의 메모리 누수를 방지합니다.
final attachmentProvider = FutureProvider.autoDispose.family<Attachment?, String>(
      (ref, String attachmentId) async {
    Logger.debug('Fetching attachment: $attachmentId');

    try {
      final repository = ref.watch(attachmentRepositoryProvider);
      final attachment = await repository.getAttachment(attachmentId);

      if (attachment == null) {
        Logger.warning('Attachment not found: $attachmentId');
      } else {
        Logger.debug('Attachment loaded: ${attachment.fileName} (${attachment.fileSize} bytes)');
      }

      return attachment;
    } catch (e, stack) {
      Logger.error('Failed to fetch attachment: $attachmentId', e, stack);

      // ✅ 에러를 다시 던져서 UI에서 AsyncValue.error로 처리 가능하게 함
      rethrow;
    }
  },
);

/// ✅ 추가 개선: 여러 첨부파일을 한 번에 가져오는 Provider (선택사항)
/// 메시지에 여러 첨부파일이 있을 때 효율적으로 로드
final attachmentsProvider = FutureProvider.autoDispose.family<List<Attachment>, List<String>>(
      (ref, List<String> attachmentIds) async {
    Logger.debug('Fetching ${attachmentIds.length} attachments');

    if (attachmentIds.isEmpty) {
      return [];
    }

    try {
      final repository = ref.watch(attachmentRepositoryProvider);

      // ✅ 병렬로 모든 첨부파일 로드 (성능 최적화)
      final attachmentFutures = attachmentIds.map(
            (id) => repository.getAttachment(id),
      );

      final attachments = await Future.wait(attachmentFutures);

      // null 제거 (삭제된 첨부파일 필터링)
      final validAttachments = attachments.whereType<Attachment>().toList();

      Logger.debug('Loaded ${validAttachments.length}/${attachmentIds.length} attachments');

      return validAttachments;
    } catch (e, stack) {
      Logger.error('Failed to fetch attachments', e, stack);
      rethrow;
    }
  },
);

/// ✅ 추가: 첨부파일 캐시 무효화 Provider (선택사항)
/// 첨부파일 업로드/삭제 후 캐시를 강제로 새로고침할 때 사용
class AttachmentCacheNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// 특정 첨부파일의 캐시 무효화
  void invalidate(String attachmentId) {
    Logger.debug('Invalidating attachment cache: $attachmentId');
    ref.invalidate(attachmentProvider(attachmentId));
    state++;
  }

  /// 모든 첨부파일 캐시 무효화
  void invalidateAll() {
    Logger.debug('Invalidating all attachment caches');
    ref.invalidate(attachmentProvider);
    state++;
  }
}

final attachmentCacheProvider = NotifierProvider<AttachmentCacheNotifier, int>(
  AttachmentCacheNotifier.new,
);
