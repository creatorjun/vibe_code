// lib/data/services/pipeline_service.dart
import '../../core/utils/logger.dart';
import '../../data/models/settings_state.dart';
import '../../data/models/api_request.dart';
import 'ai_service.dart';

/// 파이프라인 실행 서비스 (순차 실행)
class PipelineService {
  /// 순차 파이프라인 실행
  ///
  /// 1. 사용자 → Model1 → 응답1
  /// 2. (사용자 + 응답1) → Model2 → 응답2
  /// 3. (사용자 + 응답1 + 응답2) → Model3 → 응답3
  Stream<void> executePipeline({
    required List<ModelConfig> pipeline,
    required String initialInput,
    required List<ChatMessage> messageHistory,
    required Function(int step, ModelConfig config) onStepStart,
    required Function(int step, String chunk) onChunk,
    required AIService Function(String apiKey) aiServiceFactory,
    required String apiKey,
  }) async* {
    if (pipeline.isEmpty) {
      throw Exception('파이프라인이 비어있습니다.');
    }

    // 누적된 대화 히스토리
    final conversationHistory = <ChatMessage>[...messageHistory];

    // 사용자의 초기 질문
    conversationHistory.add(ChatMessage(
      role: 'user',
      content: initialInput,
    ));

    for (var i = 0; i < pipeline.length; i++) {
      final config = pipeline[i];

      Logger.info('Pipeline step ${i + 1}/${pipeline.length}: ${config.modelId}');
      onStepStart(i, config);

      // AI 서비스 생성
      final aiService = aiServiceFactory(apiKey);

      try {
        final stepOutput = StringBuffer();

        // 현재 모델에 누적된 히스토리 전달
        final messages = _buildMessages(
          messageHistory: conversationHistory,
          systemPrompt: config.systemPrompt,
        );

        // 스트리밍 실행
        await for (final chunk in aiService.streamChat(
          messages: messages,
          model: config.modelId,
        )) {
          stepOutput.write(chunk);
          onChunk(i, chunk);
        }

        final output = stepOutput.toString();

        if (output.isEmpty) {
          throw Exception('모델 ${config.modelId}의 출력이 비어있습니다.');
        }

        Logger.info('Step ${i + 1} completed: ${output.length} chars');

        // ✅ 응답을 히스토리에 추가 (다음 모델이 참조)
        conversationHistory.add(ChatMessage(
          role: 'assistant',
          content: output,
        ));

        // ✅ 마지막 모델이 아니면 다음 단계를 위한 사용자 메시지 추가
        if (i < pipeline.length - 1) {
          conversationHistory.add(ChatMessage(
            role: 'user',
            content: '위 내용을 바탕으로 계속 답변해주세요.',
          ));
        }

        yield null; // progress indicator용
      } catch (e, stackTrace) {
        Logger.error('Pipeline step ${i + 1} failed', e, stackTrace);
        rethrow;
      } finally {
        aiService.dispose();
      }
    }

    Logger.info('Pipeline execution completed');
  }

  /// 메시지 구성
  List<ChatMessage> _buildMessages({
    required List<ChatMessage> messageHistory,
    required String systemPrompt,
  }) {
    final messages = <ChatMessage>[];

    // 시스템 프롬프트
    if (systemPrompt.isNotEmpty) {
      messages.add(ChatMessage(
        role: 'system',
        content: systemPrompt,
      ));
    }

    // 누적된 대화 히스토리 전체
    messages.addAll(messageHistory);

    return messages;
  }

  /// 파이프라인 검증
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
