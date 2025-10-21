import '../../core/constants/app_constants.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';
import '../database/daos/settings_dao.dart';
import '../models/settings_state.dart';

class SettingsRepository {
  final SettingsDao _settingsDao;

  SettingsRepository(this._settingsDao);

  /// 모든 설정 로드 (기본값 자동 초기화)
  Future<SettingsState> loadSettings() async {
    try {
      Logger.info('Loading settings');

      final settings = await _settingsDao.getAllSettings();

      // 설정이 비어있으면 기본값 초기화
      if (settings.isEmpty) {
        Logger.info('No settings found, initializing with defaults');
        await _initializeDefaultSettings();
        final newSettings = await _settingsDao.getAllSettings();
        return _buildSettingsState(newSettings);
      }

      return _buildSettingsState(settings);
    } catch (e, stackTrace) {
      Logger.error('Failed to load settings, using defaults', e, stackTrace);
      // 에러 발생 시 기본값 반환
      return const SettingsState();
    }
  }

  /// 기본 설정 초기화
  Future<void> _initializeDefaultSettings() async {
    try {
      // 기본 모델 저장
      await _settingsDao.saveSetting(
        AppConstants.settingsKeyModel,
        ApiConstants.defaultModel,
      );

      // 기본 시스템 프롬프트 저장
      await _settingsDao.saveSetting(
        AppConstants.settingsKeySystemPrompt,
        ApiConstants.defaultSystemPrompt,
      );

      // 기본 테마 모드 저장
      await _settingsDao.saveSetting(
        AppConstants.settingsKeyThemeMode,
        'system',
      );

      // API 키는 빈 문자열로 초기화
      await _settingsDao.saveSetting(
        AppConstants.settingsKeyApiKey,
        '',
      );

      Logger.info('Default settings initialized');
    } catch (e, stackTrace) {
      Logger.error('Failed to initialize default settings', e, stackTrace);
    }
  }

  /// 설정 맵을 SettingsState로 변환
  SettingsState _buildSettingsState(Map<String, String> settings) {
    return SettingsState(
      apiKey: settings[AppConstants.settingsKeyApiKey] ?? '',
      selectedModel: settings[AppConstants.settingsKeyModel] ?? ApiConstants.defaultModel,
      systemPrompt: settings[AppConstants.settingsKeySystemPrompt] ?? ApiConstants.defaultSystemPrompt,
      themeMode: settings[AppConstants.settingsKeyThemeMode] ?? 'system',
    );
  }

  /// API 키 저장
  Future<void> saveApiKey(String apiKey) async {
    Logger.info('Saving API key');
    await _settingsDao.saveSetting(AppConstants.settingsKeyApiKey, apiKey);
  }

  /// 모델 선택 저장
  Future<void> saveModel(String model) async {
    Logger.info('Saving selected model: $model');
    await _settingsDao.saveSetting(AppConstants.settingsKeyModel, model);
  }

  /// 시스템 프롬프트 저장
  Future<void> saveSystemPrompt(String prompt) async {
    Logger.info('Saving system prompt');
    await _settingsDao.saveSetting(AppConstants.settingsKeySystemPrompt, prompt);
  }

  /// 테마 모드 저장
  Future<void> saveThemeMode(String themeMode) async {
    Logger.info('Saving theme mode: $themeMode');
    await _settingsDao.saveSetting(AppConstants.settingsKeyThemeMode, themeMode);
  }

  /// 특정 설정 조회
  Future<String?> getSetting(String key) async {
    return await _settingsDao.getSetting(key);
  }

  /// 설정 스트림
  Stream<String?> watchSetting(String key) {
    return _settingsDao.watchSetting(key);
  }

  /// 모든 설정 초기화
  Future<void> resetSettings() async {
    Logger.info('Resetting all settings');
    await _settingsDao.deleteAllSettings();
    // 기본값 다시 초기화
    await _initializeDefaultSettings();
  }
}
