// lib/domain/mutations/send_message/pipeline_configurator.dart

import '../../../core/utils/logger.dart';
import '../../../data/models/settings_state.dart';

class PipelineConfigurator {
  /// 활성 파이프라인 구성을 생성 (프리셋 적용 포함)
  List<ModelConfig> configurePipeline({
    required List<ModelConfig> fullPipelineConfigs,
    required int selectedDepth,
    required PromptPreset? selectedPreset,
  }) {
    // 선택된 깊이만큼만 활성화
    List<ModelConfig> activePipelineConfigs =
    fullPipelineConfigs.take(selectedDepth).toList();

    // 프리셋 적용
    if (selectedPreset != null) {
      Logger.info('Applying preset "${selectedPreset.name}" to the pipeline.');
      final pipelineWithPresetPrompts = <ModelConfig>[];

      for (int i = 0; i < activePipelineConfigs.length; i++) {
        final config = activePipelineConfigs[i];
        final prompt = (i < selectedPreset.prompts.length)
            ? selectedPreset.prompts[i]
            : '';
        pipelineWithPresetPrompts.add(config.copyWith(systemPrompt: prompt));
        Logger.debug(
            '  Step ${i + 1}: Model=${config.modelId}, Prompt=${prompt.isNotEmpty ? "[Preset Prompt]" : "[Empty]"}');
      }
      activePipelineConfigs = pipelineWithPresetPrompts;
    } else {
      Logger.info('No preset selected, using manually configured prompts.');
      for (int i = 0; i < activePipelineConfigs.length; i++) {
        final config = activePipelineConfigs[i];
        Logger.debug(
            '  Step ${i + 1}: Model=${config.modelId}, Prompt=${config.systemPrompt.isNotEmpty ? "[Manual Prompt]" : "[Empty]"}');
      }
    }

    Logger.info('Using ${activePipelineConfigs.length} models (depth: $selectedDepth)');
    return activePipelineConfigs;
  }

  /// 파이프라인의 첫 번째 모델 ID를 반환 (기본값 포함)
  String getFirstModelId(List<ModelConfig> activePipelineConfigs) {
    return activePipelineConfigs.isNotEmpty
        ? activePipelineConfigs.first.modelId
        : 'anthropic/claude-3.5-sonnet';
  }
}
