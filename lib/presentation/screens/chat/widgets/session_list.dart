import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../domain/mutations/create_session_mutation.dart';
import '../../../../../../domain/providers/database_provider.dart';
import '../../../../../../domain/providers/sidebar_state_provider.dart';
import '../../../../../../core/constants/ui_constants.dart';
import '../../../shared/widgets/adaptive_loading.dart';
import 'session_tile.dart';

class SessionList extends ConsumerStatefulWidget {
  const SessionList({super.key});

  @override
  ConsumerState<SessionList> createState() => _SessionListState();
}

class _SessionListState extends ConsumerState<SessionList> {
  bool _showExpandedContent = false;
  Timer? _expansionTimer;

  @override
  void dispose() {
    _expansionTimer?.cancel();
    super.dispose();
  }

  void _handleSidebarStateChange(bool shouldShowExpanded) {
    // 기존 타이머 취소 (레이스 컨디션 방지)
    _expansionTimer?.cancel();

    if (shouldShowExpanded) {
      // 확대: 애니메이션 완료 후 콘텐츠 확대
      _expansionTimer = Timer(UIConstants.sidebarAnimationDuration, () {
        if (mounted) {
          setState(() {
            _showExpandedContent = true;
          });
        }
      });
    } else {
      // 축소: 즉시 콘텐츠 축소
      if (mounted) {
        setState(() {
          _showExpandedContent = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(chatSessionsProvider);
    final sidebarState = ref.watch(sidebarStateProvider);

    // 실제 표시될 너비 계산
    final displayWidth = sidebarState.shouldShowExpanded
        ? UIConstants.sessionListWidth
        : UIConstants.sessionListCollapsedWidth;

    // 사이드바 상태 변경 감지
    final shouldShowExpanded = sidebarState.shouldShowExpanded;
    if (shouldShowExpanded != (_expansionTimer?.isActive ?? false ? !_showExpandedContent : _showExpandedContent)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSidebarStateChange(shouldShowExpanded);
      });
    }

    return MouseRegion(
      onEnter: (_) => ref.read(sidebarStateProvider.notifier).startHover(),
      onExit: (_) => ref.read(sidebarStateProvider.notifier).endHover(),
      child: AnimatedContainer(
        duration: UIConstants.sidebarAnimationDuration,
        curve: Curves.easeInOut,
        width: displayWidth,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // 헤더 영역 (애니메이션 타이밍 적용)
            Container(
              height: 56,
              padding: EdgeInsets.symmetric(
                horizontal: _showExpandedContent
                    ? UIConstants.spacingSm
                    : UIConstants.spacingXs,
                vertical: UIConstants.spacingXs,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: _showExpandedContent
                  ? _buildExpandedHeader(context, ref)
                  : _buildCollapsedHeader(context, ref),
            ),
            // 세션 리스트
            Expanded(
              child: sessionsAsync.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return _showExpandedContent
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          const SizedBox(height: UIConstants.spacingMd),
                          Text(
                            '대화 내역이 없습니다',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    )
                        : const SizedBox.shrink();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: UIConstants.spacingSm,
                    ),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      return SessionTile(
                        key: ValueKey('session-${sessions[index].id}'),
                        session: sessions[index],
                        isCollapsed: !_showExpandedContent,
                      );
                    },
                  );
                },
                loading: () => const AdaptiveLoading(
                  message: '로딩 중...',
                  size: 40,
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: UIConstants.spacingMd),
                      const Text('대화 내역을 불러올 수 없습니다'),
                      const SizedBox(height: UIConstants.spacingSm),
                      Text(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 확대 상태 헤더
  Widget _buildExpandedHeader(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.menu_open),
          iconSize: 20,
          tooltip: '사이드바 축소',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          onPressed: () {
            ref.read(sidebarStateProvider.notifier).toggle();
          },
        ),
        Expanded(
          child: Text(
            '대화 내역',
            style: Theme.of(context).textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          iconSize: 20,
          tooltip: '새 대화',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          onPressed: () => createNewSession(ref),
        ),
      ],
    );
  }

  /// 축소 상태 헤더
  Widget _buildCollapsedHeader(BuildContext context, WidgetRef ref) {
    return Center(
      child: IconButton(
        icon: const Icon(Icons.menu),
        iconSize: 20,
        tooltip: '사이드바 확대',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        onPressed: () {
          ref.read(sidebarStateProvider.notifier).toggle();
        },
      ),
    );
  }
}
