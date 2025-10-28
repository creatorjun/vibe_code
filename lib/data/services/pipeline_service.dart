// lib/data/services/pipeline_service.dart

import '../../core/utils/logger.dart';
import '../../core/utils/token_counter.dart';
import '../../data/models/settings_state.dart';
import '../../data/models/api_request.dart';
import 'ai_service.dart';

class PipelineService {
  /// 순차 파이프라인 실행 (컨텍스트 압축 적용)
  Stream<void> executePipeline({
    required List<ModelConfig> pipeline,
    required String initialInput,
    required List<ChatMessage> messageHistory,
    required Function(int step, ModelConfig config) onStepStart,
    required Function(int step, String chunk) onChunk,
    required AIService Function(String apiKey) aiServiceFactory,
    required String apiKey,
    Function(int inputTokens, int outputTokens)? onTokenUsage,
  }) async* {
    if (pipeline.isEmpty) {
      throw Exception('파이프라인이 비어있습니다.');
    }

    // 누적된 대화 히스토리
    final conversationHistory = <ChatMessage>[...messageHistory];
    conversationHistory.add(ChatMessage(role: 'user', content: initialInput));

    for (var i = 0; i < pipeline.length; i++) {
      final config = pipeline[i];
      Logger.info('Pipeline step ${i + 1}/${pipeline.length}: ${config.modelId}');
      onStepStart(i, config);

      // AI 서비스 생성
      final aiService = aiServiceFactory(apiKey);

      try {
        final stepOutput = StringBuffer();

        // ✅ 중간 단계에서 히스토리 압축
        final compressedHistory = _compressHistoryForStep(
          conversationHistory,
          isFirstStep: i == 0,
          isLastStep: i == pipeline.length - 1,
        );

        // 시스템 프롬프트 포함한 메시지 구성
        final messages = _buildMessages(
          messageHistory: compressedHistory,
          systemPrompt: config.systemPrompt,
        );

        // 스트리밍 실행
        await for (final chunk in aiService.streamChat(
          messages: messages,
          model: config.modelId,
          onTokenUsage: onTokenUsage,
        )) {
          stepOutput.write(chunk);
          onChunk(i, chunk);
        }

        final output = stepOutput.toString();
        if (output.isEmpty) {
          throw Exception('${config.modelId} 모델에서 응답이 없습니다.');
        }

        Logger.info('Step ${i + 1} completed: ${output.length} chars');

        // 응답을 히스토리에 추가
        conversationHistory.add(ChatMessage(role: 'assistant', content: output));

        // 다음 단계가 있으면 계속 진행
        if (i < pipeline.length - 1) {
          conversationHistory.add(ChatMessage(
            role: 'user',
            content: '다음 단계로 진행해주세요.',
          ));
        }

        yield null; // 진행 상황 업데이트
      } finally {
        aiService.dispose();
      }
    }

    Logger.info('Pipeline execution completed');
  }

  /// ✅ 신규: 파이프라인 단계별 히스토리 압축
  List<ChatMessage> _compressHistoryForStep(
      List<ChatMessage> history, {
        required bool isFirstStep,
        required bool isLastStep,
      }) {
    // 첫 번째 단계: 전체 히스토리 사용
    if (isFirstStep) {
      Logger.debug('Step 1: Using full history (${history.length} messages)');
      return history;
    }

    // 마지막 단계: 최근 대화만 유지
    if (isLastStep && history.length > 10) {
      final compressed = history.sublist(history.length - 10);
      Logger.info(
        'Last step: Compressed history ${history.length} → ${compressed.length} messages',
      );
      return compressed;
    }

    // 중간 단계: 토큰 기반 압축
    if (history.length > 15) {
      return _compressHistoryByTokens(history, maxTokens: 4000);
    }

    // 히스토리가 짧으면 그대로 사용
    return history;
  }

  /// ✅ 신규: 토큰 기반 히스토리 압축
  List<ChatMessage> _compressHistoryByTokens(
      List<ChatMessage> history, {
        int maxTokens = 4000,
      }) {
    final compressed = <ChatMessage>[];
    var currentTokens = 0;

    // 최신 메시지부터 역순으로 추가
    for (var i = history.length - 1; i >= 0; i--) {
      final message = history[i];
      final content = message.content is String
          ? message.content as String
          : '';
      final msgTokens = TokenCounter.estimateTokens(content);

      if (currentTokens + msgTokens > maxTokens) {
        // 토큰 한계 도달: 요약 메시지 추가
        if (i > 0) {
          compressed.insert(0, ChatMessage(
            role: 'system',
            content: '[이전 대화 ${i + 1}개 메시지 요약됨]',
          ));
        }
        break;
      }

      compressed.insert(0, message);
      currentTokens += msgTokens;
    }

    Logger.info(
      'Token-based compression: ${history.length} → ${compressed.length} messages (~$currentTokens tokens)',
    );

    return compressed;
  }

  /// 메시지 히스토리 구성
  List<ChatMessage> _buildMessages({
    required List<ChatMessage> messageHistory,
    required String systemPrompt,
  }) {
    final messages = <ChatMessage>[];

    // 시스템 프롬프트가 있으면 추가
    if (systemPrompt.isNotEmpty) {
      messages.add(ChatMessage(
        role: 'system',
        content: systemPrompt,
      ));
    }

    // 기존 히스토리 추가
    messages.addAll(messageHistory);

    return messages;
  }

  /// 파이프라인 유효성 검사
  bool validatePipeline(List<ModelConfig> pipeline) {
    if (pipeline.isEmpty) {
      Logger.warning('Pipeline is empty');
      return false;
    }

    if (pipeline.length > 5) {
      Logger.warning('Pipeline exceeds maximum length of 5');
      return false;
    }

    for (var i = 0; i < pipeline.length; i++) {
      final config = pipeline[i];
      if (config.modelId.isEmpty) {
        Logger.warning('Model ID is empty at index $i');
        return false;
      }
    }

    return true;
  }
}
