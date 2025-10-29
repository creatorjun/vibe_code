// lib/data/repositories/settings_repository.dart
import 'dart:convert';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../database/daos/settings_dao.dart';
import '../models/settings_state.dart';

class SettingsRepository {
  final SettingsDao _settingsDao;

  SettingsRepository(this._settingsDao);

  // --- 기본 프리셋 ---
  final List<PromptPreset> defaultPresets = const [
    PromptPreset(
      id: 'preset_improve_code',
      name: '코드 개선 프리셋',
      prompts: [
        '당신은 코드 리뷰 전문가입니다.',
        '위 코드를 분석하고 개선점을 제안해주세요.',
      ],
    ),
    PromptPreset(
      id: 'preset_code_review',
      name: '코드 리뷰 프리셋',
      prompts: [
        '당신은 시니어 개발자입니다.',
        '위 코드를 리뷰하고 피드백을 제공해주세요.',
      ],
    ),
  ];

  /// 설정 로드
  Future<SettingsState> loadSettings() async {
    try {
      Logger.info('Loading settings...');
      final allSettings = await _settingsDao.getAllSettings();

      // ❌ 이 부분 삭제 - 매번 기본값으로 덮어쓰는 문제 코드
      // if (allSettings.containsKey(AppConstants.settingsKeyPromptPresets)) {
      //   Logger.info('Force updating presets with new defaults');
      //   await savePromptPresets(defaultPresets);
      //   await saveSelectedPresetId(null);
      // }

      if (allSettings.isEmpty) {
        Logger.info('No settings found, initializing with defaults');
        await _initializeDefaultSettings();
        final newSettings = await _settingsDao.getAllSettings();
        return _buildSettingsState(newSettings);
      }

      // --- 프롬프트 프리셋 초기화 ---
      if (!allSettings.containsKey(AppConstants.settingsKeyPromptPresets)) {
        Logger.info('Prompt presets not found, initializing defaults.');
        await savePromptPresets(defaultPresets);
        await saveSelectedPresetId(null);
        final updatedSettings = await _settingsDao.getAllSettings();
        return _buildSettingsState(updatedSettings);
      }

      // --- 정상적으로 로드 ---
      return _buildSettingsState(allSettings);
    } catch (e, stackTrace) {
      Logger.error('Failed to load settings, using defaults', e, stackTrace);
      // 실패 시 기본값 반환
      return SettingsState(promptPresets: defaultPresets);
    }
  }

