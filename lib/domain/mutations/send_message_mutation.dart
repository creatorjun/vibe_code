// lib/domain/mutations/send_message_mutation.dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/validators.dart';
import '../../data/models/api_request.dart';
import '../../data/models/settings_state.dart';
import '../../data/services/openrouter_service.dart';
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

    int? aiMessageId;

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

      // ✅ 첨부파일 내용 로드
      String fullContent = content;
      if (attachmentIds.isNotEmpty) {
        final attachmentContents = <String>[];
        for (final attachmentId in attachmentIds) {
          try {
            final attachment = await attachmentRepo.getAttachment(attachmentId);
            if (attachment != null) {
              // 파일 내용 읽기
              final file = File(attachment.filePath);
              if (await file.exists()) {
                final fileContent = await file.readAsString();
                attachmentContents.add('''

---
📎 첨부파일: ${attachment.fileName}
---

$fileContent

---
''');
                Logger.info('Attachment loaded: ${attachment.fileName} (${fileContent.length} chars)');
              }
            }
          } catch (e) {
            Logger.error('Failed to load attachment: $attachmentId', e);
          }
        }

        if (attachmentContents.isNotEmpty) {
          fullContent = '''
$content

${attachmentContents.join('\n')}
''';
          Logger.info('Full content with attachments: ${fullContent.length} chars');
        }
      }

      // 메시지 히스토리 구성
      final apiMessages = await _buildMessageHistory(sessionId, settingsAsync);

      // ✅ 첨부파일 내용이 포함된 메시지 추가
      apiMessages.add(ChatMessage(
        role: 'user',
        content: fullContent,
      ));

      // 선택된 파이프라인 깊이 가져오기
      final selectedDepth = ref.read(selectedPipelineDepthProvider);
      final fullPipeline = settingsAsync.modelPipeline;

      // 선택된 깊이만큼만 사용
      final activePipeline = fullPipeline.take(selectedDepth).toList();

      Logger.info('Using ${activePipeline.length} models (depth: $selectedDepth)');

      // AI 응답 메시지 생성
      final modelId = activePipeline.isNotEmpty
          ? activePipeline.first.modelId
          : 'anthropic/claude-3.5-sonnet';

      aiMessageId = await chatRepo.addAssistantMessage(
        sessionId: sessionId,
        model: modelId,
        isStreaming: true,
      );

      // 스트리밍 상태 시작
      ref.read(streamingStateProvider.notifier).start();
      ref.read(currentStreamingMessageProvider.notifier).set(aiMessageId);

      state = const SendMessageState.streaming();

      final responseBuffer = StringBuffer();

      // PipelineService를 통한 파이프라인 실행
      final pipelineService = ref.read(pipelineServiceProvider);

      await for (final _ in pipelineService.executePipeline(
        pipeline: activePipeline,
        initialInput: fullContent, // ✅ 첨부파일 포함된 전체 내용
        messageHistory: apiMessages.sublist(0, apiMessages.length - 1),
        onStepStart: (step, config) {
          Logger.info(
              'Pipeline step ${step + 1}/${activePipeline.length}: ${config.modelId}');
        },
        onChunk: (step, chunk) async {
          responseBuffer.write(chunk);

          // DB 업데이트
          await chatRepo.updateMessageContent(
            aiMessageId!,
            responseBuffer.toString(),
          );
        },
        aiServiceFactory: ref.read(aiServiceFactoryProvider),
        apiKey: settingsAsync.apiKey,
      )) {
        // 스트림 청크는 이미 onChunk에서 처리됨
      }

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

      final errorMessage = ErrorHandler.getErrorMessage(e);
      state = SendMessageState.error(errorMessage);

      // AI 메시지를 에러 메시지로 업데이트
      if (aiMessageId != null) {
        final chatRepo = ref.read(chatRepositoryProvider);

        // 기존 내용 가져오기
        String existingContent = '';
        try {
          final messages = await chatRepo.getMessages(sessionId);
          final currentMessage =
          messages.firstWhere((m) => m.id == aiMessageId);
          existingContent = currentMessage.content;
        } catch (_) {
          existingContent = '';
        }

        // 기존 내용 + 에러 메시지 합치기
        final errorContent = existingContent.trim().isNotEmpty
            ? '$existingContent\n\n⚠️ 파이프라인 오류\n\n$errorMessage'
            : '⚠️ 메시지 전송 실패\n\n$errorMessage';

        // 메시지 내용 업데이트
        await chatRepo.updateMessageContent(aiMessageId, errorContent);

        // 스트리밍 완료 처리
        await chatRepo.completeStreaming(aiMessageId);

        Logger.info(
            'Error message ${existingContent.isEmpty ? "saved" : "appended"} to database: $aiMessageId');
      }

      ref.read(streamingStateProvider.notifier).stop();
      ref.read(currentStreamingMessageProvider.notifier).clear();
    } finally {
      _activeService?.dispose();
      _activeService = null;
    }
  }

  /// 메시지 전송 취소
  void cancel() {
    Logger.info('Cancelling message send');
    _activeService?.dispose();
    _activeService = null;
    ref.read(streamingStateProvider.notifier).stop();
    ref.read(currentStreamingMessageProvider.notifier).clear();
    state = const SendMessageState.idle();
  }

  /// 메시지 히스토리 구성
  Future<List<ChatMessage>> _buildMessageHistory(
      int sessionId,
      SettingsState settings,
      ) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final dbMessages = await chatRepo.getMessages(sessionId);

    return dbMessages.map((msg) {
      return ChatMessage(
        role: msg.role,
        content: msg.content,
      );
    }).toList();
  }

  /// 세션 제목 업데이트 (첫 메시지인 경우)
  Future<void> _updateSessionTitleIfNeeded(
      int sessionId,
      String content,
      ) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final messages = await chatRepo.getMessages(sessionId);

    // 메시지가 2개(user + assistant)인 경우 제목 업데이트
    if (messages.length == 2) {
      final title = content.length > 50
          ? '${content.substring(0, 50)}...'
          : content;
      await chatRepo.updateSessionTitle(sessionId, title);
      Logger.info('Session title updated: $title');
    }
  }
}

final sendMessageMutationProvider =
NotifierProvider<SendMessageMutationNotifier, SendMessageState>(
  SendMessageMutationNotifier.new,
);
