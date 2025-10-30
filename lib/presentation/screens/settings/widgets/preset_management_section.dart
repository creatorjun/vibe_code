// lib/presentation/screens/settings/widgets/preset_management_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/ui_constants.dart';
import '../../../../domain/providers/settings_provider.dart';
import '../../../../data/models/settings_state.dart';

class PresetManagementSection extends ConsumerWidget {
  const PresetManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(UIConstants.spacingXs),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(UIConstants.radiusSm),
              ),
              child: Icon(
                Icons.auto_awesome_outlined,
                size: UIConstants.iconMd,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: UIConstants.spacingSm),
            Expanded(
              child: Text(
                '프롬프트 프리셋',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // 프리셋 개수 표시 (파이프라인 스타일)
            settingsAsync.when(
              data: (settings) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: UIConstants.spacingSm,
                  vertical: UIConstants.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(UIConstants.radiusLg),
                ),
                child: Text(
                  '${settings.promptPresets.length}/5',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: UIConstants.spacingSm),
        // 안내 문구
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: UIConstants.iconSm,
              color: colorScheme.secondary,
            ),
            const SizedBox(width: UIConstants.spacingXs),
            Expanded(
              child: Text(
                '프리셋은 최대 5개까지 생성할 수 있습니다',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withAlpha(UIConstants.alpha60),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: UIConstants.spacingMd),
        // 프리셋 카드 (파이프라인 스타일)
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.radiusLg),
            side: BorderSide(
              color: colorScheme.outlineVariant.withAlpha(UIConstants.alpha60),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(UIConstants.spacingMd),
            child: settingsAsync.when(
              data: (settings) => _buildPresetList(context, ref, settings),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(UIConstants.spacingLg),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(UIConstants.spacingLg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline),
                      const SizedBox(width: UIConstants.spacingSm),
                      Expanded(
                        child: Text(
                          '$error',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetList(BuildContext context, WidgetRef ref, SettingsState settings) {
    return Column(
      children: [
        // 프리셋 목록
        ...settings.promptPresets.asMap().entries.map((entry) {
          final index = entry.key;
          final preset = entry.value;
          final isSelected = settings.selectedPresetId == preset.id;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index < settings.promptPresets.length - 1
                  ? UIConstants.spacingMd
                  : 0,
            ),
            child: _PresetCard(
              preset: preset,
              index: index,
              isSelected: isSelected,
            ),
          );
        }),

        // 프리셋 추가 버튼 (파이프라인 스타일)
        if (settings.promptPresets.length < 5) ...[
          const SizedBox(height: UIConstants.spacingMd),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddPresetDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('프리셋 추가'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: UIConstants.spacingMd,
                  horizontal: UIConstants.spacingLg,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showAddPresetDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 프리셋 추가'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '프리셋 이름',
            hintText: '프리셋 이름을 입력하세요..',
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              ref.read(settingsProvider.notifier).addEmptyPreset(value.trim());
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(settingsProvider.notifier).addEmptyPreset(name);
                Navigator.of(context).pop();
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
}

class _PresetCard extends ConsumerWidget {
  final PromptPreset preset;
  final int index;
  final bool isSelected;

  const _PresetCard({
    required this.preset,
    required this.index,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusMd),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary.withAlpha(UIConstants.alpha30)
              : colorScheme.outlineVariant.withAlpha(UIConstants.alpha60),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(UIConstants.radiusMd),
        onTap: () {
          ref.read(settingsProvider.notifier).selectPreset(preset.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.spacingMd),
          child: Row(
            children: [
              // 인덱스 표시 (파이프라인 스타일)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: UIConstants.spacingSm,
                  vertical: UIConstants.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(UIConstants.radiusSm),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: UIConstants.spacingMd),
              // 프리셋 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: UIConstants.spacingXs),
                    Text(
                      '프롬프트 ${preset.prompts.length}개',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // 액션 버튼
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    iconSize: 20,
                    tooltip: '이름 변경',
                    onPressed: () => _showRenameDialog(context, ref),
                    color: colorScheme.primary,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    iconSize: 20,
                    tooltip: '삭제',
                    onPressed: () => _confirmDelete(context, ref),
                    color: colorScheme.error,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: preset.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프리셋 이름 변경'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '새 이름',
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _renamePreset(context, ref, value.trim());
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                _renamePreset(context, ref, newName);
                Navigator.of(context).pop();
              }
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  void _renamePreset(BuildContext context, WidgetRef ref, String newName) {
    ref.read(settingsProvider.notifier).renamePreset(preset.id, newName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('프리셋 이름이 "$newName"(으)로 변경되었습니다'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프리셋 삭제'),
        content: Text('"${preset.name}" 프리셋을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).deletePreset(preset.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('프리셋이 삭제되었습니다')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
