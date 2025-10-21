import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/attachment_repository.dart';
import '../../data/services/file_service.dart';
import '../../core/utils/logger.dart';
import 'database_provider.dart';

/// 현재 활성 세션 ID Provider
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

/// 채팅 Repository Provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ChatRepository(db.chatDao);
});

/// 첨부파일 Repository Provider
final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final fileService = FileService();
  return AttachmentRepository(db.attachmentDao, fileService);
});

/// 새 세션 생성 Provider
final sessionCreatorProvider = AsyncNotifierProvider<SessionCreatorNotifier, int?>(
  SessionCreatorNotifier.new,
);

class SessionCreatorNotifier extends AsyncNotifier<int?> {
  @override
  Future<int?> build() async {
    return null;
  }

  Future<int> createSession(String title) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(chatRepositoryProvider);
      final sessionId = await repository.createSession(title);

      Logger.info('Session created: $sessionId');

      // 새 세션을 활성 세션으로 설정
      ref.read(activeSessionProvider.notifier).select(sessionId);

      return sessionId;
    });

    return state.requireValue!;
  }
}

/// 세션 삭제 Provider
final sessionDeleterProvider = AsyncNotifierProvider<SessionDeleterNotifier, void>(
  SessionDeleterNotifier.new,
);

class SessionDeleterNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> deleteSession(int sessionId) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(chatRepositoryProvider);
      await repository.deleteSession(sessionId);

      Logger.info('Session deleted: $sessionId');

      // 삭제된 세션이 활성 세션이면 클리어
      final activeSession = ref.read(activeSessionProvider);
      if (activeSession == sessionId) {
        ref.read(activeSessionProvider.notifier).clear();
      }
    });
  }
}
