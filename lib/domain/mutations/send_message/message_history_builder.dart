// lib/domain/mutations/send_message/message_history_builder.dart

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/token_counter.dart';
import '../../../data/models/api_request.dart';
import '../../../data/repositories/chat_repository.dart';

class MessageHistoryBuilder {
  final ChatRepository chatRepository;
  final int maxHistoryMessages;

  const MessageHistoryBuilder(
      this.chatRepository, {
        this.maxHistoryMessages = AppConstants.defaultMaxHistoryMessages,
      });

  /// DB에서 메시지 히스토리를 불러와 API 메시지 형식으로 변환
  /// ✅ 슬라이딩 윈도우 적용: 최근 N개 메시지만 선택
  Future<List<ChatMessage>> buildMessageHistory(int sessionId) async {
    final dbMessages = await chatRepository.getMessages(sessionId);

    // ✅ 최근 N개 메시지만 선택
    final recentMessages = dbMessages.length > maxHistoryMessages
        ? dbMessages.sublist(dbMessages.length - maxHistoryMessages)
        : dbMessages;

    Logger.info(
      'Message history: Selected ${recentMessages.length}/${dbMessages.length} messages (limit: $maxHistoryMessages)',
    );

    return recentMessages.map((msg) {
      return ChatMessage.text(
        role: msg.role,
        text: msg.content,
      );
    }).toList();
  }

  /// ✅ 신규: 토큰 기반 히스토리 구성 (향후 확장 가능)
  Future<List<ChatMessage>> buildMessageHistoryWithTokenLimit(
      int sessionId, {
        int maxTokens = AppConstants.maxHistoryTokens,
      }) async {
    final dbMessages = await chatRepository.getMessages(sessionId);
    final selected = <ChatMessage>[];
    var currentTokens = 0;

    // 최신 메시지부터 역순으로 추가
    for (var i = dbMessages.length - 1; i >= 0; i--) {
      final msg = dbMessages[i];
      final msgTokens = TokenCounter.estimateTokens(msg.content);

      if (currentTokens + msgTokens > maxTokens) {
        Logger.info('Token limit reached at message ${dbMessages.length - i}');
        break;
      }

      selected.insert(0, ChatMessage.text(
        role: msg.role,
        text: msg.content,
      ));
      currentTokens += msgTokens;
    }

    Logger.info(
      'Message history (token-based): Selected ${selected.length}/${dbMessages.length} messages, ~$currentTokens tokens',
    );

    return selected;
  }

  /// 현재 사용자 메시지를 API 메시지 형식으로 추가
  void addCurrentUserMessage({
    required List<ChatMessage> apiMessages,
    required String fullContent,
    required List<String> base64Images,
  }) {
    if (base64Images.isNotEmpty) {
      // 이미지가 있는 경우: Vision API 형식
      apiMessages.add(ChatMessage.withImages(
        role: 'user',
        text: fullContent.isEmpty ? '이미지를 분석해주세요' : fullContent,
        base64Images: base64Images,
      ));
      Logger.info('[Vision API] Sending ${base64Images.length} image(s) with message');
    } else {
      // 텍스트만 있는 경우
      apiMessages.add(ChatMessage.text(
        role: 'user',
        text: fullContent,
      ));
    }
  }
}
