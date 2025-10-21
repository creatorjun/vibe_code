import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/utils/logger.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 전역 에러 핸들러
  FlutterError.onError = (FlutterErrorDetails details) {
    Logger.error('Flutter error', details.exception, details.stack);
  };

  Logger.info('Starting Vibe Code app');

  runApp(
    const ProviderScope(
      child: VibeCodeApp(),
    ),
  );
}
