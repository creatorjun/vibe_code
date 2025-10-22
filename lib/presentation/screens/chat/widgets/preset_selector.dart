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

        // 프리셋이 없으면 아예 아무것도 표시하지 않음
        if (presets.isEmpty) {
          return const SizedBox.shrink();
        }

        return Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 20,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: UIConstants.spacingSm),
            Text(
              '프리셋:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: UIConstants.spacingMd),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // --- 수정: "끄기" 버튼 제거 ---
                    // _PresetButton(
                    //   preset: null,
                    //   isSelected: selectedPresetId == null,
                    //   onTap: () {
                    //     ref.read(settingsProvider.notifier).selectPreset(null);
                    //   },
                    // ),
                    // const SizedBox(width: UIConstants.spacingSm), // 간격 제거
                    // --- ---

                    // 각 프리셋 버튼 (토글 로직 추가)
                    ...presets.map((preset) {
                      final isSelected = preset.id == selectedPresetId;
                      return Padding(
                        padding: const EdgeInsets.only(right: UIConstants.spacingSm),
                        child: _PresetButton(
                          preset: preset,
                          isSelected: isSelected,
                          // --- 수정: 토글 로직 구현 ---
                          onTap: () {
                            if (isSelected) {
                              // 이미 선택된 버튼을 다시 누르면 선택 해제 ("끄기" 상태)
                              ref.read(settingsProvider.notifier).selectPreset(null);
                            } else {
                              // 다른 버튼을 누르면 해당 프리셋 선택
                              ref.read(settingsProvider.notifier).selectPreset(preset.id);
                            }
                          },
                          // --- ---
                        ),
                      );
                    }).toList(),
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

// _PresetButton 위젯 (수정: preset이 null인 경우 제거)
class _PresetButton extends StatelessWidget {
  // --- 수정: preset을 non-nullable로 변경 ---
  final PromptPreset preset;
  // --- ---
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.preset, // required로 변경
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // --- 수정: null 체크 제거 ---
    final String label = preset.name;
    const IconData icon = Icons.auto_awesome; // 아이콘 고정
    // --- ---

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
      onSelected: (_) => onTap(), // onTap 콜백 사용
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
          : BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(96)),
    );
  }
}