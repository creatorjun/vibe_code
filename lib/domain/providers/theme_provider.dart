import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/logger.dart';
import 'settings_provider.dart';

/// 테마 모드 Provider (수동 작성)
final appThemeModeProvider = Provider<ThemeMode>((ref) {
  final settingsAsync = ref.watch(settingsProvider);

  return settingsAsync.when(
    data: (settings) {
      return _parseThemeMode(settings.themeMode);
    },
    loading: () => ThemeMode.system,
    error: (_, __) => ThemeMode.system,
  );
});

ThemeMode _parseThemeMode(String mode) {
  switch (mode) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

/// 테마 토글 함수
Future<void> toggleTheme(WidgetRef ref) async {
  final current = ref.read(appThemeModeProvider);
  final newMode = current == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;

  Logger.info('Toggling theme: $current -> $newMode');

  await ref.read(settingsProvider.notifier).updateThemeMode(
    newMode == ThemeMode.light ? 'light' : 'dark',
  );
}

/// 특정 테마로 설정하는 함수
Future<void> setThemeMode(WidgetRef ref, ThemeMode mode) async {
  Logger.info('Setting theme mode: $mode');

  String modeString;
  switch (mode) {
    case ThemeMode.light:
      modeString = 'light';
      break;
    case ThemeMode.dark:
      modeString = 'dark';
      break;
    case ThemeMode.system:
      modeString = 'system';
      break;
  }

  await ref.read(settingsProvider.notifier).updateThemeMode(modeString);
}
