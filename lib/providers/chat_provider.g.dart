// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 채팅 말풍선의 확장/축소 상태를 관리하는 Provider

@ProviderFor(ChatBubbleExpansion)
const chatBubbleExpansionProvider = ChatBubbleExpansionProvider._();

/// 채팅 말풍선의 확장/축소 상태를 관리하는 Provider
final class ChatBubbleExpansionProvider
    extends $NotifierProvider<ChatBubbleExpansion, Map<String, bool>> {
  /// 채팅 말풍선의 확장/축소 상태를 관리하는 Provider
  const ChatBubbleExpansionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatBubbleExpansionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatBubbleExpansionHash();

  @$internal
  @override
  ChatBubbleExpansion create() => ChatBubbleExpansion();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, bool>>(value),
    );
  }
}

String _$chatBubbleExpansionHash() =>
    r'bcdcc2d45067b6305a54ef0a0f63ae434bd63fc5';

/// 채팅 말풍선의 확장/축소 상태를 관리하는 Provider

abstract class _$ChatBubbleExpansion extends $Notifier<Map<String, bool>> {
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
