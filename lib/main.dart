// lib/main.dart (초기화 부분 수정)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/utils/logger.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경별 설정 초기화
  const environment = String.fromEnvironment('ENV', defaultValue: 'development');

  if (environment == 'production') {
    AppConfig.initialize(ProductionConfig());
  } else {
    AppConfig.initialize(DevelopmentConfig());
  }

  AppLogger.info('App started in ${AppConfig.instance.environment} mode');

  runApp(
    const ProviderScope(
      child: VibeCodeApp(),
    ),
  );
}
