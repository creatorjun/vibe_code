// lib/core/utils/logger.dart (전체 수정)
import 'dart:convert';
import 'package:logger/logger.dart' as logger_pkg;

/// 앱 전역 로거
class AppLogger {
  static final logger_pkg.Logger _logger = logger_pkg.Logger(
    printer: logger_pkg.PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: logger_pkg.DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: logger_pkg.Level.debug,
  );

  static final logger_pkg.Logger _simpleLogger = logger_pkg.Logger(
    printer: logger_pkg.SimplePrinter(colors: true),
  );

  /// 디버그 로그
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// 정보 로그
  static void info(String message) {
    _logger.i(message);
  }

  /// 경고 로그
  static void warning(String message, [dynamic error]) {
    _logger.w(message, error: error);
  }

  /// 에러 로그
  static void error(
      String message, [
        dynamic error,
        StackTrace? stackTrace,
      ]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// 치명적 에러 로그
  static void fatal(
      String message, [
        dynamic error,
        StackTrace? stackTrace,
      ]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// 간단한 로그
  static void trace(String message) {
    _simpleLogger.t(message);
  }

  /// JSON 객체 로그
  static void json(String label, Map<String, dynamic> data) {
    _logger.i('$label:\n${_prettyPrintJson(data)}');
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
    final ms = duration.inMilliseconds;
    final emoji = ms < 100 ? '⚡' : ms < 500 ? '🐢' : '🐌';
    _logger.i('$emoji Performance: $operation took ${ms}ms');
  }

  static String _prettyPrintJson(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }
}

// 하위 호환성을 위한 별칭
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
}
