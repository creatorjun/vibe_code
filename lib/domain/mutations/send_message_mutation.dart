// lib/domain/mutations/send_message_mutation.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/validators.dart';
import '../../data/models/api_request.dart';
import '../../data/services/openrouter_service.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/streaming_state_provider.dart';

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
  final int? currentModelIndex;

  const SendMessageState({
    required this.status,
    this.error,
    this.progress,
    this.currentModelIndex,
  });

  const SendMessageState.idle()
      : status = SendMessageStatus.idle,
        error = null,
        progress = null,
        currentModelIndex = null;

  const SendMessageState.sending()
      : status = SendMessageStatus.sending,
        error = null,
        progress = null,
        currentModelIndex = null;

  const SendMessageState.streaming({
    this.progress,
    this.currentModelIndex,
  })  : status = SendMessageStatus.streaming,
        error = null;

  const SendMessageState.success()
      : status = SendMessageStatus.success,
        error = null,
        progress = null,
        currentModelIndex = null;

  const SendMessageState.error(String this.error)
      : status = SendMessageStatus.error,
        progress = null,
        currentModelIndex = null;
}

class SendMessageMutationNotifier extends Notifier<SendMessageState> {
  OpenRouterService? _activeService;

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

    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      final attachmentRepo = ref.read(attachmentRepositoryProvider);
      final settingsAsync = await ref.read(settingsProvider.future);

      // API 키 검증
      if (settingsAsync.apiKey.isEmpty) {
        throw const ValidationException('API 키를 설정해주세요. 설정 화면에서 API 키를 입력해주세요.');
      }

      if (!Validators.isValidApiKey(settingsAsync.apiKey)) {
        throw const ValidationException('올바르지 않은 API 키 형식입니다.');
      }

      // 활성화된 모델 파이프라인 가져오기
      final pipeline = settingsAsync.enabledModels;
      if (pipeline.isEmpty) {
        throw const ValidationException('최소 1개의 모델을 활성화해주세요.');
      }

      // 사용자 메시지 추가
      final userMessageId = await chatRepo.addUserMessage(
        sessionId: sessionId,
        content: content,
      );

      // 첨부파일 링크
      if (attachmentIds.isNotEmpty) {
        await attachmentRepo.linkToMessage(
          messageId: userMessageId,
          attachmentIds: attachmentIds,
        );
      }

      // 파이프라인 실행
      String currentInput = content;

      for (var i = 0; i < pipeline.length; i++) {
        final modelConfig = pipeline[i];

        state = SendMessageState.streaming(
          currentModelIndex: i,
          progress: (i / pipeline.length),
        );

        Logger.info('Pipeline step ${i + 1}/${pipeline.length}: ${modelConfig.modelId}');

        // 메시지 히스토리 구성
        final messages = await _buildMessageHistory(
          sessionId: sessionId,
          userMessage: currentInput,
          systemPrompt: modelConfig.systemPrompt,
        );

        // AI 메시지 생성 (스트리밍)
        final aiMessageId = await chatRepo.addAssistantMessage(
          sessionId: sessionId,
          model: modelConfig.modelId,
          isStreaming: true,
        );

        ref.read(streamingStateProvider.notifier).start();
        ref.read(currentStreamingMessageProvider.notifier).set(aiMessageId);

        _activeService = OpenRouterService(settingsAsync.apiKey);
        final contentBuffer = StringBuffer();

        try {
          await for (final chunk in _activeService!.streamChat(
            messages: messages,
            model: modelConfig.modelId,
          )) {
            contentBuffer.write(chunk);
            await chatRepo.updateMessageContent(aiMessageId, contentBuffer.toString());
          }

          await chatRepo.completeStreaming(aiMessageId);

          // 다음 파이프라인을 위해 현재 출력을 입력으로 사용
          currentInput = contentBuffer.toString();

          Logger.info('Pipeline step ${i + 1} completed');
        } catch (e, stackTrace) {
          Logger.error('Pipeline step ${i + 1} failed', e, stackTrace);
          await chatRepo.deleteMessage(aiMessageId);
          rethrow;
        } finally {
          _activeService?.dispose();
          _activeService = null;
          ref.read(streamingStateProvider.notifier).stop();
          ref.read(currentStreamingMessageProvider.notifier).clear();
        }
      }

      // 세션 제목 업데이트
      await _updateSessionTitleIfNeeded(sessionId, content);

      state = const SendMessageState.success();
      Logger.info('Pipeline completed successfully');
    } catch (e, stackTrace) {
      Logger.error('Send message failed', e, stackTrace);
      ErrorHandler.logError(e, stackTrace);
      state = SendMessageState.error(ErrorHandler.getErrorMessage(e));
      ref.read(streamingStateProvider.notifier).stop();
      ref.read(currentStreamingMessageProvider.notifier).clear();
    }
  }

  Future<List<ChatMessage>> _buildMessageHistory({
    required int sessionId,
    required String userMessage,
    required String systemPrompt,
  }) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final attachmentRepo = ref.read(attachmentRepositoryProvider);

    final messages = await chatRepo.getMessages(sessionId);
    final apiMessages = <ChatMessage>[];

    // 시스템 프롬프트 추가 (모델별로 다름)
    if (systemPrompt.isNotEmpty) {
      apiMessages.add(ChatMessage(
        role: 'system',
        content: systemPrompt,
      ));
    }

    // 기존 메시지 히스토리
    for (final msg in messages) {
      final attachments = await attachmentRepo.getMessageAttachments(msg.id);
      final contentBuffer = StringBuffer();

      if (attachments.isNotEmpty) {
        contentBuffer.writeln('=== 첨부파일 ===');
        for (final attachment in attachments) {
          try {
            final fileContent = await attachmentRepo.readAttachment(attachment.id);
            contentBuffer.writeln('--- ${attachment.fileName} ---');
            contentBuffer.writeln(fileContent);
          } catch (e) {
            Logger.warning('Failed to read attachment: ${attachment.fileName}');
          }
        }
        contentBuffer.writeln('=================\n');
      }

      contentBuffer.write(msg.content);

      apiMessages.add(ChatMessage(
        role: msg.role,
        content: contentBuffer.toString(),
      ));
    }

    return apiMessages;
  }

  Future<void> _updateSessionTitleIfNeeded(int sessionId, String firstMessage) async {
    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      final session = await chatRepo.getSession(sessionId);

      if (session != null && session.title == '새 대화') {
        final title = firstMessage.length > 50
            ? '${firstMessage.substring(0, 50)}...'
            : firstMessage;
        await chatRepo.updateSessionTitle(sessionId, title);
        Logger.info('Session title updated');
      }
    } catch (e) {
      Logger.warning('Failed to update session title: $e');
    }
  }

  void cancel() {
    Logger.info('Streaming cancelled');
    _activeService?.dispose();
    _activeService = null;
    state = const SendMessageState.idle();
    ref.read(streamingStateProvider.notifier).stop();
    ref.read(currentStreamingMessageProvider.notifier).clear();
  }
}

final sendMessageMutationProvider =
NotifierProvider<SendMessageMutationNotifier, SendMessageState>(
  SendMessageMutationNotifier.new,
);
