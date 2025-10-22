import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/attachment_repository.dart';
import '../../data/services/file_service.dart';
import '../../core/utils/logger.dart';
import 'database_provider.dart';

/// 활성 세션 ID Provider (Riverpod 3.0)
class ActiveSessionNotifier extends Notifier<int?> {
  @override
  int? build() {
    Logger.info('Initializing active session provider');
    return null;
  }

  void select(int sessionId) {
    Logger.info('Selecting session: $sessionId');
    state = sessionId;
  }

  void clear() {
    Logger.info('Clearing active session');
    state = null;
  }
}

final activeSessionProvider = NotifierProvider<ActiveSessionNotifier, int?>(
  ActiveSessionNotifier.new,
);

/// ChatRepository Provider (원본 방식 유지)
final chatRepositoryProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return ChatRepository(db.chatDao);
});

/// AttachmentRepository Provider (원본 방식 유지)
final attachmentRepositoryProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  final fileService = FileService();
  return AttachmentRepository(db.attachmentDao, fileService);
});
