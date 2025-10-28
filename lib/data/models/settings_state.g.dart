// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PromptPreset _$PromptPresetFromJson(Map<String, dynamic> json) =>
    _PromptPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      prompts: (json['prompts'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$PromptPresetToJson(_PromptPreset instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'prompts': instance.prompts,
    };

_ModelConfig _$ModelConfigFromJson(Map<String, dynamic> json) => _ModelConfig(
  modelId: json['modelId'] as String,
  systemPrompt: json['systemPrompt'] as String? ?? '',
  isEnabled: json['isEnabled'] as bool? ?? true,
  order: (json['order'] as num).toInt(),
);

Map<String, dynamic> _$ModelConfigToJson(_ModelConfig instance) =>
    <String, dynamic>{
      'modelId': instance.modelId,
      'systemPrompt': instance.systemPrompt,
      'isEnabled': instance.isEnabled,
      'order': instance.order,
    };

_SettingsState _$SettingsStateFromJson(Map<String, dynamic> json) =>
    _SettingsState(
      apiKey: json['apiKey'] as String? ?? '',
      modelPipeline:
          (json['modelPipeline'] as List<dynamic>?)
              ?.map((e) => ModelConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      selectedModel:
          json['selectedModel'] as String? ?? 'anthropic/claude-3.5-sonnet',
      themeMode: json['themeMode'] as String? ?? 'system',
      promptPresets:
          (json['promptPresets'] as List<dynamic>?)
              ?.map((e) => PromptPreset.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      selectedPresetId: json['selectedPresetId'] as String?,
      maxHistoryMessages:
          (json['maxHistoryMessages'] as num?)?.toInt() ??
          AppConstants.defaultMaxHistoryMessages,
    );

Map<String, dynamic> _$SettingsStateToJson(_SettingsState instance) =>
    <String, dynamic>{
      'apiKey': instance.apiKey,
      'modelPipeline': instance.modelPipeline,
      'selectedModel': instance.selectedModel,
      'themeMode': instance.themeMode,
      'promptPresets': instance.promptPresets,
      'selectedPresetId': instance.selectedPresetId,
      'maxHistoryMessages': instance.maxHistoryMessages,
    };
