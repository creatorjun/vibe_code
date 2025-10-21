import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/settings_state.dart';
import '../../data/repositories/settings_repository.dart';
import '../../core/utils/logger.dart';
import 'database_provider.dart';

/// 설정 관리 Provider (수동 작성)
final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  late final SettingsRepository _repository;

  @override
  Future<SettingsState> build() async {
    Logger.info('Initializing settings provider');

    final db = ref.watch(databaseProvider);
    _repository = SettingsRepository(db.settingsDao);

    // 설정 로드
    final settings = await _repository.loadSettings();

    Logger.info('Settings loaded: model=${settings.selectedModel}');
    return settings;
  }

  /// API 키 업데이트
  Future<void> updateApiKey(String apiKey) async {
    state = await AsyncValue.guard(() async {
      Logger.info('Updating API key');
      await _repository.saveApiKey(apiKey);
      return state.requireValue.copyWith(apiKey: apiKey);
    });
  }

  /// 모델 업데이트
  Future<void> updateModel(String model) async {
    state = await AsyncValue.guard(() async {
      Logger.info('Updating model: $model');
      await _repository.saveModel(model);
      return state.requireValue.copyWith(selectedModel: model);
    });
  }

  /// 시스템 프롬프트 업데이트
  Future<void> updateSystemPrompt(String prompt) async {
    state = await AsyncValue.guard(() async {
      Logger.info('Updating system prompt');
      await _repository.saveSystemPrompt(prompt);
      return state.requireValue.copyWith(systemPrompt: prompt);
    });
  }

  /// 테마 모드 업데이트
  Future<void> updateThemeMode(String themeMode) async {
    state = await AsyncValue.guard(() async {
      Logger.info('Updating theme mode: $themeMode');
      await _repository.saveThemeMode(themeMode);
      return state.requireValue.copyWith(themeMode: themeMode);
    });
  }

  /// 설정 초기화
  Future<void> resetSettings() async {
    state = await AsyncValue.guard(() async {
      Logger.info('Resetting settings');
      await _repository.resetSettings();
      return const SettingsState();
    });
  }
}
