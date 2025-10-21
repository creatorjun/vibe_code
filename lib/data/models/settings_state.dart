// lib/data/models/settings_state.dart
class ModelConfig {
  final String modelId;
  final String systemPrompt;
  final bool isEnabled;
  final int order;

  const ModelConfig({
    required this.modelId,
    this.systemPrompt = '',
    this.isEnabled = true,
    required this.order,
  });

  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    return ModelConfig(
      modelId: json['modelId'] as String,
      systemPrompt: json['systemPrompt'] as String? ?? '',
      isEnabled: json['isEnabled'] as bool? ?? true,
      order: json['order'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modelId': modelId,
      'systemPrompt': systemPrompt,
      'isEnabled': isEnabled,
      'order': order,
    };
  }

  ModelConfig copyWith({
    String? modelId,
    String? systemPrompt,
    bool? isEnabled,
    int? order,
  }) {
    return ModelConfig(
      modelId: modelId ?? this.modelId,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      isEnabled: isEnabled ?? this.isEnabled,
      order: order ?? this.order,
    );
  }
}

class SettingsState {
  final String apiKey;
  final List<ModelConfig> modelPipeline;
  final String themeMode;

  const SettingsState({
    this.apiKey = '',
    this.modelPipeline = const [],
    this.themeMode = 'system',
  });

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    final pipelineJson = json['modelPipeline'] as List?;
    final pipeline = pipelineJson
        ?.map((e) => ModelConfig.fromJson(e as Map<String, dynamic>))
        .toList() ??
        [];

    return SettingsState(
      apiKey: json['apiKey'] as String? ?? '',
      modelPipeline: pipeline.isEmpty
          ? [
        const ModelConfig(
          modelId: 'anthropic/claude-3.5-sonnet',
          systemPrompt: '',
          order: 0,
        ),
      ]
          : pipeline,
      themeMode: json['themeMode'] as String? ?? 'system',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apiKey': apiKey,
      'modelPipeline': modelPipeline.map((e) => e.toJson()).toList(),
      'themeMode': themeMode,
    };
  }

  SettingsState copyWith({
    String? apiKey,
    List<ModelConfig>? modelPipeline,
    String? themeMode,
  }) {
    return SettingsState(
      apiKey: apiKey ?? this.apiKey,
      modelPipeline: modelPipeline ?? this.modelPipeline,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  // 활성화된 모델만 반환
  List<ModelConfig> get enabledModels {
    return modelPipeline.where((m) => m.isEnabled).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  // 파이프라인이 설정되었는지 확인
  bool get hasPipeline => enabledModels.isNotEmpty;

  // 최대 5개 제한 확인
  bool get canAddMoreModels => modelPipeline.length < 5;
}
