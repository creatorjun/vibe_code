// lib/domain/mutations/send_message_mutation.dart (기존 파일 교체)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/settings_state.dart';
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

  const SendMessageState({
    required this.status,
    this.error,
    this.progress,
  });

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
        throw const ValidationException(
          'API 키를 설정해주세요. 설정 화면에서 API 키를 입력해주세요.',
        );
      }

      if (!Validators.isValidApiKey(settingsAsync.apiKey)) {
        throw const ValidationException('올바르지 않은 API 키 형식입니다.');
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

      // 메시지 히스토리 구성
      final apiMessages = await _buildMessageHistory(sessionId, settingsAsync);

      // 현재 사용자 메시지 추가
      apiMessages.add(ChatMessage(
        role: 'user',
        content: content,
      ));

      // AI 응답 메시지 생성
      final aiMessageId = await chatRepo.addAssistantMessage(
        sessionId: sessionId,
        model: settingsAsync.enabledModels.isNotEmpty
            ? settingsAsync.enabledModels.first.modelId
            : settingsAsync.selectedModel,
        isStreaming: true,
      );

      // 스트리밍 상태 시작
      ref.read(streamingStateProvider.notifier).start();
      ref.read(currentStreamingMessageProvider.notifier).set(aiMessageId);

      state = const SendMessageState.streaming();

      // OpenRouter 서비스 생성
      _activeService = OpenRouterService(settingsAsync.apiKey);
      final responseBuffer = StringBuffer();

      // 파이프라인 실행
      await _executePipeline(
        settingsAsync: settingsAsync,
        messages: apiMessages,
        sessionId: sessionId,
        aiMessageId: aiMessageId,
        responseBuffer: responseBuffer,
      );

      // 스트리밍 완료
      await chatRepo.completeStreaming(aiMessageId);
      ref.read(streamingStateProvider.notifier).stop();
      ref.read(currentStreamingMessageProvider.notifier).clear();

      // 세션 제목 업데이트
      await _updateSessionTitleIfNeeded(sessionId, content);

      state = const SendMessageState.success();
      Logger.info('Message sent successfully');
    } catch (e, stackTrace) {
      Logger.error('Send message failed', e, stackTrace);
      ErrorHandler.logError(e, stackTrace);
      state = SendMessageState.error(ErrorHandler.getErrorMessage(e));
      ref.read(streamingStateProvider.notifier).stop();
      ref.read(currentStreamingMessageProvider.notifier).clear();
    } finally {
      _activeService?.dispose();
      _activeService = null;
    }
  }

  Future<void> _executePipeline({
    required SettingsState settingsAsync,
    required List<ChatMessage> messages,
    required int sessionId,
    required int aiMessageId,
    required StringBuffer responseBuffer,
  }) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final pipeline = settingsAsync.enabledModels;

    if (pipeline.isEmpty) {
      // 파이프라인이 없으면 기본 모델 사용
      await _streamSingleModel(
        model: settingsAsync.selectedModel,
        messages: messages,
        aiMessageId: aiMessageId,
        responseBuffer: responseBuffer,
      );
      return;
    }

    // 파이프라인 실행
    var currentMessages = List<ChatMessage>.from(messages);

    for (var i = 0; i < pipeline.length; i++) {
      final config = pipeline[i];
      Logger.info('Pipeline step ${i + 1}/${pipeline.length}: ${config.modelId}');

      // 시스템 프롬프트가 있으면 추가
      if (config.systemPrompt.isNotEmpty) {
        currentMessages = [
          ChatMessage(role: 'system', content: config.systemPrompt),
          ...currentMessages,
        ];
      }

      final stepBuffer = StringBuffer();
      await _streamSingleModel(
        model: config.modelId,
        messages: currentMessages,
        aiMessageId: aiMessageId,
        responseBuffer: stepBuffer,
      );

      final stepOutput = stepBuffer.toString();
      responseBuffer.write(stepOutput);

      // 다음 단계를 위해 현재 출력을 입력으로 사용
      if (i < pipeline.length - 1) {
        currentMessages = [
          ChatMessage(role: 'assistant', content: stepOutput),
        ];

        // DB 업데이트
        await chatRepo.updateMessageContent(aiMessageId, responseBuffer.toString());
      }
    }
  }

  Future<void> _streamSingleModel({
    required String model,
    required List<ChatMessage> messages,
    required int aiMessageId,
    required StringBuffer responseBuffer,
  }) async {
    final chatRepo = ref.read(chatRepositoryProvider);

    await for (final chunk in _activeService!.streamChat(
      messages: messages,
      model: model,
    )) {
      responseBuffer.write(chunk);
      await chatRepo.updateMessageContent(
        aiMessageId,
        responseBuffer.toString(),
      );
    }
  }

  Future<List<ChatMessage>> _buildMessageHistory(
      int sessionId,
      SettingsState settingsAsync,
      ) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final attachmentRepo = ref.read(attachmentRepositoryProvider);

    final messages = await chatRepo.getMessages(sessionId);
    final apiMessages = <ChatMessage>[];

    for (final msg in messages) {
      final attachments = await attachmentRepo.getMessageAttachments(msg.id);
      final contentBuffer = StringBuffer();

      if (attachments.isNotEmpty) {
        contentBuffer.writeln('=== 첨부파일 ===');
        for (final attachment in attachments) {
          try {
            final fileContent =
            await attachmentRepo.readAttachment(attachment.id);
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

  Future<void> _updateSessionTitleIfNeeded(
      int sessionId,
      String firstMessage,
      ) async {
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
    _activeService?.cancelStreaming();
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
