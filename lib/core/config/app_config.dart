// lib/core/config/app_config.dart

import 'package:logger/logger.dart' as logger_pkg;

/// 앱 전역 설정 (Singleton 패턴)
class AppConfig {
  final String environment;
  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;

  AppConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.sendTimeout,
  });

  static AppConfig? _instance;

  static AppConfig get instance {
    if (_instance == null) {
      throw Exception('AppConfig가 초기화되지 않았습니다. main()에서 initialize()를 호출하세요.');
    }
    return _instance!;
  }

  static void initialize(AppConfig config) {
    _instance = config;
  }

  /// ✅ 개선: 환경별 로그 레벨
  logger_pkg.Level get logLevel {
    if (environment == 'development') {
      return logger_pkg.Level.debug;
    } else if (environment == 'profile') {
      return logger_pkg.Level.info;
    } else {
      return logger_pkg.Level.warning;
    }
  }

  /// ✅ 개선: 상세 로그 여부
  bool get enableVerboseLogs => environment == 'development';

  /// ✅ 개선: 컬러 로그
  bool get useColoredLogs => environment == 'development';

  /// ✅ 개선: 이모지 사용
  bool get showEmojis => environment == 'development';

  /// ✅ 개선: 시간 표시
  bool get showTime => environment == 'development';

  /// ✅ 개선: 메서드 호출 스택 깊이
  int get methodCount => environment == 'development' ? 2 : 0;
  int get errorMethodCount => environment == 'development' ? 8 : 3;
}

/// 개발 환경 설정
class DevelopmentConfig extends AppConfig {
  DevelopmentConfig()
      : super._(
    environment: 'development',
    apiBaseUrl: 'https://openrouter.ai/api/v1',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 30),
  );
}

/// 프로덕션 환경 설정
class ProductionConfig extends AppConfig {
  ProductionConfig()
      : super._(
    environment: 'production',
    apiBaseUrl: 'https://openrouter.ai/api/v1',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 30),
  );
}

/// 프로파일 환경 설정 (선택사항)
class ProfileConfig extends AppConfig {
  ProfileConfig()
      : super._(
    environment: 'profile',
    apiBaseUrl: 'https://openrouter.ai/api/v1',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 30),
  );
}
