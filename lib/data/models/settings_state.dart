// lib/data/models/settings_state.dart (수정)
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_state.freezed.dart';
part 'settings_state.g.dart';

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
    @Default('anthropic/claude-3.5-sonnet') String selectedModel,  // 추가
    @Default('system') String themeMode,
  }) = _SettingsState;

  factory SettingsState.fromJson(Map<String, dynamic> json) =>
      _$SettingsStateFromJson(json);

  // Computed properties
  List<ModelConfig> get enabledModels {
    return modelPipeline.where((m) => m.isEnabled).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  bool get hasPipeline => enabledModels.isNotEmpty;

  bool get canAddMoreModels => modelPipeline.length < 5;
}
