import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/logger.dart';

/// Provider (Riverpod 3.0)
final sidebarStateProvider = NotifierProvider<SidebarStateNotifier, SidebarState>(
  SidebarStateNotifier.new,
);

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

  bool get shouldShowExpanded => isExpanded || isHovering;
}

/// Notifier
class SidebarStateNotifier extends Notifier<SidebarState> {
  @override
  SidebarState build() {
    return const SidebarState(
      isExpanded: false,
      isHovering: false,
    );
  }

  void toggle() {
    Logger.info('Sidebar toggle: ${!state.isExpanded}');
    state = state.copyWith(isExpanded: !state.isExpanded);
  }

  void startHover() {
    if (!state.isExpanded) {
      Logger.debug('Sidebar hover started (collapsed)');
      state = state.copyWith(isHovering: true);
    }
  }

  void endHover() {
    if (state.isHovering) {
      Logger.debug('Sidebar hover ended');
      state = state.copyWith(isHovering: false);
    }
  }

  void expand() {
    if (!state.isExpanded) {
      Logger.info('Sidebar expanded');
      state = state.copyWith(isExpanded: true);
    }
  }

  void collapse() {
    if (state.isExpanded) {
      Logger.info('Sidebar collapsed');
      state = state.copyWith(isExpanded: false);
    }
  }
}
