// lib/domain/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/logger.dart';
import 'settings_provider.dart';

/// Provider (Riverpod 3.0 - NotifierProvider)
final appThemeModeProvider = NotifierProvider<AppThemeModeNotifier, ThemeMode>(
  AppThemeModeNotifier.new,
);

/// Notifier
class AppThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // settings
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) {
        final themeMode = _parseThemeMode(settings.themeMode);
        Logger.debug('Theme mode loaded: $themeMode');
        return themeMode;
      },
      loading: () => ThemeMode.system,
      error: (_, __) => ThemeMode.system,
    );
  }

  Future<void> toggle() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    Logger.info('Toggling theme: $state -> $newMode');
    await setThemeMode(newMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    Logger.info('Setting theme mode: $mode');

    try {
      // 1. DB에 먼저 저장
      final modeString = _themeModeToString(mode);
      await ref.read(settingsProvider.notifier).updateThemeMode(modeString);

      // 2. DB 저장 완료 후 UI 업데이트
      state = mode;

      Logger.info('Theme mode updated successfully: $mode');
    } catch (e) {
      Logger.error('Failed to update theme mode', e);
      // 에러 발생 시 state를 원래대로 복구
      rethrow;
    }
  }

  // ThemeMode 파싱
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

  // ThemeMode -> String
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
