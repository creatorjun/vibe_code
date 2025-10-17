// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 채팅 말풍선의 확장/축소 상태를 관리하는 Provider

@ProviderFor(ChatBubbleState)
const chatBubbleStateProvider = ChatBubbleStateProvider._();

/// 채팅 말풍선의 확장/축소 상태를 관리하는 Provider
final class ChatBubbleStateProvider
    extends $NotifierProvider<ChatBubbleState, Map<String, bool>> {
  /// 채팅 말풍선의 확장/축소 상태를 관리하는 Provider
  const ChatBubbleStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatBubbleStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatBubbleStateHash();

  @$internal
  @override
  ChatBubbleState create() => ChatBubbleState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, bool>>(value),
    );
  }
}

String _$chatBubbleStateHash() => r'462c9080c4696648bae6952449a9a5a55c8f3570';

/// 채팅 말풍선의 확장/축소 상태를 관리하는 Provider

abstract class _$ChatBubbleState extends $Notifier<Map<String, bool>> {
  Map<String, bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Map<String, bool>, Map<String, bool>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, bool>, Map<String, bool>>,
              Map<String, bool>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
