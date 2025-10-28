import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/logger.dart';
import 'chat_provider.dart';

class SessionStats {
  final int messageCount;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;

  const SessionStats({
    required this.messageCount,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
  });

  const SessionStats.empty()
      : messageCount = 0,
        inputTokens = 0,
        outputTokens = 0,
        totalTokens = 0;

  String get tokenDisplay {
    if (totalTokens < 1000) {
      return '$totalTokens';
    } else if (totalTokens < 1000000) {
      final k = (totalTokens / 1000).toStringAsFixed(1);
      return '${k}K';
    } else {
      final m = (totalTokens / 1000000).toStringAsFixed(1);
      return '${m}M';
    }
  }
}

// ✅ 최적화 5: DB 집계 쿼리 사용 (메시지 전체 로드하지 않음)
final activeSessionStatsProvider = StreamProvider<SessionStats>((ref) async* {
  final activeSessionId = ref.watch(activeSessionProvider);

  if (activeSessionId == null) {
    yield const SessionStats.empty();
    return;
  }

  final chatRepo = ref.watch(chatRepositoryProvider);

  // ✅ DB 레벨에서 집계된 결과만 가져오기
  await for (final _ in chatRepo.watchCompletedMessagesForSession(activeSessionId)) {
    try {
      // 메시지 개수만 카운트
      final messageCount = await chatRepo.database.chatDao
          .getSessionMessageCount(activeSessionId);

      // 토큰 사용량만 집계
      final tokenUsage = await chatRepo.database.chatDao
          .getSessionTokenUsage(activeSessionId);

      yield SessionStats(
        messageCount: messageCount,
        inputTokens: tokenUsage.inputTokens,
        outputTokens: tokenUsage.outputTokens,
        totalTokens: tokenUsage.totalTokens,
      );

      Logger.debug('SessionStats - Session: $activeSessionId - '
          'Messages: $messageCount, '
          'Input: ${tokenUsage.inputTokens}, '
          'Output: ${tokenUsage.outputTokens}, '
          'Total: ${tokenUsage.totalTokens}');
    } catch (e) {
      Logger.error('SessionStats: Failed to load stats', e);
      yield const SessionStats.empty();
    }
  }
});
