// lib/presentation/screens/chat/widgets/preset_selector.dart (수정)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../data/models/settings_state.dart';
import '../../../../domain/providers/settings_provider.dart';

class PresetSelector extends ConsumerWidget {
  const PresetSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                        padding: const EdgeInsets.only(right: UIConstants.spacingSm),
                        child: _PresetButton(
                          preset: preset,
                          isSelected: isSelected,
                          onTap: () {
                            if (isSelected) {
                              ref.read(settingsProvider.notifier).selectPreset(null);
                            } else {
                              ref.read(settingsProvider.notifier).selectPreset(preset.id);
                            }
                          },
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
      loading: () => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      error: (err, stack) => Tooltip(
        message: '프리셋 로딩 실패: ${err.toString()}',
        child: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final PromptPreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
      onSelected: (_) => onTap(),
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
          : BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(UIConstants.alpha90)),
    );
  }
}