// lib/presentation/screens/chat/widgets/pipeline_depth_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../domain/providers/selected_model_count_provider.dart';

class PipelineDepthSelector extends ConsumerWidget {
  const PipelineDepthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipelineCount = ref.watch(pipelineModelCountProvider);
    final selectedDepth = ref.watch(selectedPipelineDepthProvider);

    // 모델이 없으면 표시하지 않음
    if (pipelineCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacingMd,
        vertical: UIConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.psychology,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: UIConstants.spacingSm),
          Text(
            '파이프라인 깊이:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: UIConstants.spacingMd),
          Expanded(
            child: Row(
              children: List.generate(5, (index) {
                final depth = index + 1;
                final isAvailable = depth <= pipelineCount;
                final isSelected = depth == selectedDepth;

                return Padding(
                  padding: const EdgeInsets.only(right: UIConstants.spacingSm),
                  child: _DepthButton(
                    depth: depth,
                    isAvailable: isAvailable,
                    isSelected: isSelected,
                    onTap: isAvailable
                        ? () {
                      ref
                          .read(selectedPipelineDepthProvider.notifier)
                          .setDepth(depth);
                    }
                        : null,
                  ),
                );
              }),
            ),
          ),
          Text(
            '$selectedDepth/$pipelineCount 모델',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DepthButton extends StatelessWidget {
  final int depth;
  final bool isAvailable;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DepthButton({
    required this.depth,
    required this.isAvailable,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : isAvailable
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withAlpha(84),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : isAvailable
                ? Theme.of(context).colorScheme.outline.withAlpha(96)
                : Theme.of(context).colorScheme.outline.withAlpha(48),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            '$depth',
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : isAvailable
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withAlpha(48),
            ),
          ),
        ),
      ),
    );
  }
}
