import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sidebar_provider.g.dart';

/// 사이드바 확장/축소 상태
@riverpod
class SidebarExpanded extends _$SidebarExpanded {
  @override
  bool build() {
    return false; // 기본값: 축소 상태
  }

  void expand() {
    state = true;
  }

  void collapse() {
    state = false;
  }

  void toggle() {
    state = !state;
  }
}

/// 사이드바 콘텐츠 표시 여부 (애니메이션 딜레이용)
@riverpod
class SidebarContentVisible extends _$SidebarContentVisible {
  @override
  bool build() {
    return false; // 기본값: 콘텐츠 숨김
  }

  void show() {
    state = true;
  }

  void hide() {
    state = false;
  }
}
