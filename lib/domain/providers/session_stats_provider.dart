// lib/domain/providers/session_stats_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/logger.dart';
import 'chat_provider.dart';

/// 세션 통계
class SessionStats {
  final int messageCount;
  final int inputTokens;      // ===== 추가 =====
  final int outputTokens;     // ===== 추가 =====
  final int totalTokens;      // ===== 추가 =====

  const SessionStats({
    required this.messageCount,
    required this.inputTokens,      // ===== 추가 =====
    required this.outputTokens,     // ===== 추가 =====
    required this.totalTokens,      // ===== 추가 =====
  });

  const SessionStats.empty()
      : messageCount = 0,
        inputTokens = 0,      // ===== 추가 =====
        outputTokens = 0,     // ===== 추가 =====
        totalTokens = 0;      // ===== 추가 =====

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

/// 활성 세션의 통계를 스트림으로 제공
final activeSessionStatsProvider = StreamProvider<SessionStats>((ref) async* {
  final activeSessionId = ref.watch(activeSessionProvider);

  if (activeSessionId == null) {
    yield const SessionStats.empty();
    return;
  }

  final chatRepo = ref.watch(chatRepositoryProvider);

  // ===== 변경: DB에서 토큰 합계를 직접 조회 =====
  await for (final messages in chatRepo.watchCompletedMessagesForSession(activeSessionId)) {
    try {
      // 메시지 개수
      final messageCount = messages.length;

      // DB에서 토큰 사용량 조회
      final tokenUsage = await chatRepo.database.chatDao.getSessionTokenUsage(activeSessionId);

      yield SessionStats(
        messageCount: messageCount,
        inputTokens: tokenUsage.inputTokens,
        outputTokens: tokenUsage.outputTokens,
        totalTokens: tokenUsage.totalTokens,
      );

      Logger.debug(
        '[SessionStats] Session $activeSessionId - '
            'Messages: $messageCount, '
            'Input: ${tokenUsage.inputTokens}, '
            'Output: ${tokenUsage.outputTokens}, '
            'Total: ${tokenUsage.totalTokens}',
      );
    } catch (e) {
      Logger.error('[SessionStats] Failed to load stats', e);
      yield const SessionStats.empty();
    }
  }
  // ==============================================
});
