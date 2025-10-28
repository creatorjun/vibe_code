// lib/data/services/pipeline_service.dart

import '../../core/utils/logger.dart';
import '../../data/models/settings_state.dart';
import '../../data/models/api_request.dart';
import 'ai_service.dart';

class PipelineService {
  /// 순차 파이프라인 실행
  Stream<void> executePipeline({
    required List<ModelConfig> pipeline,
    required String initialInput,
    required List<ChatMessage> messageHistory,
    required Function(int step, ModelConfig config) onStepStart,
    required Function(int step, String chunk) onChunk,
    required AIService Function(String apiKey) aiServiceFactory,
    required String apiKey,
    Function(int inputTokens, int outputTokens)? onTokenUsage, // ✅ 신규 파라미터
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

        // 시스템 프롬프트 포함한 메시지 구성
        final messages = _buildMessages(
          messageHistory: conversationHistory,
          systemPrompt: config.systemPrompt,
        );

        // ✅ onTokenUsage 콜백 전달
        await for (final chunk in aiService.streamChat(
          messages: messages,
          model: config.modelId,
          onTokenUsage: onTokenUsage, // 파이프라인의 콜백 전달
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
