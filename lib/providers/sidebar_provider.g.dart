// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sidebar_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 사이드바 확장/축소 상태

@ProviderFor(SidebarExpanded)
const sidebarExpandedProvider = SidebarExpandedProvider._();

/// 사이드바 확장/축소 상태
final class SidebarExpandedProvider
    extends $NotifierProvider<SidebarExpanded, bool> {
  /// 사이드바 확장/축소 상태
  const SidebarExpandedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sidebarExpandedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sidebarExpandedHash();

  @$internal
  @override
  SidebarExpanded create() => SidebarExpanded();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$sidebarExpandedHash() => r'613c96394399946a65b19a1b92c0bf29d2eb3c7e';

/// 사이드바 확장/축소 상태

abstract class _$SidebarExpanded extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// 사이드바 콘텐츠 표시 여부 (애니메이션 딜레이용)

@ProviderFor(SidebarContentVisible)
const sidebarContentVisibleProvider = SidebarContentVisibleProvider._();

/// 사이드바 콘텐츠 표시 여부 (애니메이션 딜레이용)
final class SidebarContentVisibleProvider
    extends $NotifierProvider<SidebarContentVisible, bool> {
  /// 사이드바 콘텐츠 표시 여부 (애니메이션 딜레이용)
  const SidebarContentVisibleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sidebarContentVisibleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sidebarContentVisibleHash();

  @$internal
  @override
  SidebarContentVisible create() => SidebarContentVisible();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$sidebarContentVisibleHash() =>
    r'a3153c41f1d5bbe109b1c77e46aade91e04f06fb';

/// 사이드바 콘텐츠 표시 여부 (애니메이션 딜레이용)

abstract class _$SidebarContentVisible extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
