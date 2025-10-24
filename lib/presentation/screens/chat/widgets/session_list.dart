import 'dart:async';
import 'dart:ui';
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
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacingMd),
        child: AnimatedContainer(
          duration: UIConstants.sidebarAnimationDuration,
          curve: Curves.easeInOut,
          width: displayWidth,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(UIConstants.radiusLg),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: UIConstants.glassBlur,
                sigmaY: UIConstants.glassBlur,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withAlpha(UIConstants.alpha95),
                  borderRadius: BorderRadius.circular(UIConstants.radiusLg),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withAlpha(UIConstants.alpha20),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(UIConstants.alpha10),
                      blurRadius: UIConstants.radiusLg,
                      offset: const Offset(0, UIConstants.spacingXs),
                    ),
                  ],
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
                            padding: const EdgeInsets.all(
                              UIConstants.spacingSm,
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
                          size: UIConstants.iconLg + UIConstants.spacingSm,
                        ),
                        error: (error, stack) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(
                                UIConstants.spacingMd,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: UIConstants.iconLg * 1.5,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  const SizedBox(height: UIConstants.spacingMd),
                                  const Text('오류 발생'),
                                  const SizedBox(height: UIConstants.spacingSm),
                                  Text(
                                    error.toString(),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          ),
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
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withAlpha(UIConstants.alpha30),
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
          iconSize: UIConstants.iconSm,
          tooltip: '사이드바 접기',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: UIConstants.iconLg + UIConstants.spacingSm,
            minHeight: UIConstants.iconLg + UIConstants.spacingSm,
          ),
          onPressed: () {
            ref.read(sidebarStateProvider.notifier).toggle();
          },
        ),
        const SizedBox(width: UIConstants.spacingSm),
        Expanded(
          child: Text(
            '대화 목록',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          iconSize: UIConstants.iconMd,
          tooltip: '새 대화',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: UIConstants.iconLg + UIConstants.spacingSm,
            minHeight: UIConstants.iconLg + UIConstants.spacingSm,
          ),
          color: Theme.of(context).colorScheme.primary,
          onPressed: () => createNewSession(ref, '새로운 대화'),
        ),
      ],
    );
  }

  Widget _buildCollapsedHeader(BuildContext context, WidgetRef ref) {
    return Center(
      child: IconButton(
        icon: const Icon(Icons.menu),
        iconSize: UIConstants.iconSm,
        tooltip: '사이드바 펼치기',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: UIConstants.iconLg + UIConstants.spacingSm,
          minHeight: UIConstants.iconLg + UIConstants.spacingSm,
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
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withAlpha(UIConstants.alpha30),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToSettings(context),
        borderRadius: BorderRadius.circular(UIConstants.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(UIConstants.spacingMd),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withAlpha(UIConstants.alpha30),
            borderRadius: BorderRadius.circular(UIConstants.radiusMd),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withAlpha(UIConstants.alpha20),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                size: UIConstants.iconSm,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: UIConstants.spacingMd),
              Expanded(
                child: Text(
                  '설정',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: UIConstants.iconLg,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedFooter(BuildContext context) {
    return Center(
      child: IconButton(
        icon: const Icon(Icons.settings_outlined),
        iconSize: UIConstants.iconSm,
        tooltip: '설정',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: UIConstants.iconLg + UIConstants.spacingSm,
          minHeight: UIConstants.iconLg + UIConstants.spacingSm,
        ),
        color: Theme.of(context).colorScheme.primary,
        onPressed: () => _navigateToSettings(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    if (showExpandedContent) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: UIConstants.iconLg * 1.5,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha(UIConstants.alpha30),
              ),
              const SizedBox(height: UIConstants.spacingMd),
              Text(
                '대화가 없습니다',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withAlpha(UIConstants.alpha60),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }
}
