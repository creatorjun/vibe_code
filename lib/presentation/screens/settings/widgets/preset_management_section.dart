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
                Icons.bookmark_outline,
                size: UIConstants.iconMd,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: UIConstants.spacingSm),
            Expanded(
              child: Text(
                '프리셋 관리',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: UIConstants.spacingSm),

        // 설명
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
                '프리셋을 더블클릭하여 이름을 변경하거나 삭제할 수 있습니다',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withAlpha(UIConstants.alpha60),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: UIConstants.spacingMd),

        // 프리셋 목록
        settingsAsync.when(
          data: (settings) {
            if (settings.promptPresets.isEmpty) {
              return _buildEmptyState(context);
            }

            return Column(
              children: settings.promptPresets.map((preset) {
                return _PresetCard(
                  preset: preset,
                  isSelected: settings.selectedPresetId == preset.id,
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(UIConstants.spacingMd),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => _buildErrorState(context, error),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusMd),
        side: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withAlpha(UIConstants.alpha60),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacingLg),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.bookmark_border,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(UIConstants.alpha30),
              ),
              const SizedBox(height: UIConstants.spacingSm),
              Text(
                '저장된 프리셋이 없습니다',
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
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacingMd),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: UIConstants.spacingSm),
            Expanded(
              child: Text(
                '프리셋 로드 실패: $error',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetCard extends ConsumerWidget {
  final PromptPreset preset;
  final bool isSelected;

  const _PresetCard({
    required this.preset,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: UIConstants.spacingMd),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusMd),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary.withAlpha(UIConstants.alpha60)
              : colorScheme.outlineVariant.withAlpha(UIConstants.alpha60),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(UIConstants.radiusMd),
        onDoubleTap: () => _showRenameDialog(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.spacingMd),
          child: Row(
            children: [
              // 아이콘
              Container(
                padding: const EdgeInsets.all(UIConstants.spacingSm),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(UIConstants.radiusSm),
                ),
                child: Icon(
                  Icons.bookmark,
                  size: UIConstants.iconMd,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
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
                      '${preset.prompts.length}개 모델 프롬프트',
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
                  // 이름 변경 버튼
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    iconSize: 20,
                    tooltip: '이름 변경',
                    onPressed: () => _showRenameDialog(context, ref),
                    color: colorScheme.primary,
                  ),
                  // 삭제 버튼 (기본 프리셋이 아닐 경우만)
                  if (preset.id != 'default')
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

  /// ✅ 이름 변경 다이얼로그
  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: preset.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프리셋 이름 변경'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '프리셋 이름',
            hintText: '새로운 이름을 입력하세요',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
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

  /// ✅ 프리셋 이름 변경 실행
  void _renamePreset(BuildContext context, WidgetRef ref, String newName) {
    ref.read(settingsProvider.notifier).renamePreset(preset.id, newName);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: UIConstants.spacingSm),
            Text('프리셋 이름이 "$newName"(으)로 변경되었습니다'),
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

  /// 삭제 확인 다이얼로그
  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프리셋 삭제'),
        content: Text('프리셋 "${preset.name}"을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).removePreset(preset.id);
              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.white),
                      SizedBox(width: UIConstants.spacingSm),
                      Text('프리셋이 삭제되었습니다'),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(UIConstants.radiusMd),
                  ),
                ),
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
