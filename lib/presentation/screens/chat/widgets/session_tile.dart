import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/database/app_database.dart';
import '../../../../domain/providers/chat_provider.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/utils/date_formatter.dart';

class SessionTile extends ConsumerWidget {
  final ChatSession session;

  const SessionTile({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = ref.watch(activeSessionProvider);
    final isActive = activeSession == session.id;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacingSm,
        vertical: UIConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary.withAlpha(26)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(UIConstants.radiusMd),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: UIConstants.spacingMd,
          vertical: UIConstants.spacingSm,
        ),
        leading: Icon(
          Icons.chat_bubble_outline,
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).iconTheme.color,
        ),
        title: GestureDetector(
          onDoubleTap: () => _showRenameDialog(context, ref),
          child: Text(
            session.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        subtitle: Text(
          DateFormatter.formatChatTime(session.updatedAt),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: '삭제',
          iconSize: 20,
          onPressed: () => _showDeleteConfirmation(context, ref),
        ),
        onTap: () {
          ref.read(activeSessionProvider.notifier).select(session.id);
        },
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: session.title);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('세션 이름 변경'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '새 이름',
            hintText: '세션 이름을 입력하세요',
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.of(dialogContext).pop();
              ref.read(chatRepositoryProvider).updateSessionTitle(
                session.id,
                value.trim(),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                Navigator.of(dialogContext).pop();
                ref.read(chatRepositoryProvider).updateSessionTitle(
                  session.id,
                  newTitle,
                );
              }
            },
            child: const Text('변경'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('세션 삭제'),
        content: const Text('이 대화를 삭제하시겠습니까?\n삭제된 대화는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(sessionDeleterProvider.notifier).deleteSession(session.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
