// lib/core/utils/logger.dart

import 'dart:convert';
import 'package:logger/logger.dart' as logger_pkg;
import '../config/app_config.dart';

/// 앱 전역 로거
class AppLogger {
  static late final logger_pkg.Logger _logger;
  static late final logger_pkg.Logger _simpleLogger;
  static bool _initialized = false;

  /// ✅ Logger 초기화 (main.dart에서 AppConfig 초기화 후 호출)
  static void initialize() {
    if (_initialized) return;

    // AppConfig가 초기화되었는지 확인
    try {
      final config = AppConfig.instance;

      // 상세 로거
      _logger = logger_pkg.Logger(
        printer: logger_pkg.PrettyPrinter(
          methodCount: config.methodCount,
          errorMethodCount: config.errorMethodCount,
          lineLength: 120,
          colors: config.useColoredLogs,
          printEmojis: config.showEmojis,
          dateTimeFormat: config.showTime
              ? logger_pkg.DateTimeFormat.onlyTimeAndSinceStart
              : logger_pkg.DateTimeFormat.none,
        ),
        level: config.logLevel,
      );

      // 간단한 로거
      _simpleLogger = logger_pkg.Logger(
        printer: logger_pkg.SimplePrinter(colors: config.useColoredLogs),
        level: config.logLevel,
      );

      _initialized = true;

      // 초기화 로그
      info('Logger initialized - Level: ${config.logLevel.name}, Environment: ${config.environment}');
    } catch (e) {
      // AppConfig가 초기화되지 않은 경우 기본 설정 사용
      _logger = logger_pkg.Logger(
        printer: logger_pkg.PrettyPrinter(),
        level: logger_pkg.Level.debug,
      );
      _simpleLogger = logger_pkg.Logger(
        printer: logger_pkg.SimplePrinter(),
      );
      _initialized = true;
      warning('Logger initialized with default settings (AppConfig not ready)');
    }
  }

  static void _ensureInitialized() {
    if (!_initialized) {
      initialize();
    }
  }

  /// 디버그 로그
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// 정보 로그
  static void info(String message) {
    _ensureInitialized();
    _logger.i(message);
  }

  /// 경고 로그
  static void warning(String message, [dynamic error]) {
    _ensureInitialized();
    _logger.w(message, error: error);
  }

  /// 에러 로그
  static void error(
      String message, [
        dynamic error,
        StackTrace? stackTrace,
      ]) {
    _ensureInitialized();
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// 치명적 에러 로그
  static void fatal(
      String message, [
        dynamic error,
        StackTrace? stackTrace,
      ]) {
    _ensureInitialized();
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// 간단한 로그
  static void trace(String message) {
    _ensureInitialized();
    _simpleLogger.t(message);
  }

  /// JSON 객체 로그
  static void json(String label, Map data) {
    _ensureInitialized();
    try {
      if (AppConfig.instance.enableVerboseLogs) {
        _logger.i('$label:\n${_prettyPrintJson(data)}');
      }
    } catch (e) {
      // AppConfig 사용 불가 시 기본 출력
      _logger.i('$label:\n${_prettyPrintJson(data)}');
    }
  }

  /// HTTP 요청/응답 로그
  static void http({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    dynamic body,
    int? statusCode,
    dynamic response,
  }) {
    _ensureInitialized();

    try {
      if (!AppConfig.instance.enableVerboseLogs) return;
    } catch (e) {
      // AppConfig 사용 불가 시 출력
    }

    final buffer = StringBuffer();
    buffer.writeln('🌐 HTTP $method $url');

    if (statusCode != null) {
      buffer.writeln('📊 Status: $statusCode');
    }

    if (headers != null && headers.isNotEmpty) {
      buffer.writeln('📋 Headers: $headers');
    }

    if (body != null) {
      buffer.writeln('📤 Request: $body');
    }

    if (response != null) {
      buffer.writeln('📥 Response: $response');
    }

    _logger.d(buffer.toString());
  }

  /// 성능 측정 로그
  static void performance(String operation, Duration duration) {
    _ensureInitialized();

    final ms = duration.inMilliseconds;
    final emoji = ms < 100 ? '⚡' : ms < 500 ? '🐢' : '🐌';

    _logger.i('$emoji Performance: $operation took ${ms}ms');
  }

  static String _prettyPrintJson(Map json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }
}

// ✅ 하위 호환성을 위한 별칭
class Logger {
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger.debug(message, error, stackTrace);
  }

  static void info(String message) {
    AppLogger.info(message);
  }

  static void warning(String message, [dynamic error]) {
    AppLogger.warning(message, error);
  }

  static void error(
      String message, [
        dynamic error,
        StackTrace? stackTrace,
      ]) {
    AppLogger.error(message, error, stackTrace);
  }

  static void fatal(
      String message, [
        dynamic error,
        StackTrace? stackTrace,
      ]) {
    AppLogger.fatal(message, error, stackTrace);
  }

  static void trace(String message) {
    AppLogger.trace(message);
  }

  static void json(String label, Map data) {
    AppLogger.json(label, data);
  }

  static void http({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    dynamic body,
    int? statusCode,
    dynamic response,
  }) {
    AppLogger.http(
      method: method,
      url: url,
      headers: headers,
      body: body,
      statusCode: statusCode,
      response: response,
    );
  }

  static void performance(String operation, Duration duration) {
    AppLogger.performance(operation, duration);
  }
}
