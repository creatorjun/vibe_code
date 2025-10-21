// lib/core/config/app_config.dart
abstract class AppConfig {
  String get apiBaseUrl;
  Duration get connectTimeout;
  Duration get receiveTimeout;
  bool get enableLogging;
  bool get enableAnalytics;
  String get environment;

  static AppConfig? _instance;

  static AppConfig get instance {
    if (_instance == null) {
      throw Exception('AppConfig가 초기화되지 않았습니다. AppConfig.initialize()를 먼저 호출하세요.');
    }
    return _instance!;
  }

  static void initialize(AppConfig config) {
    _instance = config;
  }

  static bool get isInitialized => _instance != null;
}

/// 개발 환경 설정
class DevelopmentConfig extends AppConfig {
  @override
  String get apiBaseUrl => 'https://openrouter.ai/api/v1';

  @override
  Duration get connectTimeout => const Duration(seconds: 30);

  @override
  Duration get receiveTimeout => const Duration(seconds: 60);

  @override
  bool get enableLogging => true;

  @override
  bool get enableAnalytics => false;

  @override
  String get environment => 'development';
}

/// 프로덕션 환경 설정
class ProductionConfig extends AppConfig {
  @override
  String get apiBaseUrl => 'https://openrouter.ai/api/v1';

  @override
  Duration get connectTimeout => const Duration(seconds: 15);

  @override
  Duration get receiveTimeout => const Duration(seconds: 30);

  @override
  bool get enableLogging => false;

  @override
  bool get enableAnalytics => true;

  @override
  String get environment => 'production';
}
