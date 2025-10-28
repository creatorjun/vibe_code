// lib/domain/notifiers/chat_input/paste_handler_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_code/core/utils/clipboard_helper.dart';
import 'package:vibe_code/core/utils/logger.dart';
import 'package:vibe_code/domain/notifiers/chat_input/chat_input_action_notifier.dart';
import 'package:vibe_code/domain/providers/chat_input_state_provider.dart';
import 'package:vibe_code/domain/providers/chat_provider.dart';


/// ✅ Riverpod 3.0 NotifierProvider 패턴
/// 붙여넣기 로직을 완전히 분리
class PasteHandlerNotifier extends Notifier<void> {
  @override
  void build() {}

  /// 붙여넣기 처리 (텍스트 or 이미지)
  Future<PasteResult> handlePaste() async {
    if (!ref.mounted) return const PasteResult.cancelled();

    Logger.debug('[PASTE] Starting paste operation');

    try {
      // 1. 이미지 확인
      final hasImage = await ClipboardHelper.hasImage();

      if (!hasImage) {
        return await _handleTextPaste();
      }

      return await _handleImagePaste();
    } catch (e, stack) {
      Logger.error('[PASTE] Failed', e, stack);
      return PasteResult.error(e.toString());
    }
  }

  /// 텍스트 붙여넣기
  Future<PasteResult> _handleTextPaste() async {
    if (!ref.mounted) return const PasteResult.cancelled();

    final text = await ClipboardHelper.getTextFromClipboard();
    if (text == null || text.isEmpty) {
      return const PasteResult.noContent();
    }

    // ✅ Controller를 통해 텍스트 삽입
    ref.read(chatInputActionProvider.notifier).insertText(text);
    Logger.debug('[PASTE] Text pasted successfully');

    return const PasteResult.success(message: '텍스트가 붙여넣어졌습니다');
  }

  /// 이미지 붙여넣기
  Future<PasteResult> _handleImagePaste() async {
    if (!ref.mounted) return const PasteResult.cancelled();

    Logger.debug('[PASTE] Processing image');

    final imageFile = await ClipboardHelper.getImageFromClipboard();
    if (imageFile == null) {
      Logger.debug('[PASTE] Image file is null');
      return const PasteResult.noContent();
    }

    // ✅ Riverpod 3.0: 비동기 작업 전 mounted 체크
    if (!ref.mounted) return const PasteResult.cancelled();

    final attachmentRepo = ref.read(attachmentRepositoryProvider);
    final attachmentId = await attachmentRepo.uploadFile(imageFile.path);

    // ✅ 업로드 후 다시 mounted 체크
    if (!ref.mounted) return const PasteResult.cancelled();

    Logger.info('[PASTE] Image uploaded - ID: $attachmentId');

    // 상태 업데이트
    ref.read(chatInputStateProvider.notifier).addAttachment(attachmentId);
    ref.read(chatInputActionProvider.notifier).scheduleHeightUpdate();

    return const PasteResult.success(message: '이미지가 첨부되었습니다');
  }
}

/// ✅ Provider 정의
final pasteHandlerProvider = NotifierProvider<PasteHandlerNotifier, void>(
  PasteHandlerNotifier.new,
);

/// ✅ 결과 모델 (sealed class - Riverpod 3.0 스타일)
sealed class PasteResult {
  const PasteResult();

  const factory PasteResult.success({String? message}) = PasteSuccess;
  const factory PasteResult.error(String message) = PasteError;
  const factory PasteResult.noContent() = PasteNoContent;
  const factory PasteResult.cancelled() = PasteCancelled;
}

class PasteSuccess extends PasteResult {
  final String? message;
  const PasteSuccess({this.message});
}

class PasteError extends PasteResult {
  final String message;
  const PasteError(this.message);
}

class PasteNoContent extends PasteResult {
  const PasteNoContent();
}

class PasteCancelled extends PasteResult {
  const PasteCancelled();
}
