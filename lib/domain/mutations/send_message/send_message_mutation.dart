// lib/domain/mutations/send_message/send_message_mutation.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/token_counter.dart';
import '../../../core/utils/validators.dart';
import '../../providers/chat_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/streaming_state_provider.dart';
import '../../providers/selected_model_count_provider.dart';
import '../../providers/ai_service_provider.dart';
import 'send_message_state.dart';
import 'attachment_processor.dart';
import 'message_history_builder.dart';
import 'pipeline_configurator.dart';
import 'session_manager.dart';
import 'send_message_error_handler.dart';

export 'send_message_state.dart';

class SendMessageMutationNotifier extends Notifier<SendMessageState> {
  @override
  SendMessageState build() {
    return const SendMessageState.idle();
  }

  Future<void> sendMessage({
    required int sessionId,
    required String content,
    List<String> attachmentIds = const [],
  }) async {
    state = const SendMessageState.sending();
    int? userMessageId;
    int? aiMessageId;

    // ✅ 실제 API 토큰 수 저장용
    int? actualInputTokens;
    int? actualOutputTokens;

    try {
      // 1. 리포지토리 및 설정 초기화
      final chatRepo = ref.read(chatRepositoryProvider);
      final attachmentRepo = ref.read(attachmentRepositoryProvider);
      final settingsAsync = await ref.read(settingsProvider.future);

      // 2. API 키 검증
      _validateApiKey(settingsAsync.apiKey);

      // ✅ 개선: 첫 메시지인지 확인 (사용자 메시지 저장 전)
      final messages = await chatRepo.getMessages(sessionId);
      final isFirstMessage = messages.isEmpty;

      // 3. 사용자 메시지 저장
      final userMessageTokens = TokenCounter.estimateTokens(content);
      userMessageId = await chatRepo.addUserMessage(
        sessionId: sessionId,
        content: content,
        inputTokens: userMessageTokens,
      );

      // ✅ 개선: 첫 메시지 전송 시 즉시 제목 업데이트
      if (isFirstMessage) {
        final sessionManager = SessionManager(chatRepo);
        await sessionManager.updateSessionTitleIfNeeded(
          sessionId,
          _generateTitleFromContent(content),
        );
        Logger.info('✨ Session title updated on first message');
      }

      // 4. 첨부 파일 연결
      if (attachmentIds.isNotEmpty) {
        await attachmentRepo.linkToMessage(
          messageId: userMessageId,
          attachmentIds: attachmentIds,
        );
      }

      // 5. 첨부 파일 처리
      final attachmentProcessor = AttachmentProcessor(attachmentRepo);
      final attachmentResult = await attachmentProcessor.processAttachments(attachmentIds);
      final fullContent = attachmentProcessor.buildFullContent(
        content,
        attachmentResult.textAttachments,
      );

      // 6. 메시지 히스토리 구성
      final messageHistoryBuilder = MessageHistoryBuilder(
        chatRepo,
        maxHistoryMessages: settingsAsync.maxHistoryMessages,
      );
      final apiMessages = await messageHistoryBuilder.buildMessageHistory(sessionId);
      messageHistoryBuilder.addCurrentUserMessage(
        apiMessages: apiMessages,
        fullContent: fullContent,
        base64Images: attachmentResult.base64Images,
      );

      // 7. 파이프라인 구성
      final pipelineConfigurator = PipelineConfigurator();
      final selectedDepth = ref.read(selectedPipelineDepthProvider);
      final activePipelineConfigs = pipelineConfigurator.configurePipeline(
        fullPipelineConfigs: settingsAsync.modelPipeline,
        selectedDepth: selectedDepth,
        selectedPreset: settingsAsync.selectedPreset,
      );

      // 8. AI 메시지 생성
      final modelId = pipelineConfigurator.getFirstModelId(activePipelineConfigs);
      aiMessageId = await chatRepo.addAiMessage(
        sessionId: sessionId,
        model: modelId,
        isStreaming: true,
      );

      // 9. 스트리밍 시작
      ref.read(streamingStateProvider.notifier).start();
      ref.read(currentStreamingMessageProvider.notifier).set(aiMessageId);
      state = const SendMessageState.streaming(progress: 0.0);

      try {
        // 10. 파이프라인 실행
        final responseBuffer = StringBuffer();
        final pipelineService = ref.read(pipelineServiceProvider);

        await for (final _ in pipelineService.executePipeline(
          pipeline: activePipelineConfigs,
          initialInput: fullContent,
          messageHistory: apiMessages.sublist(0, apiMessages.length - 1),
          onStepStart: (step, config) {
            Logger.info('📍 Pipeline step ${step + 1}/${activePipelineConfigs.length}: ${config.modelId}');
            state = SendMessageState.streaming(
              progress: (step / activePipelineConfigs.length),
            );
          },
          onChunk: (step, chunk) async {
            responseBuffer.write(chunk);
            await chatRepo.updateMessageContent(
              aiMessageId!,
              responseBuffer.toString(),
            );
          },
          aiServiceFactory: ref.read(aiServiceFactoryProvider),
          apiKey: settingsAsync.apiKey,
          // ✅ 토큰 사용량 콜백
          onTokenUsage: (inputTokens, outputTokens) {
            actualInputTokens = inputTokens;
            actualOutputTokens = outputTokens;
            Logger.info('💰 Actual API tokens: input=$inputTokens, output=$outputTokens');
          },
        )) {}

        // 11. 최종 응답 처리
        final finalResponse = responseBuffer.toString();

        // ✅ 실제 API 토큰 수가 있으면 사용, 없으면 추정값 사용
        final totalInputTokens = actualInputTokens ?? TokenCounter.estimateTokens(fullContent);
        final totalOutputTokens = actualOutputTokens ?? TokenCounter.estimateTokens(finalResponse);

        // ✅ 로그만 조건부로 출력
        if (actualInputTokens != null) {
          Logger.info('✅ Using actual API tokens: input=$totalInputTokens, output=$totalOutputTokens');
        } else {
          Logger.info('📊 Using estimated tokens: input=$totalInputTokens, output=$totalOutputTokens');
        }

        await chatRepo.completeStreaming(
          aiMessageId,
          inputTokens: totalInputTokens,
          outputTokens: totalOutputTokens,
        );

        ref.read(streamingStateProvider.notifier).stop();
        ref.read(currentStreamingMessageProvider.notifier).clear();

        state = const SendMessageState.success();
        Logger.info('✅ Message sent successfully');
      } catch (e, stackTrace) {
        Logger.error('Error during streaming', e, stackTrace);
        final errorMessage = ErrorHandler.getErrorMessage(e);
        state = SendMessageState.error(errorMessage);

        // ✅ chatRepo 다시 읽기
        final chatRepo = ref.read(chatRepositoryProvider);
        final errorHandler = SendMessageErrorHandler(chatRepo);
        await errorHandler.appendErrorToMessage(sessionId, aiMessageId, errorMessage);
      } finally {
        ref.read(streamingStateProvider.notifier).stop();
        ref.read(currentStreamingMessageProvider.notifier).clear();
      }
    } on SocketException catch (e) {
      Logger.error('Network error', e);
      state = const SendMessageState.error('네트워크 연결을 확인해주세요');
      await _handleError(sessionId, userMessageId, aiMessageId);
    } on HttpException catch (e) {
      Logger.error('HTTP error', e);
      state = SendMessageState.error('HTTP 오류: ${e.message}');
      await _handleError(sessionId, userMessageId, aiMessageId);
    } on TimeoutException catch (e) {
      Logger.error('Timeout error', e);
      state = const SendMessageState.error('요청 시간이 초과되었습니다');
      await _handleError(sessionId, userMessageId, aiMessageId);
    } on ValidationException catch (e) {
      Logger.error('Validation error', e);
      state = SendMessageState.error(e.message);
      await _handleError(sessionId, userMessageId, aiMessageId);
    } on AppException catch (e) {
      Logger.error('App exception', e);
      state = SendMessageState.error(e.message);
      await _handleError(sessionId, userMessageId, aiMessageId);
    } catch (e, stackTrace) {
      Logger.error('Unexpected error', e, stackTrace);
      ErrorHandler.logError(e, stackTrace);
      final errorMessage = ErrorHandler.getErrorMessage(e);
      state = SendMessageState.error(errorMessage);

      // ✅ chatRepo 다시 읽기
      final chatRepo = ref.read(chatRepositoryProvider);
      if (aiMessageId != null) {
        final errorHandler = SendMessageErrorHandler(chatRepo);
        await errorHandler.appendErrorToMessage(sessionId, aiMessageId, errorMessage);
      }
    } finally {
      ref.read(streamingStateProvider.notifier).stop();
      ref.read(currentStreamingMessageProvider.notifier).clear();
    }
  }

  /// ✅ 새 메서드: 첫 30자로 제목 생성
  String _generateTitleFromContent(String content) {
    // 개행 문자 제거
    final cleanContent = content.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 30자로 제한
    if (cleanContent.length <= 30) {
      return cleanContent;
    }

    return '${cleanContent.substring(0, 30)}...';
  }

  void _validateApiKey(String apiKey) {
    if (!Validators.isValidApiKey(apiKey)) {
      throw const ValidationException(
        'API 키가 설정되지 않았습니다.\n설정 화면에서 API 키를 입력해주세요.',
      );
    }
  }

  Future<void> _handleError(
      int sessionId,
      int? userMessageId,
      int? aiMessageId,
      ) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final errorHandler = SendMessageErrorHandler(chatRepo);
    await errorHandler.handleError(sessionId, userMessageId, aiMessageId);
  }

  void cancel() {
    Logger.info('Streaming cancellation requested');
  }
}

final sendMessageMutationProvider =
NotifierProvider<SendMessageMutationNotifier, SendMessageState>(
  SendMessageMutationNotifier.new,
);
