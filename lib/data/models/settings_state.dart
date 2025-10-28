// lib/data/models/settings_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/constants/app_constants.dart';

part 'settings_state.freezed.dart';
part 'settings_state.g.dart';

@freezed
sealed class PromptPreset with _$PromptPreset {
  const factory PromptPreset({
    required String id,
    required String name,
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
    @Default([]) List<PromptPreset> promptPresets,
    String? selectedPresetId,
    // ✅ 신규: 메시지 히스토리 제한 설정
    @Default(AppConstants.defaultMaxHistoryMessages) int maxHistoryMessages,
  }) = _SettingsState;

  factory SettingsState.fromJson(Map<String, dynamic> json) =>
      _$SettingsStateFromJson(json);

  // Computed properties
  List<ModelConfig> get enabledModels {
    return modelPipeline.where((m) => m.isEnabled).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  int get enabledModelCount => enabledModels.length;

  bool get canAddMoreModels =>
      modelPipeline.length < AppConstants.maxPipelineModels;

  PromptPreset? get selectedPreset {
    if (selectedPresetId == null) return null;
    try {
      return promptPresets.firstWhere((p) => p.id == selectedPresetId);
    } catch (_) {
      return null;
    }
  }
}
