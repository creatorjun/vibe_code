// lib/core/constants/api_constants.dart (수정)
import '../config/app_config.dart';

class ApiConstants {
  // 동적으로 설정 가져오기
  static String get baseUrl => AppConfig.instance.apiBaseUrl;
  static Duration get connectTimeout => AppConfig.instance.connectTimeout;
  static Duration get receiveTimeout => AppConfig.instance.receiveTimeout;

  // 엔드포인트
  static const String chatEndpoint = '/chat/completions';
  static const String modelsEndpoint = '/models';

  // 헤더
  static const String httpReferer = 'https://github.com/creatorjun/vibe_code';
  static const String xTitle = 'Vibe Code';

  ApiConstants._();
}
