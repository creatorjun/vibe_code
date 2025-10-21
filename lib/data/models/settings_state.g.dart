// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
    );

Map<String, dynamic> _$SettingsStateToJson(_SettingsState instance) =>
    <String, dynamic>{
      'apiKey': instance.apiKey,
      'modelPipeline': instance.modelPipeline,
      'selectedModel': instance.selectedModel,
      'themeMode': instance.themeMode,
    };
