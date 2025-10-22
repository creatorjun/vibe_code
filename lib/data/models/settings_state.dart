// lib/data/models/settings_state.dart (수정)
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/constants/app_constants.dart'; // AppConstants 추가

part 'settings_state.freezed.dart';
part 'settings_state.g.dart';

/// 시스템 프롬프트 프리셋 모델
@freezed
sealed class PromptPreset with _$PromptPreset {
  const factory PromptPreset({
    required String id, // 프리셋 고유 ID (예: 'preset_code_improve')
    required String name, // 프리셋 이름 (예: '코드 점진 개선')
    // 각 파이프라인 단계별 시스템 프롬프트 리스트
    // 길이는 최대 AppConstants.maxPipelineModels 와 같거나 작아야 함
    required List<String> prompts,
  }) = _PromptPreset;

  factory PromptPreset.fromJson(Map<String, dynamic> json) =>
      _$PromptPresetFromJson(json);
}


@freezed
sealed class ModelConfig with _$ModelConfig {
  const factory ModelConfig({
    required String modelId,
    @Default('') String systemPrompt,
    @Default(true) bool isEnabled,
    required int order,
  }) = _ModelConfig;

  factory ModelConfig.fromJson(Map<String, dynamic> json) =>
      _$ModelConfigFromJson(json);
}

@freezed
sealed class SettingsState with _$SettingsState {
  const SettingsState._();

  const factory SettingsState({
    @Default('') String apiKey,
    @Default([]) List<ModelConfig> modelPipeline,
    @Default('anthropic/claude-3.5-sonnet') String selectedModel,
    @Default('system') String themeMode,
    // 프리셋 목록 추가
    @Default([]) List<PromptPreset> promptPresets,
    // 현재 선택된 프리셋 ID 추가 (null이면 선택 안됨)
    String? selectedPresetId,
  }) = _SettingsState;

  factory SettingsState.fromJson(Map<String, dynamic> json) =>
      _$SettingsStateFromJson(json);

  // Computed properties
  List<ModelConfig> get enabledModels {
    return modelPipeline.where((m) => m.isEnabled).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  // 활성화된 모델 수 반환 (기존 canAddMoreModels 대신 사용 고려)
  int get enabledModelCount => enabledModels.length;

  // 최대 모델 수 상수 사용
  bool get canAddMoreModels => modelPipeline.length < AppConstants.maxPipelineModels;

  // 현재 선택된 프리셋 객체 반환
  PromptPreset? get selectedPreset {
    if (selectedPresetId == null) return null;
    try {
      return promptPresets.firstWhere((p) => p.id == selectedPresetId);
    } catch (_) {
      return null; // ID에 해당하는 프리셋이 없을 경우
    }
  }
}