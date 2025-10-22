import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/logger.dart';
import 'settings_provider.dart';

/// 테마 모드 Provider (Riverpod 3.0 - NotifierProvider)
final appThemeModeProvider = NotifierProvider<AppThemeModeNotifier, ThemeMode>(
  AppThemeModeNotifier.new,
);

/// 테마 모드 Notifier
class AppThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // settings 변경 감지
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

  /// 테마 토글 (라이트 ↔ 다크)
  Future<void> toggle() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    Logger.info('Toggling theme: $state -> $newMode');
    await _updateThemeMode(newMode);
  }

  /// 테마 모드 설정
  Future<void> setThemeMode(ThemeMode mode) async {
    Logger.info('Setting theme mode: $mode');
    await _updateThemeMode(mode);
  }

  /// 내부: 테마 모드 업데이트
  Future<void> _updateThemeMode(ThemeMode mode) async {
    final modeString = _themeModeToString(mode);
    await ref.read(settingsProvider.notifier).updateThemeMode(modeString);
    // settings가 업데이트되면 build()가 자동으로 재호출되어 state 갱신
  }

  /// 문자열 → ThemeMode 변환
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

  /// ThemeMode → 문자열 변환
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
