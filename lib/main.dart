// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'core/config/app_config.dart';
import 'core/utils/logger.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Window Manager 초기화
  await windowManager.ensureInitialized();

  // ✅ 창 옵션 설정
  const windowOptions = WindowOptions(
    minimumSize: Size(800, 600),
    skipTaskbar: false,
  );

  // ✅ 창이 준비될 때까지 대기하고 최대화
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.maximize();
  });

  // ✅ 환경별 설정 초기화
  const environment = String.fromEnvironment('ENV', defaultValue: 'development');
  if (environment == 'production') {
    AppConfig.initialize(ProductionConfig());
  } else {
    AppConfig.initialize(DevelopmentConfig());
  }

  // ✅ Logger 초기화 (AppConfig 초기화 후)
  AppLogger.initialize();

  AppLogger.info('App started in ${AppConfig.instance.environment} mode');

  runApp(
    const ProviderScope(
      child: VibeCodeApp(),
    ),
  );
}
