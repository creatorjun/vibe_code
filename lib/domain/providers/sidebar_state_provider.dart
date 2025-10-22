import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/logger.dart';

/// 사이드바 상태 Provider (Riverpod 3.0)
final sidebarStateProvider = NotifierProvider<SidebarStateNotifier, SidebarState>(
  SidebarStateNotifier.new,
);

/// 사이드바 상태 모델
class SidebarState {
  final bool isExpanded;
  final bool isHovering;

  const SidebarState({
    required this.isExpanded,
    required this.isHovering,
  });

  SidebarState copyWith({
    bool? isExpanded,
    bool? isHovering,
  }) {
    return SidebarState(
      isExpanded: isExpanded ?? this.isExpanded,
      isHovering: isHovering ?? this.isHovering,
    );
  }

  /// 실제 표시될 너비 계산
  bool get shouldShowExpanded => isExpanded || isHovering;
}

/// 사이드바 상태 Notifier
class SidebarStateNotifier extends Notifier<SidebarState> {
  @override
  SidebarState build() {
    return const SidebarState(
      isExpanded: false, // ✅ 축소된 상태로 시작 (true → false)
      isHovering: false,
    );
  }

  /// 확대/축소 토글
  void toggle() {
    Logger.info('Sidebar toggle: ${!state.isExpanded}');
    state = state.copyWith(isExpanded: !state.isExpanded);
  }

  /// 호버 시작
  void startHover() {
    if (!state.isExpanded) {
      Logger.debug('Sidebar hover started (collapsed state)');
      state = state.copyWith(isHovering: true);
    }
  }

  /// 호버 종료
  void endHover() {
    if (state.isHovering) {
      Logger.debug('Sidebar hover ended');
      state = state.copyWith(isHovering: false);
    }
  }

  /// 확대 상태로 설정
  void expand() {
    if (!state.isExpanded) {
      Logger.info('Sidebar expanded');
      state = state.copyWith(isExpanded: true);
    }
  }

  /// 축소 상태로 설정
  void collapse() {
    if (state.isExpanded) {
      Logger.info('Sidebar collapsed');
      state = state.copyWith(isExpanded: false);
    }
  }
}
