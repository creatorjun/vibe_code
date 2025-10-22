// lib/core/constants/app_constants.dart
class AppConstants {
  // 앱 정보
  static const String appName = 'Vibe Code';
  static const String appVersion = '1.0.0';

  // 파일 제한
  static const int maxFileSize = 100 * 1024 * 1024; // 100MB

  // 데이터베이스
  static const String cacheDbName = 'cache.db';

  // 설정 키
  static const String settingsKeyApiKey = 'api_key';
  static const String settingsKeyModelPipeline = 'model_pipeline'; // 변경됨
  static const String settingsKeyThemeMode = 'theme_mode';
  // --- 추가된 설정 키 ---
  static const String settingsKeyPromptPresets = 'prompt_presets'; // 프리셋 목록 키
  static const String settingsKeySelectedPresetId = 'selected_preset_id'; // 선택된 프리셋 ID 키
  // --- ---

  // 모델 파이프라인 제한
  static const int maxPipelineModels = 5;
  static const int minPipelineModels = 1;

  // Private constructor
  AppConstants._();
}