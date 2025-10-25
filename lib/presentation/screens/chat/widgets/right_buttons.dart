// lib/presentation/screens/chat/widgets/right_buttons.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/constants/app_constants.dart';
import '../../../../../../core/constants/ui_constants.dart';
import '../../../../../../data/models/settings_state.dart';
import '../../../../../../domain/providers/selected_model_count_provider.dart';
import '../../../../../../domain/providers/settings_provider.dart';

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
    final settingsAsync = ref.watch(settingsProvider);
    final selectedDepth = ref.watch(selectedPipelineDepthProvider);

    return settingsAsync.when(
      data: (settings) {
        final availableModels = settings.enabledModels.length;
        final maxDepth = availableModels < AppConstants.maxPipelineModels
            ? availableModels
            : AppConstants.maxPipelineModels;

        if (maxDepth < 1) {
          return const SizedBox(height: 40);
        }

        final minDepth = AppConstants.minPipelineModels;
        final currentValidDepth = selectedDepth.clamp(minDepth, maxDepth);

        // 최적화: 개별 FilterChip 대신 Container로 감싸기
        return Container(
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
                  onTap: () {
                    ref
                        .read(selectedPipelineDepthProvider.notifier)
                        .setDepth(depth);
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
                      '$depth',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
      loading: () => const SizedBox(height: 40),
      error: (_, __) => const SizedBox(height: 40),
    );
  }

  Widget _buildPresetSelector(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) {
        final presets = settings.promptPresets;
        final selectedPresetId = settings.selectedPresetId;

        if (presets.isEmpty) {
          return const SizedBox.shrink();
        }

        // ✅ Flexible 제거하고 SingleChildScrollView 직접 사용
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: presets.map((preset) {
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
              }).toList(),
            ),
          ),
        );
      },
      loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      error: (err, stack) => Tooltip(
        message: err.toString(),
        child: Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

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
        color: Theme.of(context)
            .colorScheme
            .outline
            .withAlpha(UIConstants.alpha90),
      ),
    );
  }

  Widget _buildSendButton(BuildContext context) {
    if (isSending) {
      return IconButton(
        icon: const Icon(Icons.stop_circle),
        onPressed: onCancel,
        tooltip: '중지',
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
