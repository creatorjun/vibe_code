// lib/presentation/screens/chat/widgets/session_list.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/mutations/create_session_mutation.dart';
import '../../../../domain/providers/database_provider.dart';
import '../../../../domain/providers/sidebar_state_provider.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../shared/widgets/adaptive_loading.dart';
import '../../settings/settings_screen.dart';
import 'session_tile.dart';

class SessionList extends ConsumerStatefulWidget {
  const SessionList({super.key});

  @override
  ConsumerState<SessionList> createState() => _SessionListState();
}

class _SessionListState extends ConsumerState<SessionList> {
  bool showExpandedContent = false;
  Timer? _expansionTimer;

  @override
  void dispose() {
    _expansionTimer?.cancel();
    super.dispose();
  }

  void _handleSidebarStateChange(bool shouldShowExpanded) {
    _expansionTimer?.cancel();

    if (shouldShowExpanded) {
      _expansionTimer = Timer(UIConstants.sidebarAnimationDuration, () {
        if (mounted) {
          setState(() {
            showExpandedContent = true;
          });
        }
      });
    } else {
      if (mounted) {
        setState(() {
          showExpandedContent = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(chatSessionsProvider);
    final sidebarState = ref.watch(sidebarStateProvider);

    final displayWidth = sidebarState.shouldShowExpanded
        ? UIConstants.sessionListWidth
        : UIConstants.sessionListCollapsedWidth;

    final shouldShowExpanded = sidebarState.shouldShowExpanded;

    if (shouldShowExpanded !=
        (_expansionTimer?.isActive ?? false
            ? !showExpandedContent
            : showExpandedContent)) {
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
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            right: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            _buildHeader(context, ref),
            Expanded(
              child: sessionsAsync.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return _buildEmptyState(context);
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
                        isCollapsed: !showExpandedContent,
                      );
                    },
                  );
                },
                loading: () => const AdaptiveLoading(
                  message: '...',
                  size: 40,
                ),
                error: (error, stack) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: UIConstants.spacingMd),
                        const Text('오류 발생'),
                        const SizedBox(height: UIConstants.spacingSm),
                        Text(
                          error.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacingMd),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: showExpandedContent
          ? _buildExpandedHeader(context, ref)
          : _buildCollapsedHeader(context, ref),
    );
  }

  Widget _buildExpandedHeader(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.menu_open),
          iconSize: 20,
          tooltip: '사이드바 접기',
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
            '대화 목록',
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
          onPressed: () => createNewSession(ref, '새로운 대화'),
        ),
      ],
    );
  }

  Widget _buildCollapsedHeader(BuildContext context, WidgetRef ref) {
    return Center(
      child: IconButton(
        icon: const Icon(Icons.menu),
        iconSize: 20,
        tooltip: '사이드바 펼치기',
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

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacingMd),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: showExpandedContent
          ? _buildExpandedFooter(context)
          : _buildCollapsedFooter(context),
    );
  }

  Widget _buildExpandedFooter(BuildContext context) {
    return InkWell(
      onTap: () => _navigateToSettings(context),
      borderRadius: BorderRadius.circular(UIConstants.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: UIConstants.spacingMd,
          vertical: UIConstants.spacingSm,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(UIConstants.radiusMd),
        ),
        child: Row(
          children: [
            Icon(
              Icons.settings_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: UIConstants.spacingSm),
            Expanded(
              child: Text(
                '설정',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedFooter(BuildContext context) {
    return Center(
      child: IconButton(
        icon: const Icon(Icons.settings_outlined),
        iconSize: 20,
        tooltip: '설정',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        onPressed: () => _navigateToSettings(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    if (showExpandedContent) {
      return Center(
        child: Text(
          '대화가 없습니다',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }
}
