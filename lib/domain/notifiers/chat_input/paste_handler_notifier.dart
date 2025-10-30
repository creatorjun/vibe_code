// lib/domain/notifiers/chat_input/paste_handler_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_code/core/utils/clipboard_helper.dart';
import 'package:vibe_code/core/utils/logger.dart';
import 'package:vibe_code/domain/notifiers/chat_input/chat_input_action_notifier.dart';
import 'package:vibe_code/domain/providers/chat_input_state_provider.dart';
import 'package:vibe_code/domain/providers/chat_provider.dart';

/// ✅ Riverpod 3.0: NotifierProvider 패턴
/// 붙여넣기 로직을 완전히 분리하여 관리합니다.
/// 텍스트와 이미지 붙여넣기를 모두 지원합니다.
class PasteHandlerNotifier extends Notifier<void> {
  @override
  void build() {
    // Notifier는 상태가 void이므로 초기화 불필요
  }

  /// 붙여넣기 처리 (텍스트 or 이미지)
  ///
  /// 클립보드 내용을 분석하여 이미지가 있으면 첨부파일로 업로드하고,
  /// 텍스트만 있으면 입력 필드에 삽입합니다.
  Future<PasteResult> handlePaste() async {
    // ✅ Riverpod 3.0: 비동기 작업 전 mounted 체크
    if (!ref.mounted) return const PasteResult.cancelled();

    Logger.debug('[PASTE] Starting paste operation');

    try {
      // 1. 클립보드에 이미지가 있는지 확인
      final hasImage = await ClipboardHelper.hasImage();

      if (!hasImage) {
        // 텍스트만 있는 경우
        return await _handleTextPaste();
      }

      // 이미지가 있는 경우
      return await _handleImagePaste();
    } catch (e, stack) {
      Logger.error('[PASTE] Failed to process paste', e, stack);
      return PasteResult.error('붙여넣기 실패: ${e.toString()}');
    }
  }

  /// 텍스트 붙여넣기
  ///
  /// 클립보드에서 텍스트를 가져와 입력 필드에 삽입합니다.
  Future<PasteResult> _handleTextPaste() async {
    if (!ref.mounted) return const PasteResult.cancelled();

    try {
      final text = await ClipboardHelper.getTextFromClipboard();

      if (text == null || text.isEmpty) {
        Logger.debug('[PASTE] No text content in clipboard');
        return const PasteResult.noContent();
      }

      // ✅ Controller를 통해 텍스트 삽입
      ref.read(chatInputActionProvider.notifier).insertText(text);

      Logger.info('[PASTE] Text pasted successfully (${text.length} chars)');
      return const PasteResult.success(message: '텍스트가 붙여넣어졌습니다');
    } catch (e, stack) {
      Logger.error('[PASTE] Failed to paste text', e, stack);
      return PasteResult.error('텍스트 붙여넣기 실패: ${e.toString()}');
    }
  }

  /// 이미지 붙여넣기
  ///
  /// 클립보드에서 이미지를 가져와 임시 파일로 저장한 후,
  /// 첨부파일로 업로드하고 입력 필드에 추가합니다.
  Future<PasteResult> _handleImagePaste() async {
    if (!ref.mounted) return const PasteResult.cancelled();

    Logger.debug('[PASTE] Processing image from clipboard');

    try {
      // 1. 클립보드에서 이미지 파일 추출
      final imageFile = await ClipboardHelper.getImageFromClipboard();

      if (imageFile == null) {
        Logger.debug('[PASTE] Image extraction returned null');
        return const PasteResult.noContent();
      }

      Logger.debug('[PASTE] Image file created: ${imageFile.path}');

      // ✅ Riverpod 3.0: 비동기 작업 전 mounted 체크
      if (!ref.mounted) return const PasteResult.cancelled();

      // 2. 첨부파일로 업로드
      final attachmentRepo = ref.read(attachmentRepositoryProvider);
      final attachmentId = await attachmentRepo.uploadFile(imageFile.path);

      // ✅ 업로드 후 다시 mounted 체크
      if (!ref.mounted) return const PasteResult.cancelled();

      Logger.info('[PASTE] Image uploaded successfully - ID: $attachmentId');

      // 3. 상태 업데이트 (첨부파일 추가)
      ref.read(chatInputStateProvider.notifier).addAttachment(attachmentId);

      // 4. 입력 필드 높이 재계산
      ref.read(chatInputActionProvider.notifier).scheduleHeightUpdate();

      return const PasteResult.success(message: '이미지가 첨부되었습니다');
    } catch (e, stack) {
      Logger.error('[PASTE] Failed to paste image', e, stack);
      return PasteResult.error('이미지 붙여넣기 실패: ${e.toString()}');
    }
  }
}

/// ✅ Provider 정의
final pasteHandlerProvider = NotifierProvider<PasteHandlerNotifier, void>(
  PasteHandlerNotifier.new,
);

/// ✅ 결과 모델 (sealed class - Riverpod 3.0 스타일)
/// 붙여넣기 작업의 결과를 타입 안전하게 표현합니다.
sealed class PasteResult {
  const PasteResult();

  const factory PasteResult.success({String? message}) = PasteSuccess;
  const factory PasteResult.error(String message) = PasteError;
  const factory PasteResult.noContent() = PasteNoContent;
  const factory PasteResult.cancelled() = PasteCancelled;
}

/// 붙여넣기 성공
class PasteSuccess extends PasteResult {
  final String? message;
  const PasteSuccess({this.message});
}

/// 붙여넣기 실패
class PasteError extends PasteResult {
  final String message;
  const PasteError(this.message);
}

/// 클립보드에 내용 없음
class PasteNoContent extends PasteResult {
  const PasteNoContent();
}

/// 작업 취소됨 (위젯이 dispose된 경우)
class PasteCancelled extends PasteResult {
  const PasteCancelled();
}
