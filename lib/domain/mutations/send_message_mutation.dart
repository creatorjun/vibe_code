// lib/domain/mutations/send_message_mutation.dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/validators.dart';
import '../../data/models/api_request.dart';
import '../../data/models/settings_state.dart'; // SettingsState 추가
// import '../../data/services/openrouter_service.dart'; // 직접 사용하지 않으므로 주석 처리 또는 제거 가능
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
  final double? progress; // Pipeline 진행률 (선택 사항)

  const SendMessageState.idle()
      : status = SendMessageStatus.idle,
        error = null,
        progress = null;

  const SendMessageState.sending()
      : status = SendMessageStatus.sending,
        error = null,
        progress = null;

  // progress 추가
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
  // OpenRouterService 참조 제거 (PipelineService가 내부에서 생성/관리)
  // OpenRouterService? _activeService;

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
      // settingsProvider에서 설정값 읽기 (프리셋 포함)
      final settingsAsync = await ref.read(settingsProvider.future);

      // API 키 검증 (기존 코드 유지)
      if (settingsAsync.apiKey.isEmpty) {
        throw const ValidationException(
          'API 키를 설정해주세요. 설정 화면에서 API 키를 입력해주세요.',
        );
      }
      if (!Validators.isValidApiKey(settingsAsync.apiKey)) {
        throw const ValidationException('올바르지 않은 API 키 형식입니다.');
      }

      // 사용자 메시지 추가 (기존 코드 유지)
      final userMessageId = await chatRepo.addUserMessage(
        sessionId: sessionId,
        content: content,
      );

      // 첨부파일 링크 (기존 코드 유지)
      if (attachmentIds.isNotEmpty) {
        await attachmentRepo.linkToMessage(
          messageId: userMessageId,
          attachmentIds: attachmentIds,
        );
      }

      // 첨부파일 내용 로드 (기존 코드 유지)
      String fullContent = content;
      if (attachmentIds.isNotEmpty) {
        final attachmentContents = <String>[];
        for (final attachmentId in attachmentIds) {
          try {
            final attachment = await attachmentRepo.getAttachment(attachmentId);
            if (attachment != null) {
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

      // 메시지 히스토리 구성 (기존 코드 유지)
      final apiMessages = await _buildMessageHistory(sessionId, settingsAsync);
      apiMessages.add(ChatMessage(
        role: 'user',
        content: fullContent, // 첨부파일 포함된 전체 내용
      ));

      // 선택된 파이프라인 깊이 가져오기 (기존 코드 유지)
      final selectedDepth = ref.read(selectedPipelineDepthProvider);
      // SettingsState에서 모델 파이프라인 가져오기
      final fullPipelineConfigs = settingsAsync.modelPipeline;

      // 선택된 깊이만큼만 사용
      List<ModelConfig> activePipelineConfigs = fullPipelineConfigs.take(selectedDepth).toList();

      // --- 프리셋 적용 로직 (수정 없음) ---
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
          Logger.debug('  Step ${i+1}: Model=${config.modelId}, Prompt=${prompt.isNotEmpty ? "[Preset Prompt]" : "[Empty]"}');
        }
        activePipelineConfigs = pipelineWithPresetPrompts;
      } else {
        Logger.info('No preset selected, using manually configured prompts.');
        for (int i = 0; i < activePipelineConfigs.length; i++) {
          final config = activePipelineConfigs[i];
          Logger.debug('  Step ${i+1}: Model=${config.modelId}, Prompt=${config.systemPrompt.isNotEmpty ? "[Manual Prompt]" : "[Empty]"}');
        }
      }
      // --- ---

      Logger.info('Using ${activePipelineConfigs.length} models (depth: $selectedDepth)');

      // AI 응답 메시지 생성 (기존 코드 유지)
      final modelId = activePipelineConfigs.isNotEmpty
          ? activePipelineConfigs.first.modelId
          : 'anthropic/claude-3.5-sonnet';

      aiMessageId = await chatRepo.addAssistantMessage(
        sessionId: sessionId,
        model: modelId,
        isStreaming: true,
      );

      // 스트리밍 상태 시작 (기존 코드 유지)
      ref.read(streamingStateProvider.notifier).start();
      ref.read(currentStreamingMessageProvider.notifier).set(aiMessageId);

      state = const SendMessageState.streaming(progress: 0.0);

      final responseBuffer = StringBuffer();
      // final int completedSteps = 0; // <-- 변수 제거

      // PipelineService를 통한 파이프라인 실행
      final pipelineService = ref.read(pipelineServiceProvider);

      await for (final _ in pipelineService.executePipeline(
        pipeline: activePipelineConfigs,
        initialInput: fullContent,
        messageHistory: apiMessages.sublist(0, apiMessages.length - 1),
        onStepStart: (step, config) {
          Logger.info('Pipeline step ${step + 1}/${activePipelineConfigs.length}: ${config.modelId}');
          // --- setState 대신 state 직접 할당으로 수정 ---
          state = SendMessageState.streaming(progress: step / activePipelineConfigs.length);
          // --- ---
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
        // yield가 호출될 때마다 단계가 완료된 것으로 간주 (completedSteps 변수 제거됨)
        // completedSteps++;
      }

      // 스트리밍 완료 (기존 코드 유지)
      await chatRepo.completeStreaming(aiMessageId);
      ref.read(streamingStateProvider.notifier).stop();
      ref.read(currentStreamingMessageProvider.notifier).clear();

      // 세션 제목 업데이트 (기존 코드 유지)
      await _updateSessionTitleIfNeeded(sessionId, content);

      state = const SendMessageState.success();
      Logger.info('Message sent successfully via pipeline');

    } catch (e, stackTrace) {
      Logger.error('Send message failed', e, stackTrace);
      ErrorHandler.logError(e, stackTrace);

      final errorMessage = ErrorHandler.getErrorMessage(e);
      state = SendMessageState.error(errorMessage);

      // AI 메시지를 에러 메시지로 업데이트 (기존 코드 유지)
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
        Logger.info('Error message ${existingContent.isEmpty ? "saved" : "appended"} to database: $aiMessageId');
      }

      ref.read(streamingStateProvider.notifier).stop();
      ref.read(currentStreamingMessageProvider.notifier).clear();
    } finally {
      // _activeService 관련 코드 제거 (기존 코드 유지)
    }
  }

  /// 메시지 전송 취소 (기존 코드 유지)
  void cancel() {
    Logger.info('Cancelling message send');
    ref.read(streamingStateProvider.notifier).stop();
    ref.read(currentStreamingMessageProvider.notifier).clear();
    state = const SendMessageState.idle();
  }

  /// 메시지 히스토리 구성 (기존 코드 유지)
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

  /// 세션 제목 업데이트 (기존 코드 유지)
  Future<void> _updateSessionTitleIfNeeded(
      int sessionId,
      String content,
      ) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final messages = await chatRepo.getMessages(sessionId);
    if (messages.length == 2) {
      final title = content.length > 50 ? '${content.substring(0, 50)}...' : content;
      await chatRepo.updateSessionTitle(sessionId, title);
      Logger.info('Session title updated: $title');
    }
  }
}

final sendMessageMutationProvider =
NotifierProvider<SendMessageMutationNotifier, SendMessageState>(
  SendMessageMutationNotifier.new,
);