// lib/domain/providers/database_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../core/utils/logger.dart';

/// Database Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  Logger.info('Initializing database');
  final db = AppDatabase();

  ref.onDispose(() {
    Logger.info('Disposing database');
    db.close();
  });

  return db;
});

/// 활성 세션 목록을 스트림으로 제공하는 Provider
final chatSessionsProvider = StreamProvider.autoDispose<List<ChatSession>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.chatDao.watchActiveSessions();
});

/// 특정 세션의 메시지 목록을 스트림으로 제공하는 Provider
final sessionMessagesProvider = StreamProvider.autoDispose.family<List<Message>, int>(
      (ref, sessionId) {
    final db = ref.watch(databaseProvider);
    return db.chatDao.watchMessagesForSession(sessionId);
  },
);

/// 특정 세션 정보를 스트림으로 제공하는 Provider (새로 추가)
final sessionProvider = StreamProvider.autoDispose.family<ChatSession?, int>(
      (ref, sessionId) {
    final db = ref.watch(databaseProvider);
    return db.chatDao.watchSession(sessionId);
  },
);
