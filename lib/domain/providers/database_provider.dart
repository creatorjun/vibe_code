import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../core/utils/logger.dart';

// Database Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  Logger.info('Initializing database');
  final db = AppDatabase();

  ref.onDispose(() {
    Logger.info('Disposing database');
    db.close();
  });

  return db;
});

// ✅ 최적화 6: limit 파라미터 추가
final chatSessionsProvider = StreamProvider.autoDispose<List<ChatSession>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.chatDao.watchActiveSessions(limit: 100); // 최근 100개만
});

final sessionMessagesProvider =
StreamProvider.autoDispose.family<List<Message>, int>((ref, sessionId) {
  final db = ref.watch(databaseProvider);
  return db.chatDao.watchMessagesForSession(sessionId);
});

final sessionProvider =
StreamProvider.autoDispose.family<ChatSession?, int>((ref, sessionId) {
  final db = ref.watch(databaseProvider);
  return db.chatDao.watchSession(sessionId);
});
