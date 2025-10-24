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

  Future<void> _showDeleteAllConfirmation(
      BuildContext context, WidgetRef ref) async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.warning_rounded,
          color: colorScheme.error,
          size: UIConstants.iconLg * 1.5,
        ),
        title: const Text('모든 대화 삭제'),
        content: const Text(
          '정말로 모든 대화 내역을 삭제하시겠습니까?\n\n'
              '이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
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
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: UIConstants.spacingSm),
                  Expanded(child: Text('삭제 실패: $e')),
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
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // ✅ 현대적인 AppBar
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 3,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(UIConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ API 설정
            const ApiSettings(),
            const SizedBox(height: UIConstants.spacingLg),

            // ✅ 모델 파이프라인 설정
            const ModelPipelineSettings(),
            const SizedBox(height: UIConstants.spacingLg),

            // ✅ 테마 선택
            const ThemeSelector(),
            const SizedBox(height: UIConstants.spacingLg),

            // ✅ 데이터 관리 섹션 (현대적 디자인)
            _SectionHeader(
              icon: Icons.storage_rounded,
              title: '데이터 관리',
              color: colorScheme.error,
            ),
            const SizedBox(height: UIConstants.spacingMd),
            _SettingsCard(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(UIConstants.spacingSm),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(UIConstants.radiusSm),
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                  ),
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

            const SizedBox(height: UIConstants.spacingLg),

            // ✅ 앱 정보 섹션 (현대적 디자인)
            _SectionHeader(
              icon: Icons.info_outline_rounded,
              title: '앱 정보',
              color: colorScheme.primary,
            ),
            const SizedBox(height: UIConstants.spacingMd),
            _SettingsCard(
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.verified_rounded,
                    title: '버전',
                    subtitle: AppConstants.appVersion,
                    color: colorScheme.primary,
                  ),
                  Divider(
                    height: 1,
                    indent: UIConstants.spacingMd,
                    endIndent: UIConstants.spacingMd,
                  ),
                  _InfoTile(
                    icon: Icons.code_rounded,
                    title: 'GitHub',
                    subtitle: 'creator-jun/vibe_code',
                    color: colorScheme.secondary,
                    onTap: () {
                      // GitHub 링크 열기 (선택사항)
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: UIConstants.spacingXl),
          ],
        ),
      ),
    );
  }
}

// ✅ 섹션 헤더 위젯
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(UIConstants.spacingXs),
          decoration: BoxDecoration(
            color: color.withAlpha(UIConstants.alpha20),
            borderRadius: BorderRadius.circular(UIConstants.radiusSm),
          ),
          child: Icon(
            icon,
            size: UIConstants.iconMd,
            color: color,
          ),
        ),
        const SizedBox(width: UIConstants.spacingSm),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ✅ 설정 카드 위젯
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusLg),
        side: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withAlpha(UIConstants.alpha60),
        ),
      ),
      child: child,
    );
  }
}

// ✅ 정보 타일 위젯
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(UIConstants.spacingSm),
        decoration: BoxDecoration(
          color: color.withAlpha(UIConstants.alpha20),
          borderRadius: BorderRadius.circular(UIConstants.radiusSm),
        ),
        child: Icon(
          icon,
          color: color,
          size: UIConstants.iconMd,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: onTap != null
          ? Icon(
        Icons.open_in_new,
        size: UIConstants.iconSm,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      )
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacingMd,
        vertical: UIConstants.spacingSm,
      ),
    );
  }
}
