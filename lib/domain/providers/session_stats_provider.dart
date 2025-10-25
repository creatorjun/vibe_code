// lib/domain/providers/session_stats_provider.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/token_counter.dart';
import 'chat_provider.dart';

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

final activeSessionStatsProvider = StreamProvider<SessionStats>((ref) async* {
  final activeSessionId = ref.watch(activeSessionProvider);

  if (activeSessionId == null) {
    yield const SessionStats.empty();
    return;
  }

  // chatRepositoryProvider와 chatProvider를 export하고 있으므로 사용 가능
  final chatRepo = ref.watch(chatRepositoryProvider);
  final attachmentRepo = ref.watch(attachmentRepositoryProvider);

  // watch
  await for (final messages
  in chatRepo.watchCompletedMessagesForSession(activeSessionId)) {
    final messageCount = messages.length;
    int totalTokens = 0;

    // 메시지 내용 토큰 계산
    for (final message in messages) {
      totalTokens += TokenCounter.estimateTokens(message.content);
      totalTokens += 4; // 메시지당 기본 토큰
    }

    // 최적화: 모든 메시지의 첨부파일을 한 번에 처리
    if (messages.isNotEmpty) {
      try {
        // 모든 메시지의 첨부파일을 병렬로 가져오기
        final attachmentFutures = messages.map((message) async {
          try {
            final attachments = await attachmentRepo.getMessageAttachments(message.id);
            int attachmentTokens = 0;

            // 각 첨부파일의 토큰 계산
            for (final attachment in attachments) {
              try {
                final file = File(attachment.filePath);
                if (await file.exists()) {
                  final size = await file.length();
                  attachmentTokens += TokenCounter.estimateTokensFromBytes(size);
                }
              } catch (e) {
                // 개별 파일 오류는 무시
              }
            }

            return attachmentTokens;
          } catch (e) {
            // 메시지별 첨부파일 조회 오류는 무시
            return 0;
          }
        });

        // 모든 첨부파일 토큰 합산
        final attachmentTokensList = await Future.wait(attachmentFutures);
        totalTokens += attachmentTokensList.fold<int>(0, (sum, tokens) => sum + tokens);
      } catch (e) {
        // 전체 첨부파일 처리 오류는 무시
      }
    }

    yield SessionStats(
      messageCount: messageCount,
      estimatedTokens: totalTokens,
    );
  }
});
