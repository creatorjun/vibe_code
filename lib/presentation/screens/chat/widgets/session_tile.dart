import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../data/database/app_database.dart';
import '../../../../../../domain/providers/chat_provider.dart';
import '../../../../../../core/constants/ui_constants.dart';
import '../../../../../../core/utils/date_formatter.dart';

class SessionTile extends ConsumerWidget {
  final ChatSession session;
  final bool isCollapsed;

  const SessionTile({
    super.key,
    required this.session,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = ref.watch(activeSessionProvider);
    final isActive = activeSession == session.id;

    // 축소 상태일 때는 아이콘만 표시
    if (isCollapsed) {
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
        child: IconButton(
          icon: Icon(
            Icons.chat_bubble_outline,
            size: 20,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).iconTheme.color,
          ),
          tooltip: session.title,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          onPressed: () {
            ref.read(activeSessionProvider.notifier).select(session.id);
          },
        ),
      );
    }

    // 확대 상태일 때는 커스텀 레이아웃으로 전체 내용 표시
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(UIConstants.radiusMd),
          onTap: () {
            ref.read(activeSessionProvider.notifier).select(session.id);
          },
          child: Padding(
            padding: const EdgeInsets.all(UIConstants.spacingSm),
            child: Row(
              children: [
                // 아이콘
                Icon(
                  Icons.chat_bubble_outline,
                  size: 18,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).iconTheme.color,
                ),
                const SizedBox(width: UIConstants.spacingSm),
                // 텍스트 영역
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onDoubleTap: () => _showRenameDialog(context, ref),
                        child: Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormatter.formatChatTime(session.updatedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: UIConstants.spacingXs),
                // 삭제 버튼
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  iconSize: 16,
                  tooltip: '삭제',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: () => _showDeleteConfirmation(context, ref),
                ),
              ],
            ),
          ),
        ),
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
            labelText: '세션 이름',
            hintText: '새 이름을 입력하세요',
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.of(dialogContext).pop();
              ref
                  .read(chatRepositoryProvider)
                  .updateSessionTitle(session.id, value.trim());
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
                ref
                    .read(chatRepositoryProvider)
                    .updateSessionTitle(session.id, newTitle);
              }
            },
            child: const Text('저장'),
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
        content: const Text('정말로 이 대화 세션을 삭제하시겠습니까?\n삭제된 데이터는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();

              // ✅ 원본에는 없던 로직: 현재 활성 세션이면 초기화
              final activeSession = ref.read(activeSessionProvider);
              if (activeSession == session.id) {
                ref.read(activeSessionProvider.notifier).clear();
              }

              // 원본 그대로: 세션 삭제만 수행
              ref.read(chatRepositoryProvider).deleteSession(session.id);
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
