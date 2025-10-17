import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_provider.g.dart';

/// 채팅 말풍선의 확장/축소 상태를 관리하는 Provider
@riverpod
class ChatBubbleState extends _$ChatBubbleState {
  @override
  Map<String, bool> build() {
    // Key: messageId, Value: isExpanded
    return {};
  }

  /// 특정 메시지 말풍선의 확장 상태를 토글합니다.
  void toggleExpanded(String messageId) {
    state = {
      ...state,
      messageId: !(state[messageId] ?? false),
    };
  }
}