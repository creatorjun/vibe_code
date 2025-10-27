// lib/domain/mutations/send_message_mutation.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vibe_code/core/errors/app_exception.dart';
import 'package:vibe_code/core/errors/error_handler.dart';
import 'package:vibe_code/core/utils/logger.dart';
import 'package:vibe_code/core/utils/token_counter.dart';
import 'package:vibe_code/core/utils/validators.dart';
import 'package:vibe_code/domain/providers/ai_service_provider.dart';
import 'package:vibe_code/domain/providers/chat_provider.dart';
import 'package:vibe_code/domain/providers/settings_provider.dart';
import 'package:vibe_code/domain/providers/streaming_state_provider.dart';
import 'package:vibe_code/domain/providers/selected_model_count_provider.dart';
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
    int totalInputTokens = 0;
    int totalOutputTokens = 0;

    try {
      // 1. 리포지토리 및 설정 초기화
      final chatRepo = ref.read(chatRepositoryProvider);
      final attachmentRepo = ref.read(attachmentRepositoryProvider);
      final settingsAsync = await ref.read(settingsProvider.future);

      // 2. API 키 검증
      _validateApiKey(settingsAsync.apiKey);

      // 3. 사용자 메시지 추가
      final userMessageTokens = TokenCounter.estimateTokens(content);
      userMessageId = await chatRepo.addUserMessage(
        sessionId: sessionId,
        content: content,
        inputTokens: userMessageTokens,
      );

      // 4. 첨부파일 링크
      if (attachmentIds.isNotEmpty) {
        await attachmentRepo.linkToMessage(
          messageId: userMessageId,
          attachmentIds: attachmentIds,
        );
      }

      // 5. 첨부파일 처리
      final attachmentProcessor = AttachmentProcessor(attachmentRepo);
      final attachmentResult = await attachmentProcessor.processAttachments(attachmentIds);
      final fullContent = attachmentProcessor.buildFullContent(
        content,
        attachmentResult.textAttachments,
      );

      // 6. 메시지 히스토리 구성
      final messageHistoryBuilder = MessageHistoryBuilder(chatRepo);
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

      // 8. AI 응답 메시지 생성
      final modelId = pipelineConfigurator.getFirstModelId(activePipelineConfigs);
      aiMessageId = await chatRepo.addAiMessage(
        sessionId: sessionId,
        model: modelId,
        isStreaming: true,
      );

      // 9. 스트리밍 상태 시작
      ref.read(streamingStateProvider.notifier).start();
      ref.read(currentStreamingMessageProvider.notifier).set(aiMessageId);
      state = const SendMessageState.streaming(progress: 0.0);

      // 10. 파이프라인 실행
      final responseBuffer = StringBuffer();
      final pipelineService = ref.read(pipelineServiceProvider);

      await for (final _ in pipelineService.executePipeline(
        pipeline: activePipelineConfigs,
        initialInput: fullContent,
        messageHistory: apiMessages.sublist(0, apiMessages.length - 1),
        onStepStart: (step, config) {
          Logger.info(
              'Pipeline step ${step + 1}/${activePipelineConfigs.length}: ${config.modelId}');
          state = SendMessageState.streaming(
              progress: step / activePipelineConfigs.length);
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
      )) {
        // Progress tracking
      }

      // 11. 토큰 추정 및 스트리밍 완료
      final finalResponse = responseBuffer.toString();
      totalInputTokens = TokenCounter.estimateTokens(fullContent);
      totalOutputTokens = TokenCounter.estimateTokens(finalResponse);
      Logger.info(
          'Estimated tokens - Input: $totalInputTokens, Output: $totalOutputTokens');

      await chatRepo.completeStreaming(
        aiMessageId,
        inputTokens: totalInputTokens,
        outputTokens: totalOutputTokens,
      );

      ref.read(streamingStateProvider.notifier).stop();
      ref.read(currentStreamingMessageProvider.notifier).clear();

      // 12. 세션 제목 업데이트
      final sessionManager = SessionManager(chatRepo);
      await sessionManager.updateSessionTitleIfNeeded(sessionId, content);

      state = const SendMessageState.success();
      Logger.info(
          'Message sent successfully with tokens: input=$totalInputTokens, output=$totalOutputTokens');
    } on SocketException catch (e) {
      Logger.error('Network error', e);
      state = const SendMessageState.error('네트워크 연결 오류: 인터넷 연결을 확인해주세요');
      await _handleError(sessionId, userMessageId, aiMessageId);
    } on HttpException catch (e) {
      Logger.error('HTTP error', e);
      state = SendMessageState.error('HTTP 오류: ${e.message}');
      await _handleError(sessionId, userMessageId, aiMessageId);
    } on TimeoutException catch (e) {
      Logger.error('Timeout error', e);
      state = const SendMessageState.error('요청 시간 초과: 다시 시도해주세요');
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
      Logger.error('Unexpected error during message send', e, stackTrace);
      ErrorHandler.logError(e, stackTrace);
      final errorMessage = ErrorHandler.getErrorMessage(e);
      state = SendMessageState.error(errorMessage);

      if (aiMessageId != null) {
        final chatRepo = ref.read(chatRepositoryProvider);
        final errorHandler = SendMessageErrorHandler(chatRepo);
        await errorHandler.appendErrorToMessage(sessionId, aiMessageId, errorMessage);
      }
    } finally {
      ref.read(streamingStateProvider.notifier).stop();
      ref.read(currentStreamingMessageProvider.notifier).clear();
    }
  }

  void _validateApiKey(String apiKey) {
    if (apiKey.isEmpty) {
      throw const ValidationException(
        'API 키를 설정해주세요. 설정 화면에서 API 키를 입력해주세요.',
      );
    }
    if (!Validators.isValidApiKey(apiKey)) {
      throw const ValidationException('올바르지 않은 API 키 형식입니다.');
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
    Logger.info('Cancelling message send');
    ref.read(streamingStateProvider.notifier).stop();
    ref.read(currentStreamingMessageProvider.notifier).clear();
    state = const SendMessageState.idle();
  }
}

final sendMessageMutationProvider =
NotifierProvider<SendMessageMutationNotifier, SendMessageState>(
  SendMessageMutationNotifier.new,
);
