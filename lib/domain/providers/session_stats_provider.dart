// lib/domain/providers/session_stats_provider.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/token_counter.dart';
import 'chat_provider.dart';

/// 세션 통계 정보
class SessionStats {
  final int messageCount;
  final int estimatedTokens;

  const SessionStats({
    required this.messageCount,
    required this.estimatedTokens,
  });

  const SessionStats.empty()
      : messageCount = 0,
        estimatedTokens = 0;

  String get tokenDisplay => TokenCounter.formatTokenCount(estimatedTokens);
}

/// 현재 활성 세션의 통계 정보 (완료된 메시지만)
final activeSessionStatsProvider = StreamProvider<SessionStats>((ref) async* {
  final activeSessionId = ref.watch(activeSessionProvider);

  if (activeSessionId == null) {
    yield const SessionStats.empty();
    return;
  }

  // ✅ chatRepositoryProvider는 chatProvider에서 export됨
  final chatRepo = ref.watch(chatRepositoryProvider);
  final attachmentRepo = ref.watch(attachmentRepositoryProvider);

  // 완료된 메시지만 watch
  await for (final messages
  in chatRepo.watchCompletedMessagesForSession(activeSessionId)) {
    final messageCount = messages.length;

    // 토큰 계산
    int totalTokens = 0;

    for (final message in messages) {
      // 메시지 내용 토큰
      totalTokens += TokenCounter.estimateTokens(message.content);
      totalTokens += 4; // 메시지 오버헤드

      // 첨부파일 토큰
      try {
        final attachments =
        await attachmentRepo.getMessageAttachments(message.id);
        for (final attachment in attachments) {
          final file = File(attachment.filePath);
          if (await file.exists()) {
            final size = await file.length();
            totalTokens += TokenCounter.estimateTokensFromBytes(size);
          }
        }
      } catch (e) {
        // 첨부파일 로드 실패 시 무시
      }
    }

    yield SessionStats(
      messageCount: messageCount,
      estimatedTokens: totalTokens,
    );
  }
});
