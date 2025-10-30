// lib/presentation/screens/chat/widgets/right_buttons.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_code/core/constants/ui_constants.dart';
import 'package:vibe_code/core/constants/app_constants.dart';
import 'package:vibe_code/domain/providers/settings_provider.dart';
import 'package:vibe_code/domain/providers/selected_model_count_provider.dart';

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
        _buildPipelineDepthSelector(context, ref),
        const SizedBox(width: UIConstants.spacingMd),
        _buildPresetSelector(context, ref),
        const SizedBox(width: UIConstants.spacingMd),
        _buildSendButton(context),
      ],
    );
  }

  Widget _buildPipelineDepthSelector(BuildContext context, WidgetRef ref) {
    final enabledModelsLength = ref.watch(
      settingsProvider.select((async) => async.whenOrNull(
        data: (settings) => settings.enabledModels.length,
      ) ??
          0),
    );
    final selectedDepth = ref.watch(selectedPipelineDepthProvider);
    final maxDepth = enabledModelsLength < AppConstants.maxPipelineModels
        ? enabledModelsLength
        : AppConstants.maxPipelineModels;

    if (maxDepth <= 1) {
      return const SizedBox(height: 40);
    }

    final minDepth = AppConstants.minPipelineModels;
    final currentValidDepth = selectedDepth.clamp(minDepth, maxDepth);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 아이콘을 좌측에 배치
        Icon(
          Icons.list_outlined,
          size: 16,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withAlpha(UIConstants.alpha60),
        ),
        const SizedBox(width: UIConstants.spacingSm),
        // 버튼 컨테이너
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.spacingXs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withAlpha(UIConstants.alpha30),
            borderRadius: BorderRadius.circular(UIConstants.radiusSm),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withAlpha(UIConstants.alpha20),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(maxDepth, (index) {
              final depth = index + 1;
              final isSelected = depth == currentValidDepth;
              return Padding(
                padding: EdgeInsets.only(
                  right: index < maxDepth - 1 ? 4.0 : 0,
                ),
                child: InkWell(
                  onTap: () => ref
                      .read(selectedPipelineDepthProvider.notifier)
                      .setDepth(depth),
                  borderRadius: BorderRadius.circular(UIConstants.radiusXs),
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(UIConstants.radiusXs),
                    ),
                    child: Text(
                      '$depth',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(UIConstants.alpha70),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetSelector(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(
      settingsProvider.select((async) => async.whenOrNull(
        data: (settings) => settings.promptPresets,
      ) ??
          []),
    );
    final selectedPresetId = ref.watch(
      settingsProvider.select((async) => async.whenOrNull(
        data: (settings) => settings.selectedPresetId,
      )),
    );

    if (presets.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.auto_awesome_outlined,
          size: 16,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withAlpha(UIConstants.alpha60),
        ),
        const SizedBox(width: UIConstants.spacingSm),
        // 버튼 컨테이너
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.spacingXs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withAlpha(UIConstants.alpha30),
            borderRadius: BorderRadius.circular(UIConstants.radiusSm),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withAlpha(UIConstants.alpha20),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(presets.length, (index) {
              final preset = presets[index];
              final isSelected = preset.id == selectedPresetId;
              return Padding(
                padding: EdgeInsets.only(
                  right: index < presets.length - 1 ? 4.0 : 0,
                ),
                child: InkWell(
                  onTap: () {
                    if (isSelected) {
                      ref.read(settingsProvider.notifier).selectPreset(null);
                    } else {
                      ref.read(settingsProvider.notifier).selectPreset(preset.id);
                    }
                  },
                  borderRadius: BorderRadius.circular(UIConstants.radiusXs),
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(UIConstants.radiusXs),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(UIConstants.alpha70),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton(BuildContext context) {
    if (isSending) {
      return IconButton(
        icon: const Icon(Icons.stop_circle_outlined),
        onPressed: onCancel,
        tooltip: '중지',
        color: Theme.of(context).colorScheme.error,
      );
    }

    return IconButton(
      icon: const Icon(Icons.arrow_circle_up_outlined),
      onPressed: canSend && !isSending ? onSend : null,
      tooltip: '전송',
      color: canSend ? Theme.of(context).colorScheme.primary : null,
    );
  }
}
