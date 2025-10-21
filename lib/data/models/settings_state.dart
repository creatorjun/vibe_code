class SettingsState {
  final String apiKey;
  final String selectedModel;
  final String systemPrompt;
  final String themeMode;

  const SettingsState({
    this.apiKey = '',
    this.selectedModel = 'anthropic/claude-3.5-sonnet',
    this.systemPrompt = '',
    this.themeMode = 'system',
  });

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      apiKey: json['apiKey'] as String? ?? '',
      selectedModel: json['selectedModel'] as String? ?? 'anthropic/claude-3.5-sonnet',
      systemPrompt: json['systemPrompt'] as String? ?? '',
      themeMode: json['themeMode'] as String? ?? 'system',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apiKey': apiKey,
      'selectedModel': selectedModel,
      'systemPrompt': systemPrompt,
      'themeMode': themeMode,
    };
  }

  SettingsState copyWith({
    String? apiKey,
    String? selectedModel,
    String? systemPrompt,
    String? themeMode,
  }) {
    return SettingsState(
      apiKey: apiKey ?? this.apiKey,
      selectedModel: selectedModel ?? this.selectedModel,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
