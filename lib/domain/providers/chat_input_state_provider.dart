// lib/domain/providers/chat_input_state_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 채팅 입력 상태 (높이 + 작성 중인 메시지)
class ChatInputState {
  final double height;
  final String content;
  final List<String> attachmentIds;

  const ChatInputState({
    this.height = 56.0,
    this.content = '',
    this.attachmentIds = const [],
  });

  bool get canSend => content.trim().isNotEmpty || attachmentIds.isNotEmpty;

  ChatInputState copyWith({
    double? height,
    String? content,
    List<String>? attachmentIds,
  }) {
    return ChatInputState(
      height: height ?? this.height,
      content: content ?? this.content,
      attachmentIds: attachmentIds ?? this.attachmentIds,
    );
  }
}

/// 채팅 입력 상태 관리 (높이 + 텍스트 + 첨부파일)
class ChatInputStateNotifier extends Notifier<ChatInputState> {
  @override
  ChatInputState build() {
    return const ChatInputState();
  }

  /// 입력 필드 높이 업데이트
  void updateHeight(double height) {
    state = state.copyWith(height: height);
  }

  /// 텍스트 내용 업데이트
  void updateContent(String content) {
    state = state.copyWith(content: content);
  }

  /// 첨부파일 추가
  void addAttachment(String attachmentId) {
    final newList = [...state.attachmentIds, attachmentId];
    state = state.copyWith(attachmentIds: newList);
  }

  /// 첨부파일 제거
  void removeAttachment(String attachmentId) {
    final newList =
    state.attachmentIds.where((id) => id != attachmentId).toList();
    state = state.copyWith(attachmentIds: newList);
  }

  /// 초기화 (전송 후)
  void clear() {
    state = ChatInputState(height: state.height); // 높이는 유지
  }

  /// 메시지 내용 가져오기
  (String content, List<String> attachmentIds) get() {
    return (state.content, state.attachmentIds);
  }
}

final chatInputStateProvider =
NotifierProvider<ChatInputStateNotifier, ChatInputState>(
  ChatInputStateNotifier.new,
);

// ✅ 기존 코드와 호환성을 위한 별칭 (deprecated)
@Deprecated('Use chatInputStateProvider instead')
final chatInputHeightProvider = Provider<double>((ref) {
  return ref.watch(chatInputStateProvider.select((state) => state.height));
});
