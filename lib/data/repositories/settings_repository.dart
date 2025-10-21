// lib/data/repositories/settings_repository.dart
import 'dart:convert';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../database/daos/settings_dao.dart';
import '../models/settings_state.dart';

class SettingsRepository {
  final SettingsDao _settingsDao;

  SettingsRepository(this._settingsDao);

  // 전체 설정 로드
  Future<SettingsState> loadSettings() async {
    try {
      Logger.info('Loading settings...');
      final allSettings = await _settingsDao.getAllSettings();

      if (allSettings.isEmpty) {
        Logger.info('No settings found, initializing with defaults');
        await _initializeDefaultSettings();
        final newSettings = await _settingsDao.getAllSettings();
        return _buildSettingsState(newSettings);
      }

      return _buildSettingsState(allSettings);
    } catch (e, stackTrace) {
      Logger.error('Failed to load settings, using defaults', e, stackTrace);
      return const SettingsState();
    }
  }

  // Map에서 SettingsState 빌드
  SettingsState _buildSettingsState(Map<String, String> settings) {
    try {
      final apiKey = settings[AppConstants.settingsKeyApiKey] ?? '';
      final themeMode = settings[AppConstants.settingsKeyThemeMode] ?? 'system';

      // 모델 파이프라인 JSON 파싱
      final pipelineJson = settings[AppConstants.settingsKeyModelPipeline];
      List<ModelConfig> pipeline = [];

      if (pipelineJson != null && pipelineJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(pipelineJson) as List;
          pipeline = decoded
              .map((e) => ModelConfig.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (e) {
          Logger.warning('Failed to parse model pipeline, using default', e);
        }
      }

      // 파이프라인이 비어있으면 기본값 설정
      if (pipeline.isEmpty) {
        pipeline = [
          const ModelConfig(
            modelId: 'anthropic/claude-3.5-sonnet',
            systemPrompt: '',
            order: 0,
          ),
        ];
      }

      return SettingsState(
        apiKey: apiKey,
        modelPipeline: pipeline,
        themeMode: themeMode,
      );
    } catch (e, stackTrace) {
      Logger.error('Error building settings state', e, stackTrace);
      return const SettingsState();
    }
  }

  // 기본 설정 초기화
  Future<void> _initializeDefaultSettings() async {
    try {
      await _settingsDao.saveSetting(
        AppConstants.settingsKeyApiKey,
        '',
      );

      final defaultPipeline = [
        const ModelConfig(
          modelId: 'anthropic/claude-3.5-sonnet',
          systemPrompt: '',
          order: 0,
        ),
      ];

      await _settingsDao.saveSetting(
        AppConstants.settingsKeyModelPipeline,
        jsonEncode(defaultPipeline.map((e) => e.toJson()).toList()),
      );

      await _settingsDao.saveSetting(
        AppConstants.settingsKeyThemeMode,
        'system',
      );

      Logger.info('Default settings initialized');
    } catch (e, stackTrace) {
      Logger.error('Failed to initialize default settings', e, stackTrace);
    }
  }

  // API 키 저장
  Future<void> saveApiKey(String apiKey) async {
    Logger.info('Saving API key');
    await _settingsDao.saveSetting(AppConstants.settingsKeyApiKey, apiKey);
  }

  // 모델 파이프라인 저장
  Future<void> saveModelPipeline(List<ModelConfig> pipeline) async {
    Logger.info('Saving model pipeline: ${pipeline.length} models');
    final json = jsonEncode(pipeline.map((e) => e.toJson()).toList());
    await _settingsDao.saveSetting(AppConstants.settingsKeyModelPipeline, json);
  }

  // 테마 모드 저장
  Future<void> saveThemeMode(String themeMode) async {
    Logger.info('Saving theme mode: $themeMode');
    await _settingsDao.saveSetting(AppConstants.settingsKeyThemeMode, themeMode);
  }

  // 특정 설정 조회
  Future<String?> getSetting(String key) async {
    return await _settingsDao.getSetting(key);
  }

  // 설정 감시
  Stream<String?> watchSetting(String key) {
    return _settingsDao.watchSetting(key);
  }

  // 설정 초기화
  Future<void> resetSettings() async {
    Logger.info('Resetting all settings');
    await _settingsDao.deleteAllSettings();
    await _initializeDefaultSettings();
  }
}
