import 'dart:async'; // Timer를 사용하기 위해 추가
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sidebar_provider.g.dart';

/// 사이드바 확장/축소 상태
@riverpod
class SidebarExpanded extends _$SidebarExpanded {
  Timer? _timer; // 콘텐츠 표시 지연을 위한 타이머

  @override
  bool build() {
    // 프로바이더가 소멸될 때 타이머를 정리합니다.
    ref.onDispose(() {
      _timer?.cancel();
    });
    return false; // 기본값: 축소 상태
  }

  void expand() {
    state = true;
    // 이전 타이머가 있다면 취소하고 새 타이머를 설정합니다.
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 150), () {
      ref.read(sidebarContentVisibleProvider.notifier).show();
    });
  }

  void collapse() {
    state = false;
    // 확장 시 예약된 타이머가 있다면 취소합니다.
    _timer?.cancel();
    ref.read(sidebarContentVisibleProvider.notifier).hide();
  }

  void toggle() {
    if (state) {
      collapse();
    } else {
      expand();
    }
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