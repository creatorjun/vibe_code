// lib/domain/notifiers/chat_input/drop_handler_notifier.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:vibe_code/core/utils/logger.dart';
import 'package:vibe_code/domain/providers/chat_provider.dart';
import 'package:vibe_code/domain/providers/chat_input_state_provider.dart';
import 'package:vibe_code/domain/notifiers/chat_input/chat_input_action_notifier.dart';

/// ✅ Riverpod 3.0: NotifierProvider 패턴
/// 드래그앤드롭 상태 + 로직 통합
class DropHandlerNotifier extends Notifier<DropHandlerState> {
  @override
  DropHandlerState build() {
    return const DropHandlerState(isDragging: false);
  }

  /// 드래그 시작
  void onDropEnter() {
    if (!ref.mounted) return;
    Logger.debug('[DROP] Drag entered');
    state = state.copyWith(isDragging: true);
  }

  /// 드래그 종료
  void onDropLeave() {
    if (!ref.mounted) return;
    Logger.debug('[DROP] Drag exited');
    state = state.copyWith(isDragging: false);
  }

  /// ✅ 드롭 가능 여부
  DropOperation onDropOver(DropOverEvent event) {
    return DropOperation.copy;
  }

  /// 파일 드롭 처리
  ///
  /// super_drag_and_drop의 getValue는 콜백 기반이므로
  /// Completer를 사용하여 Future로 변환합니다.
  Future<DropResult> handleDrop(PerformDropEvent event) async {
    if (!ref.mounted) return const DropResult.cancelled();

    // 드래그 상태 해제
    state = state.copyWith(isDragging: false);
    Logger.info('[DROP] Processing drop event');

    try {
      final item = event.session.items.first;
      final reader = item.dataReader;

      if (reader == null || !reader.canProvide(Formats.fileUri)) {
        Logger.warning('[DROP] No file URI available');
        return const DropResult.error('지원하지 않는 파일 형식입니다');
      }

      // ✅ Completer로 콜백 기반 API를 Future로 변환
      final completer = Completer<DropResult>();

      reader.getValue(
        Formats.fileUri,
            (uri) async {
          if (uri == null) {
            Logger.warning('[DROP] URI is null');
            completer.complete(const DropResult.error('파일 경로를 가져올 수 없습니다'));
            return;
          }

          try {
            final filePath = uri.toFilePath();
            Logger.debug('[DROP] File path: $filePath');

            // ✅ mounted 체크
            if (!ref.mounted) {
              completer.complete(const DropResult.cancelled());
              return;
            }

            // 파일 업로드
            final attachmentRepo = ref.read(attachmentRepositoryProvider);
            final attachmentId = await attachmentRepo.uploadFile(filePath);

            // ✅ 업로드 후 다시 mounted 체크
            if (!ref.mounted) {
              completer.complete(const DropResult.cancelled());
              return;
            }

            Logger.info('[DROP] Upload success - ID: $attachmentId');

            // 상태 업데이트
            ref.read(chatInputStateProvider.notifier).addAttachment(attachmentId);
            ref.read(chatInputActionProvider.notifier).scheduleHeightUpdate();

            final fileName = filePath.split('/').last;
            completer.complete(DropResult.success(fileName: fileName));
          } catch (e, stack) {
            Logger.error('[DROP] Upload failed', e, stack);
            completer.complete(DropResult.error(e.toString()));
          }
        },
        onError: (error) {
          Logger.error('[DROP] Reader error', error, null);
          completer.complete(DropResult.error(error.toString()));
        },
      );

      return await completer.future;
    } catch (e, stack) {
      Logger.error('[DROP] Failed', e, stack);
      return DropResult.error(e.toString());
    }
  }
}

/// ✅ Provider 정의
final dropHandlerProvider = NotifierProvider<DropHandlerNotifier, DropHandlerState>(
  DropHandlerNotifier.new,
);

/// ✅ 상태 모델
class DropHandlerState {
  final bool isDragging;

  const DropHandlerState({required this.isDragging});

  DropHandlerState copyWith({bool? isDragging}) {
    return DropHandlerState(
      isDragging: isDragging ?? this.isDragging,
    );
  }
}

/// ✅ 결과 모델 (sealed class)
sealed class DropResult {
  const DropResult();

  const factory DropResult.success({required String fileName}) = DropSuccess;
  const factory DropResult.error(String message) = DropError;
  const factory DropResult.cancelled() = DropCancelled;
}

class DropSuccess extends DropResult {
  final String fileName;
  const DropSuccess({required this.fileName});
}

class DropError extends DropResult {
  final String message;
  const DropError(this.message);
}

class DropCancelled extends DropResult {
  const DropCancelled();
}
