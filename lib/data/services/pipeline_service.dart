// lib/data/services/pipeline_service.dart
import '../../core/utils/logger.dart';
import '../../data/models/settings_state.dart';
import '../../data/models/api_request.dart';
import 'ai_service.dart';

/// 모델 파이프라인 실행 결과
class PipelineStepResult {
  final int stepIndex;
  final ModelConfig config;
  final String output;
  final DateTime timestamp;

  PipelineStepResult({
    required this.stepIndex,
    required this.config,
    required this.output,
    required this.timestamp,
  });
}

/// AI 모델 파이프라인 실행 서비스
class PipelineService {
  final String apiKey;
  final AIService Function(String apiKey) aiServiceFactory;

  PipelineService({
    required this.apiKey,
    required this.aiServiceFactory,
  });

  /// 파이프라인 실행 (스트리밍 방식)
  ///
  /// [pipeline]: 실행할 모델 설정 리스트
  /// [initialInput]: 첫 번째 모델에 입력할 초기 메시지
  /// [messageHistory]: 이전 대화 히스토리
  /// [onStepStart]: 각 단계 시작 시 호출되는 콜백
  /// [onChunk]: 스트리밍 청크 수신 시 호출되는 콜백
  Stream<String> executePipeline({
    required List<ModelConfig> pipeline,
    required String initialInput,
    required List<ChatMessage> messageHistory,
    void Function(int step, ModelConfig config)? onStepStart,
    void Function(int step, String chunk)? onChunk,
  }) async* {
    if (pipeline.isEmpty) {
      throw Exception('파이프라인이 비어있습니다.');
    }

    Logger.info('Starting pipeline execution with ${pipeline.length} models');

    String currentInput = initialInput;
    final stepOutputs = <String>[];

    for (var i = 0; i < pipeline.length; i++) {
      final config = pipeline[i];

      Logger.info(
        'Pipeline step ${i + 1}/${pipeline.length}: ${config.modelId}',
      );

      onStepStart?.call(i, config);

      // 메시지 구성
      final messages = _buildMessages(
        messageHistory: messageHistory,
        systemPrompt: config.systemPrompt,
        userInput: currentInput,
      );

      // AI 서비스 생성
      final aiService = aiServiceFactory(apiKey);

      try {
        final stepBuffer = StringBuffer();

        // 스트리밍 실행
        await for (final chunk in aiService.streamChat(
          messages: messages,
          model: config.modelId,
        )) {
          stepBuffer.write(chunk);

          // 청크 콜백 호출
          onChunk?.call(i, chunk);

          // 스트림으로 청크 전달
          yield chunk;
        }

        final stepOutput = stepBuffer.toString();

        if (stepOutput.isEmpty) {
          throw Exception('모델 ${config.modelId}의 출력이 비어있습니다.');
        }

        Logger.info('Pipeline step ${i + 1} completed: ${stepOutput.length} chars');

        stepOutputs.add(stepOutput);

        // 다음 단계를 위해 출력을 입력으로 사용
        currentInput = stepOutput;
      } catch (e, stackTrace) {
        Logger.error('Pipeline step ${i + 1} failed', e, stackTrace);
        rethrow;
      } finally {
        aiService.dispose();
      }
    }

    Logger.info('Pipeline execution completed successfully');
  }

  /// 메시지 히스토리 구성
  List<ChatMessage> _buildMessages({
    required List<ChatMessage> messageHistory,
    required String systemPrompt,
    required String userInput,
  }) {
    final messages = <ChatMessage>[];

    // 시스템 프롬프트 추가
    if (systemPrompt.isNotEmpty) {
      messages.add(ChatMessage(
        role: 'system',
        content: systemPrompt,
      ));
    }

    // 기존 히스토리 추가
    messages.addAll(messageHistory);

    // 현재 사용자 입력 추가
    messages.add(ChatMessage(
      role: 'user',
      content: userInput,
    ));

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
