// lib/presentation/screens/chat/widgets/right_buttons.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../data/models/settings_state.dart';
import '../../../../domain/providers/selected_model_count_provider.dart';
import '../../../../domain/providers/settings_provider.dart';

class RightButtons extends ConsumerWidget {
  final bool isSending;
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback onCancel;

  const RightButtons({
    super.key,
    required this.isSending,
    required this.canSend,
    required this.onSend,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 파이프라인 깊이 선택기
        IntrinsicWidth(child: _buildPipelineDepthSelector(context, ref)),
        const SizedBox(width: UIConstants.spacingMd),
        // 프리셋 선택기
        IntrinsicWidth(child: _buildPresetSelector(context, ref)),
        const SizedBox(width: UIConstants.spacingMd),
        // 전송/취소 버튼
        _buildSendButton(context),
      ],
    );
  }

  // 파이프라인 깊이 선택기 위젯
  Widget _buildPipelineDepthSelector(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final selectedDepth = ref.watch(selectedPipelineDepthProvider);

    return settingsAsync.when(
      data: (settings) {
        // 실제 사용 가능한 모델 수 (활성화된 모델 수)
        final availableModels = settings.enabledModels.length;
        // 선택 가능한 최대 깊이 (활성화된 모델 수 또는 최대 파이프라인 모델 수 중 작은 값)
        final maxDepth = availableModels < AppConstants.maxPipelineModels
            ? availableModels
            : AppConstants.maxPipelineModels;
        // 최소 깊이는 1
        final minDepth = AppConstants.minPipelineModels;
        // 선택된 깊이가 유효한 범위 내에 있는지 확인하고 조정
        final currentValidDepth = selectedDepth.clamp(minDepth, maxDepth);

        // 파이프라인 깊이 선택 버튼 생성 (1부터 maxDepth까지)
        final buttons = List.generate(maxDepth, (index) {
          final depth = index + 1;
          final isSelected = depth == currentValidDepth;
          return Padding(
            // 버튼 사이 간격 추가
            padding: const EdgeInsets.only(right: UIConstants.spacingSm),
            child: FilterChip(
              label: Text('$depth'),
              selected: isSelected,
              onSelected: (_) {
                ref
                    .read(selectedPipelineDepthProvider.notifier)
                    .setDepth(depth);
              },
              showCheckmark: false,
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: isSelected
                  ? BorderSide.none
                  : BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withAlpha(UIConstants.alpha90),
                    ),
              // dense하게 만들기 위해 패딩 조절
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              labelPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          );
        });

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(children: buttons),
        );
      },
      loading: () => const SizedBox(height: 40),
      error: (_, __) => const SizedBox(height: 40),
    );
  }

  // 프리셋 선택기 위젯
  Widget _buildPresetSelector(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) {
        final presets = settings.promptPresets;
        final selectedPresetId = settings.selectedPresetId;

        if (presets.isEmpty) {
          return const SizedBox.shrink();
        }

        return Row(
          children: [
            const SizedBox(width: UIConstants.spacingMd),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...presets.map((preset) {
                      final isSelected = preset.id == selectedPresetId;
                      return Padding(
                        padding: const EdgeInsets.only(
                          right: UIConstants.spacingSm,
                        ),
                        child: _buildPresetButton(
                          context,
                          ref,
                          preset: preset,
                          isSelected: isSelected,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (err, stack) => Tooltip(
        message: '프리셋 로딩 실패: ${err.toString()}',
        child: Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  // 프리셋 버튼 위젯
  Widget _buildPresetButton(
    BuildContext context,
    WidgetRef ref, {
    required PromptPreset preset,
    required bool isSelected,
  }) {
    final String label = preset.name;
    const IconData icon = Icons.auto_awesome;

    return FilterChip(
      label: Text(label),
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.secondary,
      ),
      selected: isSelected,
      onSelected: (_) {
        if (isSelected) {
          ref.read(settingsProvider.notifier).selectPreset(null);
        } else {
          ref.read(settingsProvider.notifier).selectPreset(preset.id);
        }
      },
      showCheckmark: false,
      selectedColor: Theme.of(context).colorScheme.primary,
      checkmarkColor: Theme.of(context).colorScheme.onPrimary,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      side: isSelected
          ? BorderSide.none
          : BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withAlpha(UIConstants.alpha90),
            ),
    );
  }

  // 전송/취소 버튼
  Widget _buildSendButton(BuildContext context) {
    if (isSending) {
      return IconButton(
        icon: const Icon(Icons.stop_circle),
        onPressed: onCancel,
        tooltip: '전송 취소',
        color: Theme.of(context).colorScheme.error,
      );
    }

    return IconButton(
      icon: const Icon(Icons.send),
      onPressed: canSend && !isSending ? onSend : null,
      tooltip: '전송',
      color: canSend ? Theme.of(context).colorScheme.primary : null,
    );
  }
}
