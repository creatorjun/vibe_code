// lib/presentation/screens/chat/widgets/session_list.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../domain/providers/database_provider.dart';
import '../../../shared/widgets/adaptive_loading.dart';
import 'session_tile.dart';

class SessionList extends ConsumerWidget {
  final bool isExpanded;

  const SessionList({
    super.key,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(chatSessionsProvider);

    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(UIConstants.spacingSm),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            return SessionTile(
              key: ValueKey('session-${sessions[index].id}'),
              session: sessions[index],
              isCollapsed: !isExpanded,
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
            padding: const EdgeInsets.all(UIConstants.spacingMd),
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
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    if (isExpanded) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: UIConstants.iconLg * 1.5,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(UIConstants.alpha30),
              ),
              const SizedBox(height: UIConstants.spacingMd),
              Text(
                '대화가 없습니다',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha(UIConstants.alpha60),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
