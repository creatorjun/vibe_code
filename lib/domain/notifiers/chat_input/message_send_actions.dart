import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_code/core/utils/logger.dart';
import 'package:vibe_code/domain/mutations/send_message/send_message_mutation.dart';
import 'package:vibe_code/domain/providers/chat_provider.dart';
import 'package:vibe_code/domain/providers/chat_input_state_provider.dart';
import 'package:vibe_code/domain/notifiers/chat_input/chat_input_action_notifier.dart';

/// NotifierProvider (Ref.mounted 사용 가능)
class MessageSendActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  /// 메시지 전송 액션
  Future<SendActionResult> sendMessage() async {
    if (!ref.mounted) return const SendActionResult.cancelled();

    final inputState = ref.read(chatInputStateProvider);
    if (!inputState.canSend) return const SendActionResult.invalidInput();

    Logger.info('[MessageSend] Preparing to send message');

    // 1. 세션 준비
    final activeSession = ref.read(activeSessionProvider);
    final sessionId = activeSession ?? await _createSession();
    if (!ref.mounted) return const SendActionResult.cancelled();

    // 2. 메시지 내용 및 첨부파일 준비
    final content = inputState.content.trim();
    final attachmentIds = List<String>.from(inputState.attachmentIds);

    // 3. 입력창 초기화
    ref.read(chatInputActionProvider.notifier).clearInput();

    // Riverpod 3.0 mounted 체크
    if (!ref.mounted) return const SendActionResult.cancelled();

    try {
      // 4. SendMessageMutation 실행
      await ref.read(sendMessageMutationProvider.notifier).sendMessage(
        sessionId: sessionId,
        content: content.isEmpty ? '' : content,
        attachmentIds: attachmentIds,
      );

      Logger.info('[MessageSend] Message sent successfully');
      return const SendActionResult.success();
    } catch (e, stackTrace) {
      Logger.error('[MessageSend] Send failed', e, stackTrace);
      return SendActionResult.error(e.toString());
    } finally {
      // ✅ 5. 전송 완료 후 명시적으로 포커스 요청
      if (ref.mounted) {
        ref.read(chatInputActionProvider.notifier).requestFocus();
        Logger.debug('[MessageSend] Focus requested after send completion');
      }
    }
  }

  /// 세션 생성 (✅ title 파라미터 추가)
  Future<int> _createSession() async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final sessionId = await chatRepo.createSession('새로운 대화'); // ✅ title 추가
    if (ref.mounted) {
      ref.read(activeSessionProvider.notifier).select(sessionId);
    }
    return sessionId;
  }

  /// 스트리밍 취소
  void cancelStreaming() {
    if (!ref.mounted) return;

    ref.read(sendMessageMutationProvider.notifier).cancel();

    // ✅ 스트리밍 취소 후 명시적으로 포커스 요청
    ref.read(chatInputActionProvider.notifier).requestFocus();
    Logger.info('[MessageSend] Streaming cancelled');
  }
}

/// Provider
final messageSendActionsProvider = NotifierProvider<MessageSendActionsNotifier, void>(
  MessageSendActionsNotifier.new,
);

/// 전송 결과 sealed class
sealed class SendActionResult {
  const SendActionResult();

  const factory SendActionResult.success() = SendActionSuccess;
  const factory SendActionResult.error(String message) = SendActionError;
  const factory SendActionResult.invalidInput() = SendActionInvalidInput;
  const factory SendActionResult.cancelled() = SendActionCancelled;
}

class SendActionSuccess extends SendActionResult {
  const SendActionSuccess();
}

class SendActionError extends SendActionResult {
  final String message;
  const SendActionError(this.message);
}

class SendActionInvalidInput extends SendActionResult {
  const SendActionInvalidInput();
}

class SendActionCancelled extends SendActionResult {
  const SendActionCancelled();
}
