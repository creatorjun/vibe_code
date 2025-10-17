import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_provider.g.dart';

/// 채팅 말풍선의 확장/축소 상태를 관리하는 Provider
@riverpod
class ChatBubbleExpansion extends _$ChatBubbleExpansion {
  @override
  Map<String, bool> build() {
    // Key: messageId, Value: isExpanded
    return {};
  }

  /// 특정 메시지의 확장 상태를 가져옵니다.
  bool isExpanded(String messageId) {
    return state[messageId] ?? false;
  }

  /// 특정 메시지 말풍선의 확장 상태를 토글합니다.
  void toggleExpanded(String messageId) {
    state = {
      ...state,
      messageId: !(state[messageId] ?? false),
    };
  }

  /// 특정 메시지의 확장 상태를 설정합니다.
  void setExpanded(String messageId, bool isExpanded) {
    state = {
      ...state,
      messageId: isExpanded,
    };
  }
}
