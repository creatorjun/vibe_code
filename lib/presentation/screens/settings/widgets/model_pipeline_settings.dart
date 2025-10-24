// lib/presentation/screens/settings/widgets/model_pipeline_settings.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../domain/providers/settings_provider.dart';
import '../../../../data/models/settings_state.dart';
import 'model_config_card.dart';
import 'add_model_dialog.dart';

class ModelPipelineSettings extends ConsumerWidget {
  const ModelPipelineSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ 섹션 헤더 (현대적 디자인)
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(UIConstants.spacingXs),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(UIConstants.radiusSm),
              ),
              child: Icon(
                Icons.settings_suggest_outlined,
                size: UIConstants.iconMd,
              ),
            ),
            const SizedBox(width: UIConstants.spacingSm),
            Expanded(
              child: Text(
                '모델 파이프라인',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // ✅ 카운터 뱃지
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
                  '${settings.enabledModels.length}/5',
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

        // ✅ 설명 개선
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
                '최대 5개의 모델을 순차적으로 실행할 수 있습니다',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withAlpha(UIConstants.alpha60),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: UIConstants.spacingMd),

        // ✅ 카드로 감싸기
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
              data: (settings) => _buildPipelineList(context, ref, settings),
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
                      Icon(
                        Icons.error_outline,
                      ),
                      const SizedBox(width: UIConstants.spacingSm),
                      Expanded(
                        child: Text(
                          '설정을 불러올 수 없습니다: $error',
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

  Widget _buildPipelineList(
      BuildContext context,
      WidgetRef ref,
      SettingsState settings,
      ) {
    return Column(
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) async {
            try {
              await ref
                  .read(settingsProvider.notifier)
                  .reorderModels(oldIndex, newIndex);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('순서 변경 실패: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          itemCount: settings.modelPipeline.length,
          itemBuilder: (context, index) {
            final config = settings.modelPipeline[index];
            return ModelConfigCard(
              key: ValueKey('model_${config.modelId}_$index'),
              config: config,
              index: index,
              canRemove: settings.modelPipeline.length > 1,
              onRemove: () => _removeModel(context, ref, index),
              onToggle: () => _toggleModel(context, ref, index),
              onUpdateModel: (modelId) =>
                  _updateModelId(context, ref, index, modelId),
              onUpdatePrompt: (prompt) =>
                  _updateSystemPrompt(context, ref, index, prompt),
            );
          },
        ),
        const SizedBox(height: UIConstants.spacingMd),
        if (settings.canAddMoreModels)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddModelDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('모델 추가'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: UIConstants.spacingMd,
                  horizontal: UIConstants.spacingLg,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showAddModelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AddModelDialog(
        onAdd: (modelId, systemPrompt) async {
          try {
            await ref
                .read(settingsProvider.notifier)
                .addModel(modelId, systemPrompt: systemPrompt);
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('모델이 추가되었습니다'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('모델 추가 실패: $e'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _removeModel(
      BuildContext context,
      WidgetRef ref,
      int index,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('모델 제거'),
        content: const Text('이 모델을 파이프라인에서 제거하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('제거'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(settingsProvider.notifier).removeModel(index);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('모델이 제거되었습니다'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('모델 제거 실패: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleModel(
      BuildContext context,
      WidgetRef ref,
      int index,
      ) async {
    try {
      await ref.read(settingsProvider.notifier).toggleModel(index);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('모델 토글 실패: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateModelId(
      BuildContext context,
      WidgetRef ref,
      int index,
      String modelId,
      ) async {
    try {
      await ref
          .read(settingsProvider.notifier)
          .updateModelConfig(index, modelId: modelId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('모델 변경 실패: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateSystemPrompt(
      BuildContext context,
      WidgetRef ref,
      int index,
      String prompt,
      ) async {
    try {
      await ref
          .read(settingsProvider.notifier)
          .updateModelConfig(index, systemPrompt: prompt);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('시스템 프롬프트 변경 실패: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
