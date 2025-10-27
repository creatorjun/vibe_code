// lib/domain/mutations/send_message_mutation.dart

import 'dart:async';  // ✅ 추가
import 'dart:convert';  // ✅ 추가
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';  // ✅ 추가

import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/token_counter.dart';
import '../../core/utils/validators.dart';
import '../../data/models/api_request.dart';
import '../../data/models/settings_state.dart';
import '../providers/ai_service_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/streaming_state_provider.dart';
import '../providers/selected_model_count_provider.dart';

enum SendMessageStatus {
  idle,
  sending,
  streaming,
  success,
  error,
}

class SendMessageState {
  final SendMessageStatus status;
  final String? error;
  final double? progress;

  const SendMessageState.idle()
      : status = SendMessageStatus.idle,
        error = null,
        progress = null;

  const SendMessageState.sending()
      : status = SendMessageStatus.sending,
        error = null,
        progress = null;

  const SendMessageState.streaming({this.progress})
      : status = SendMessageStatus.streaming,
        error = null;

  const SendMessageState.success()
      : status = SendMessageStatus.success,
        error = null,
        progress = null;

  const SendMessageState.error(String this.error)
      : status = SendMessageStatus.error,
        progress = null;
}

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
      final chatRepo = ref.read(chatRepositoryProvider);
      final attachmentRepo = ref.read(attachmentRepositoryProvider);
      final settingsAsync = await ref.read(settingsProvider.future);

      // API 키 검증
      if (settingsAsync.apiKey.isEmpty) {
        throw const ValidationException(
          'API 키를 설정해주세요. 설정 화면에서 API 키를 입력해주세요.',
        );
      }
      if (!Validators.isValidApiKey(settingsAsync.apiKey)) {
        throw const ValidationException('올바르지 않은 API 키 형식입니다.');
      }

      // 사용자 메시지 토큰 계산
      final userMessageTokens = TokenCounter.estimateTokens(content);

      // 사용자 메시지 추가
      userMessageId = await chatRepo.addUserMessage(
        sessionId: sessionId,
        content: content,
        inputTokens: userMessageTokens,
      );

      // 첨부파일 링크
      if (attachmentIds.isNotEmpty) {
        await attachmentRepo.linkToMessage(
          messageId: userMessageId,
          attachmentIds: attachmentIds,
        );
      }

      // ✅ 첨부파일 처리 (이미지 vs 텍스트 구분)
      final base64Images = <String>[];
      final textAttachments = <String>[];

      if (attachmentIds.isNotEmpty) {
        for (final attachmentId in attachmentIds) {
          try {
            final attachment = await attachmentRepo.getAttachment(attachmentId);
            if (attachment != null) {
              final file = File(attachment.filePath);

              if (await file.exists()) {
                // ✅ MIME 타입 확인
                final mimeType = lookupMimeType(attachment.filePath);
                Logger.debug('[Attachment] MIME type: $mimeType for ${attachment.fileName}');

                if (mimeType != null && mimeType.startsWith('image/')) {
                  // ✅ 이미지 파일: Base64 인코딩
                  final bytes = await file.readAsBytes();
                  final base64String = base64Encode(bytes);
                  base64Images.add(base64String);
                  Logger.info('[Attachment] Image encoded: ${attachment.fileName} (${bytes.length} bytes)');
                } else {
                  // ✅ 텍스트 파일: 내용 읽기
                  try {
                    final fileContent = await file.readAsString();
                    textAttachments.add('''
---
📎 첨부파일: ${attachment.fileName}
---
$fileContent
---
''');
                    Logger.info('[Attachment] Text file loaded: ${attachment.fileName} (${fileContent.length} chars)');
                  } catch (e) {
                    Logger.warning('[Attachment] Failed to read as text: ${attachment.fileName}');
                  }
                }
              }
            }
          } catch (e, stack) {
            Logger.error('[Attachment] Failed to load: $attachmentId', e, stack);
          }
        }
      }

      // ✅ 전체 메시지 구성
      String fullContent = content;
      if (textAttachments.isNotEmpty) {
        fullContent = '''
$content

${textAttachments.join('\n')}
''';
        Logger.info('Full content with text attachments: ${fullContent.length} chars');
      }

      // 메시지 히스토리 구성
      final apiMessages = await _buildMessageHistory(sessionId, settingsAsync);

      // ✅ 현재 사용자 메시지 추가 (Vision API 지원)
      if (base64Images.isNotEmpty) {
        // ✅ 이미지가 있는 경우: Vision API 형식
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

      // 파이프라인 구성
      final selectedDepth = ref.read(selectedPipelineDepthProvider);
      final fullPipelineConfigs = settingsAsync.modelPipeline;
      List<ModelConfig> activePipelineConfigs =
      fullPipelineConfigs.take(selectedDepth).toList();

      // 프리셋 적용
      final selectedPreset = settingsAsync.selectedPreset;
      if (selectedPreset != null) {
        Logger.info('Applying preset "${selectedPreset.name}" to the pipeline.');
        List<ModelConfig> pipelineWithPresetPrompts = [];
        for (int i = 0; i < activePipelineConfigs.length; i++) {
          final config = activePipelineConfigs[i];
          final prompt = (i < selectedPreset.prompts.length)
              ? selectedPreset.prompts[i]
              : '';
          pipelineWithPresetPrompts.add(config.copyWith(systemPrompt: prompt));
          Logger.debug(
              '  Step ${i + 1}: Model=${config.modelId}, Prompt=${prompt.isNotEmpty ? "[Preset Prompt]" : "[Empty]"}');
        }
        activePipelineConfigs = pipelineWithPresetPrompts;
      } else {
        Logger.info('No preset selected, using manually configured prompts.');
        for (int i = 0; i < activePipelineConfigs.length; i++) {
          final config = activePipelineConfigs[i];
          Logger.debug(
              '  Step ${i + 1}: Model=${config.modelId}, Prompt=${config.systemPrompt.isNotEmpty ? "[Manual Prompt]" : "[Empty]"}');
        }
      }

      Logger.info('Using ${activePipelineConfigs.length} models (depth: $selectedDepth)');

      // AI 응답 메시지 생성
      final modelId = activePipelineConfigs.isNotEmpty
          ? activePipelineConfigs.first.modelId
          : 'anthropic/claude-3.5-sonnet';

      aiMessageId = await chatRepo.addAiMessage(
        sessionId: sessionId,
        model: modelId,
        isStreaming: true,
      );

      // 스트리밍 상태 시작
      ref.read(streamingStateProvider.notifier).start();
      ref.read(currentStreamingMessageProvider.notifier).set(aiMessageId);
      state = const SendMessageState.streaming(progress: 0.0);

      final responseBuffer = StringBuffer();

      // PipelineService를 통한 파이프라인 실행
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

      // 토큰 추정
      final finalResponse = responseBuffer.toString();
      totalInputTokens = TokenCounter.estimateTokens(fullContent);
      totalOutputTokens = TokenCounter.estimateTokens(finalResponse);
      Logger.info(
          'Estimated tokens - Input: $totalInputTokens, Output: $totalOutputTokens');

      // 스트리밍 완료
      await chatRepo.completeStreaming(
        aiMessageId,
        inputTokens: totalInputTokens,
        outputTokens: totalOutputTokens,
      );

      ref.read(streamingStateProvider.notifier).stop();
      ref.read(currentStreamingMessageProvider.notifier).clear();

      // 세션 제목 업데이트
      await _updateSessionTitleIfNeeded(sessionId, content);

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
        String existingContent = '';
        try {
          final messages = await chatRepo.getMessages(sessionId);
          final currentMessage = messages.firstWhere((m) => m.id == aiMessageId);
          existingContent = currentMessage.content;
        } catch (_) {}

        final errorContent = existingContent.trim().isNotEmpty
            ? '$existingContent\n\n⚠️ 파이프라인 오류\n\n$errorMessage'
            : '⚠️ 메시지 전송 실패\n\n$errorMessage';

        await chatRepo.updateMessageContent(aiMessageId, errorContent);
        await chatRepo.completeStreaming(aiMessageId);
        Logger.info(
            'Error message ${existingContent.isEmpty ? "saved" : "appended"} to database: $aiMessageId');
      }
    } finally {
      ref.read(streamingStateProvider.notifier).stop();
      ref.read(currentStreamingMessageProvider.notifier).clear();
    }
  }

  Future<void> _handleError(
      int sessionId,
      int? userMessageId,
      int? aiMessageId,
      ) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    if (aiMessageId != null) {
      try {
        await chatRepo.deleteMessage(aiMessageId);
        Logger.debug('Cleaned up AI message: $aiMessageId');
      } catch (e) {
        Logger.error('Failed to delete AI message', e);
      }
    }
  }

  void cancel() {
    Logger.info('Cancelling message send');
    ref.read(streamingStateProvider.notifier).stop();
    ref.read(currentStreamingMessageProvider.notifier).clear();
    state = const SendMessageState.idle();
  }

  Future<List<ChatMessage>> _buildMessageHistory(
      int sessionId,
      SettingsState settings,
      ) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final dbMessages = await chatRepo.getMessages(sessionId);
    return dbMessages.map((msg) {
      return ChatMessage.text(
        role: msg.role,
        text: msg.content,
      );
    }).toList();
  }

  Future<void> _updateSessionTitleIfNeeded(
      int sessionId,
      String content,
      ) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final session = await chatRepo.getSession(sessionId);
    if (session != null &&
        (session.title == '새로운 대화' || session.title.isEmpty)) {
      final title =
      content.length > 50 ? '${content.substring(0, 50)}...' : content;
      await chatRepo.updateSessionTitle(sessionId, title);
      Logger.info('Session title updated: $title');
    }
  }
}

final sendMessageMutationProvider =
NotifierProvider<SendMessageMutationNotifier, SendMessageState>(
  SendMessageMutationNotifier.new,
);
