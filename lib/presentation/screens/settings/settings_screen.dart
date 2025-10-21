// lib/presentation/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../domain/providers/chat_provider.dart';
import 'widgets/api_settings.dart';
import 'widgets/model_pipeline_settings.dart';
import 'widgets/theme_selector.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _showDeleteAllConfirmation(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('⚠️ 모든 대화 삭제'),
        content: const Text(
          '정말로 모든 대화 내역을 삭제하시겠습니까?\n\n'
              '이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // 모든 대화 삭제
        await ref.read(chatRepositoryProvider).deleteAllConversations();

        // 활성 세션 초기화
        ref.read(activeSessionProvider.notifier).clear();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 모든 대화 내역이 삭제되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ 삭제 실패: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(UIConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ApiSettings(),
            const SizedBox(height: UIConstants.spacingXl),
            const ModelPipelineSettings(),
            const SizedBox(height: UIConstants.spacingXl),
            const ThemeSelector(),
            const SizedBox(height: UIConstants.spacingXl),

            // ✅ 데이터 관리 섹션
            Text(
              '데이터 관리',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: UIConstants.spacingMd),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.delete_forever,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: const Text('모든 대화 내역 삭제'),
                subtitle: const Text('저장된 모든 대화와 첨부파일을 삭제합니다'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDeleteAllConfirmation(context, ref),
              ),
            ),

            const SizedBox(height: UIConstants.spacingXl),

            // 기존 앱 정보
            Text(
              '앱 정보',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: UIConstants.spacingMd),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('버전'),
              subtitle: const Text(AppConstants.appVersion),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('GitHub'),
              subtitle: const Text('creator-jun/vibe_code'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
