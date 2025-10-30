// lib/domain/providers/chat_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/attachment_repository.dart';
import '../../data/services/file_service.dart';
import '../../core/utils/logger.dart';
import 'database_provider.dart';

/// ✅ Riverpod 3.0: 활성 세션 ID Provider
/// 현재 선택된 채팅 세션의 ID를 관리합니다.
class ActiveSessionNotifier extends Notifier<int?> {
  @override
  int? build() {
    Logger.info('Initializing active session provider');
    return null;
  }

  /// 세션 선택
  void select(int sessionId) {
    Logger.info('Selecting session: $sessionId');
    state = sessionId;
  }

  /// 세션 선택 해제
  void clear() {
    Logger.info('Clearing active session');
    state = null;
  }
}

final activeSessionProvider = NotifierProvider<ActiveSessionNotifier, int?>(
  ActiveSessionNotifier.new,
);

/// ✅ Riverpod 3.0 개선: autoDispose 추가
/// ChatRepository는 데이터베이스 연결을 유지하므로 사용하지 않을 때 자동 정리 필요
final chatRepositoryProvider = Provider.autoDispose<ChatRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final repository = ChatRepository(db.chatDao);

  Logger.debug('Creating ChatRepository');

  // ✅ 리소스 정리 (필요 시)
  ref.onDispose(() {
    Logger.debug('Disposing ChatRepository');
    // ChatRepository에 dispose 메서드가 있다면 호출
    // repository.dispose();
  });

  return repository;
});

/// ✅ Riverpod 3.0 개선: autoDispose 추가
/// AttachmentRepository는 파일 시스템 접근 및 FileService를 사용하므로 자동 정리 권장
final attachmentRepositoryProvider = Provider.autoDispose<AttachmentRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final fileService = FileService();
  final repository = AttachmentRepository(db.attachmentDao, fileService);

  Logger.debug('Creating AttachmentRepository with FileService');

  // ✅ FileService 리소스 정리
  ref.onDispose(() {
    Logger.debug('Disposing AttachmentRepository and FileService');
    // FileService에 dispose 메서드가 있다면 호출
    // fileService.dispose();
  });

  return repository;
});

/// ✅ Riverpod 3.0 권장: FileService Provider 분리 (재사용성 향상)
/// FileService를 별도 Provider로 분리하여 다른 곳에서도 사용 가능
final fileServiceProvider = Provider.autoDispose<FileService>((ref) {
  final service = FileService();

  Logger.debug('Creating FileService');

  ref.onDispose(() {
    Logger.debug('Disposing FileService');
    // FileService에 dispose 메서드가 있다면 호출
    // service.dispose();
  });

  return service;
});

/// ✅ 개선된 AttachmentRepository Provider (FileService 재사용)
final attachmentRepositoryProviderV2 = Provider.autoDispose<AttachmentRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final fileService = ref.watch(fileServiceProvider); // ✅ 재사용

  return AttachmentRepository(db.attachmentDao, fileService);
});
