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

  const SendMessageState({
    required this.status,
    this.error,
    this.progress,
  });

  const SendMessageState.idle() : this(status: SendMessageStatus.idle);
  const SendMessageState.sending() : this(status: SendMessageStatus.sending);
  const SendMessageState.streaming([double? progress])
      : this(status: SendMessageStatus.streaming, progress: progress);
  const SendMessageState.success() : this(status: SendMessageStatus.success);
  const SendMessageState.error(String error)
      : this(status: SendMessageStatus.error, error: error);
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

      if (settingsAsync.apiKey.isEmpty) {
        throw const ValidationException(
          'API 키가 설정되지 않았습니다.\n설정에서 API 키를 입력해주세요.',
        );
      }

      if (!Validators.isValidApiKey(settingsAsync.apiKey)) {
        throw const ValidationException('유효하지 않은 API 키입니다.');
      }

      final userMessageId = await chatRepo.addUserMessage(
        sessionId: sessionId,
        content: content,
      );

      if (attachmentIds.isNotEmpty) {
        await attachmentRepo.linkToMessage(
          messageId: userMessageId,
          attachmentIds: attachmentIds,
        );
      }

      final messages = await _buildMessageHistory(sessionId);

      final aiMessageId = await chatRepo.addAssistantMessage(
        sessionId: sessionId,
        model: settingsAsync.selectedModel,
        isStreaming: true,
      );

      state = const SendMessageState.streaming();
      ref.read(streamingStateProvider.notifier).start();
      ref.read(currentStreamingMessageProvider.notifier).set(aiMessageId);

      _activeService = OpenRouterService(settingsAsync.apiKey);
      final contentBuffer = StringBuffer();

      try {
        await for (final chunk in _activeService!.streamChat(
          messages: messages,
          model: settingsAsync.selectedModel,
        )) {
          contentBuffer.write(chunk);
          await chatRepo.updateMessageContent(aiMessageId, contentBuffer.toString());
        }

        await chatRepo.completeStreaming(aiMessageId);

        await _updateSessionTitleIfNeeded(sessionId, content);

        state = const SendMessageState.success();
        Logger.info('Message sent successfully');
      } catch (e, stackTrace) {
        Logger.error('Streaming error', e, stackTrace);
        await chatRepo.deleteMessage(aiMessageId);
        rethrow;
      } finally {
        _activeService?.dispose();
        _activeService = null;
        ref.read(streamingStateProvider.notifier).stop();
        ref.read(currentStreamingMessageProvider.notifier).clear();
      }

      await Future.delayed(const Duration(seconds: 2));
      state = const SendMessageState.idle();
    } catch (e, stackTrace) {
      Logger.error('Send message failed', e, stackTrace);
      ErrorHandler.logError(e, stackTrace);

      state = SendMessageState.error(ErrorHandler.getErrorMessage(e));

      ref.read(streamingStateProvider.notifier).stop();
      ref.read(currentStreamingMessageProvider.notifier).clear();
    }
  }

  Future<List<ChatMessage>> _buildMessageHistory(int sessionId) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final attachmentRepo = ref.read(attachmentRepositoryProvider);
    final settingsAsync = await ref.read(settingsProvider.future);

    final messages = await chatRepo.getMessages(sessionId);
    final apiMessages = <ChatMessage>[];

    if (settingsAsync.systemPrompt.isNotEmpty) {
      apiMessages.add(ChatMessage(
        role: 'system',
        content: settingsAsync.systemPrompt,
      ));
    }

    for (final msg in messages) {
      final attachments = await attachmentRepo.getMessageAttachments(msg.id);
      final contentBuffer = StringBuffer();

      if (attachments.isNotEmpty) {
        contentBuffer.writeln('=== 첨부파일 ===');
        for (final attachment in attachments) {
          try {
            final fileContent = await attachmentRepo.readAttachment(attachment.id);
            contentBuffer.writeln('\n[${attachment.fileName}]');
            contentBuffer.writeln(fileContent);
          } catch (e) {
            Logger.warning('Failed to read attachment: ${attachment.fileName}');
          }
        }
        contentBuffer.writeln('\n=== 메시지 ===');
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

final sendMessageMutationProvider = NotifierProvider<SendMessageMutationNotifier, SendMessageState>(
  SendMessageMutationNotifier.new,
);