  /// Map에서 SettingsState 생성
  SettingsState _buildSettingsState(Map<String, String> settings) {
    try {
      final apiKey = settings[AppConstants.settingsKeyApiKey] ?? '';
      final themeMode = settings[AppConstants.settingsKeyThemeMode] ?? 'system';

      // 모델 파이프라인 파싱
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

      if (pipeline.isEmpty) {
        pipeline = [
          const ModelConfig(
            modelId: 'anthropic/claude-3.5-sonnet',
            systemPrompt: '',
            order: 0,
          ),
        ];
      }

      // --- 프롬프트 프리셋 파싱 ---
      final presetsJson = settings[AppConstants.settingsKeyPromptPresets];
      List<PromptPreset> presets = [];
      if (presetsJson != null && presetsJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(presetsJson) as List;
          presets = decoded
              .map((e) => PromptPreset.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (e) {
          Logger.warning('Failed to parse prompt presets, using default', e);
          presets = defaultPresets;
        }
      } else {
        presets = defaultPresets;
      }

      // JSON 파싱 후 null이면 ID를 null로
      final selectedPresetId = settings[AppConstants.settingsKeySelectedPresetId];

      // 메시지 히스토리 제한 설정 로드
      final maxHistoryMessagesStr = settings[AppConstants.settingsKeyMaxHistoryMessages];
      int maxHistoryMessages = AppConstants.defaultMaxHistoryMessages;
      if (maxHistoryMessagesStr != null && maxHistoryMessagesStr.isNotEmpty) {
        maxHistoryMessages = int.tryParse(maxHistoryMessagesStr) ?? AppConstants.defaultMaxHistoryMessages;
      }

      // --- 최종 반환 ---
      return SettingsState(
        apiKey: apiKey,
        modelPipeline: pipeline,
        themeMode: themeMode,
        promptPresets: presets,
        selectedPresetId: selectedPresetId,
        maxHistoryMessages: maxHistoryMessages,
      );
    } catch (e, stackTrace) {
      Logger.error('Error building settings state', e, stackTrace);
      return SettingsState(promptPresets: defaultPresets);
    }
  }

  /// 기본 설정 초기화
  Future<void> _initializeDefaultSettings() async {
    try {
      await _settingsDao.saveSetting(AppConstants.settingsKeyApiKey, '');

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

      await _settingsDao.saveSetting(AppConstants.settingsKeyThemeMode, 'system');

      // 프롬프트 프리셋 / ID 초기화
      await savePromptPresets(defaultPresets);
      await saveSelectedPresetId(null);

      // 메시지 히스토리 제한 초기화
      await _settingsDao.saveSetting(
        AppConstants.settingsKeyMaxHistoryMessages,
        AppConstants.defaultMaxHistoryMessages.toString(),
      );

      Logger.info('Default settings initialized');
    } catch (e, stackTrace) {
      Logger.error('Failed to initialize default settings', e, stackTrace);
    }
  }

  /// API 키 저장
  Future<void> saveApiKey(String apiKey) async {
    Logger.info('Saving API key');
    await _settingsDao.saveSetting(AppConstants.settingsKeyApiKey, apiKey);
  }

  /// 모델 파이프라인 저장
  Future<void> saveModelPipeline(List<ModelConfig> pipeline) async {
    Logger.info('Saving model pipeline: ${pipeline.length} models');
    final json = jsonEncode(pipeline.map((e) => e.toJson()).toList());
    await _settingsDao.saveSetting(AppConstants.settingsKeyModelPipeline, json);
  }

  /// 테마 모드 저장
  Future<void> saveThemeMode(String themeMode) async {
    Logger.info('Saving theme mode: $themeMode');
    await _settingsDao.saveSetting(AppConstants.settingsKeyThemeMode, themeMode);
  }

  /// ✅ public으로 변경: 프롬프트 프리셋 저장
  Future<void> savePromptPresets(List<PromptPreset> presets) async {
    Logger.info('Saving prompt presets: ${presets.length} presets');
    final json = jsonEncode(presets.map((e) => e.toJson()).toList());
    await _settingsDao.saveSetting(AppConstants.settingsKeyPromptPresets, json);
  }

  /// ✅ public으로 변경: 선택된 프리셋 ID 저장
  Future<void> saveSelectedPresetId(String? presetId) async {
    Logger.info('Saving selected preset ID: ${presetId ?? 'null (기본값)'}');
    await _settingsDao.saveSetting(
      AppConstants.settingsKeySelectedPresetId,
      presetId ?? '',
    );
  }

  /// 메시지 히스토리 제한 저장
  Future<void> saveMaxHistoryMessages(int maxMessages) async {
    Logger.info('Saving max history messages: $maxMessages');
    await _settingsDao.saveSetting(
      AppConstants.settingsKeyMaxHistoryMessages,
      maxMessages.toString(),
    );
  }

  /// 설정 읽기
  Future<String?> getSetting(String key) async {
    return await _settingsDao.getSetting(key);
  }

  /// 설정 스트림
  Stream<String?> watchSetting(String key) {
    return _settingsDao.watchSetting(key);
  }

  /// 설정 초기화
  Future<void> resetSettings() async {
    Logger.info('Resetting all settings');
    await _settingsDao.deleteAllSettings();
    await _initializeDefaultSettings();
  }
}
