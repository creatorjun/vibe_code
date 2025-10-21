import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/mutations/create_session_mutation.dart';
import '../../../../domain/providers/database_provider.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../shared/widgets/adaptive_loading.dart';
import 'session_tile.dart';

class SessionList extends ConsumerWidget {
  const SessionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(chatSessionsProvider);

    return Container(
      width: UIConstants.sessionListWidth,
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
          Container(
            padding: const EdgeInsets.all(UIConstants.spacingMd),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '대화 목록',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: '새 대화',
                  onPressed: () => createNewSession(ref),
                ),
              ],
            ),
          ),
          Expanded(
            child: sessionsAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return Center(
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
                          '대화가 없습니다',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: UIConstants.spacingSm),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    return SessionTile(
                      key: ValueKey('session_${sessions[index].id}'),
                      session: sessions[index],
                    );
                  },
                );
              },
              loading: () => const AdaptiveLoading(
                message: '대화 목록 로딩 중...',
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
                    Text(
                      '대화 목록을 불러올 수 없습니다',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
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
    );
  }
}
