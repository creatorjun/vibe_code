import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../core/utils/logger.dart';

/// 데이터베이스 싱글톤 Provider (수동 작성)
final databaseProvider = Provider<AppDatabase>((ref) {
  Logger.info('Initializing database');
  final db = AppDatabase();

  ref.onDispose(() {
    Logger.info('Disposing database');
    db.close();
  });

  return db;
});

/// 세션 목록 스트림 Provider (수동 작성)
final chatSessionsProvider = StreamProvider.autoDispose<List<ChatSession>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.chatDao.watchActiveSessions();
});

/// 특정 세션의 메시지 스트림 Provider (수동 작성)
final sessionMessagesProvider = StreamProvider.autoDispose.family<List<Message>, int>(
      (ref, sessionId) {
    final db = ref.watch(databaseProvider);
    return db.chatDao.watchMessagesForSession(sessionId);
  },
);
