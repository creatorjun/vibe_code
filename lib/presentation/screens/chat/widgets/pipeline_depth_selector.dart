// lib/presentation/screens/chat/widgets/pipeline_depth_selector.dart (수정)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../domain/providers/selected_model_count_provider.dart';
import '../../../../domain/providers/settings_provider.dart';

class PipelineDepthSelector extends ConsumerWidget {
  const PipelineDepthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        // 만약 조정되었다면, Provider 상태 업데이트 (다음 빌드 사이클에서 반영됨)
        // WidgetsBinding.instance.addPostFrameCallback((_) {
        //   if (selectedDepth != currentValidDepth && ref.context.mounted) {
        //     ref.read(selectedPipelineDepthProvider.notifier).setDepth(currentValidDepth);
        //   }
        // });
        // -> 위 코드는 빌드 중에 상태를 변경하려고 시도하여 에러 발생 가능성이 있음
        // -> 상태 조정은 Provider 내부 로직이나 다른 적절한 시점에 처리하는 것이 좋음
        // -> 여기서는 UI 표시만 조정된 값(currentValidDepth)을 기준으로 함


        // 파이프라인 깊이 선택 버튼 생성 (1부터 maxDepth까지)
        final buttons = List.generate(
          maxDepth,
              (index) {
            final depth = index + 1;
            final isSelected = depth == currentValidDepth;
            return Padding(
              // 버튼 사이 간격 추가
              padding: const EdgeInsets.only(right: UIConstants.spacingSm),
              child: FilterChip(
                label: Text('$depth'),
                selected: isSelected,
                onSelected: (_) {
                  ref.read(selectedPipelineDepthProvider.notifier).setDepth(depth);
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
                    : BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(UIConstants.alpha90)),
                // dense하게 만들기 위해 패딩 조절 (선택 사항)
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                labelPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            );
          },
        );

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4.0), // 상하 약간의 패딩
          child: Row(children: buttons),
        );
      },
      loading: () => const SizedBox(height: 40), // 로딩 중 높이 유지
      error: (_, __) => const SizedBox(height: 40), // 에러 시 높이 유지
    );
  }
}