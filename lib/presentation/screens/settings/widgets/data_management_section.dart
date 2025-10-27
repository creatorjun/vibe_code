// lib/presentation/screens/settings/widgets/data_management_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_code/presentation/screens/settings/widgets/settings_section_header.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../domain/providers/chat_provider.dart';
import 'settings_card.dart';
import 'delete_confirmation_dialog.dart';

class DataManagementSection extends ConsumerWidget {
  const DataManagementSection({super.key});

  Future<void> _showDeleteAllConfirmation(
      BuildContext context,
      WidgetRef ref,
      ) async {
    final confirmed = await showDeleteConfirmationDialog(context);

    if (confirmed == true && context.mounted) {
      try {
        // 모든 대화 삭제
        await ref.read(chatRepositoryProvider).deleteAllConversations();

        // 활성 세션 초기화
        ref.read(activeSessionProvider.notifier).clear();

        if (context.mounted) {
          _showSuccessSnackBar(context);
        }
      } catch (e) {
        if (context.mounted) {
          _showErrorSnackBar(context, e);
        }
      }
    }
  }

  void _showSuccessSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: UIConstants.spacingSm),
            Text('모든 대화 내역이 삭제되었습니다'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusMd),
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: UIConstants.spacingSm),
            Expanded(child: Text('삭제 실패: $error')),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusMd),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(
          icon: Icons.storage_rounded,
          title: '데이터 관리',
          color: colorScheme.error,
        ),
        const SizedBox(height: UIConstants.spacingMd),
        SettingsCard(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(UIConstants.spacingSm),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(UIConstants.radiusSm),
              ),
              child: const Icon(Icons.delete_forever_rounded),
            ),
            title: const Text(
              '모든 대화 내역 삭제',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('저장된 모든 대화와 첨부파일을 삭제합니다'),
            trailing: Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: () => _showDeleteAllConfirmation(context, ref),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: UIConstants.spacingMd,
              vertical: UIConstants.spacingSm,
            ),
          ),
        ),
      ],
    );
  }
}
