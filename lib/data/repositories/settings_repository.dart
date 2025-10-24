// lib/data/repositories/settings_repository.dart
import 'dart:convert';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../database/daos/settings_dao.dart';
import '../models/settings_state.dart'; // SettingsState 및 PromptPreset 모델 포함

class SettingsRepository {
  final SettingsDao _settingsDao;

  SettingsRepository(this._settingsDao);

  // --- 기본 프리셋 정의 (추가) ---
  final List<PromptPreset> _defaultPresets = [
    const PromptPreset(
      id: 'preset_improve_code',
      name: 'Preset 1',
      prompts: [
        '다음 코드를 분석하고 개선할 점을 찾아주세요.',
        '첫 번째 모델의 분석 결과를 바탕으로 실제 개선된 코드를 작성해주세요.',
        '두 번째 모델이 작성한 개선 코드의 효율성, 가독성, 잠재적 오류 가능성을 검토하고 추가 개선 제안이나 최종 의견을 제시해주세요.',
        '세 번째 모델의 결과를 반영하여, 코드를 기능별 모듈로 분리하는 리팩토링을 제안해주세요.',
        '네 번째 모델의 리팩토링 제안을 포함하여, 최종 코드의 유지보수성 측면을 평가하고 종합적인 코드 리뷰 의견을 제시해주세요.',
      ],
    ),
    const PromptPreset(
      id: 'preset_code_review',
      name: 'Preset 2',
      prompts: [
        '다음 코드의 초안을 작성해주세요. 요구사항: [여기에 요구사항 입력]',
        '첫 번째 모델이 작성한 코드 초안의 로직을 검토하고 개선해주세요.',
        '두 번째 모델이 개선한 코드의 보안 취약점을 검토하고 수정 제안을 해주세요.',
        '세 번째 모델의 검토 결과를 반영하여, 코드를 기능별 모듈로 분리하는 리팩토링을 제안해주세요.',
        '네 번째 모델의 리팩토링 제안을 포함하여, 최종 코드의 유지보수성 측면을 평가하고 종합적인 코드 리뷰 의견을 제시해주세요.',
      ],
    ),
  ];

  // 전체 설정 로드
  Future<SettingsState> loadSettings() async {
    try {
      Logger.info('Loading settings...');

      final allSettings = await _settingsDao.getAllSettings();

      // // ✅ 개발 중에만 사용: 프리셋 강제 업데이트
      // if (allSettings.containsKey(AppConstants.settingsKeyPromptPresets)) {
      //   Logger.info('Force updating presets with new defaults');
      //   await savePromptPresets(_defaultPresets);
      //   await saveSelectedPresetId(null);
      // }

      if (allSettings.isEmpty) {
        Logger.info('No settings found, initializing with defaults');
        await _initializeDefaultSettings();
        // 기본값 초기화 후 다시 로드
        final newSettings = await _settingsDao.getAllSettings();
        return _buildSettingsState(newSettings);
      }

      // --- 프리셋 로드 로직 추가 ---
      // 데이터베이스에 프리셋 설정이 없으면 기본값으로 초기화
      if (!allSettings.containsKey(AppConstants.settingsKeyPromptPresets)) {
        Logger.info('Prompt presets not found, initializing defaults.');
        await savePromptPresets(_defaultPresets);
        // 선택된 프리셋 ID도 초기화 (null)
        await saveSelectedPresetId(null);
        // 업데이트된 설정을 다시 로드
        final updatedSettings = await _settingsDao.getAllSettings();
        return _buildSettingsState(updatedSettings);
      }
      // --- ---

      return _buildSettingsState(allSettings);
    } catch (e, stackTrace) {
      Logger.error('Failed to load settings, using defaults', e, stackTrace);
      // 에러 발생 시 기본 SettingsState 반환 (기본 프리셋 포함)
      return SettingsState(promptPresets: _defaultPresets);
    }
  }

  // Map에서 SettingsState 빌드
  SettingsState _buildSettingsState(Map<String, String> settings) {
    try {
      final apiKey = settings[AppConstants.settingsKeyApiKey] ?? '';
      final themeMode = settings[AppConstants.settingsKeyThemeMode] ?? 'system';
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

      // --- 프리셋 파싱 로직 추가 ---
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
          presets = _defaultPresets; // 파싱 실패 시 기본값 사용
        }
      } else {
        presets = _defaultPresets; // JSON이 없으면 기본값 사용
      }
      // 선택된 프리셋 ID 로드
      final selectedPresetId = settings[AppConstants.settingsKeySelectedPresetId];
      // --- ---

      return SettingsState(
        apiKey: apiKey,
        modelPipeline: pipeline,
        themeMode: themeMode,
        promptPresets: presets, // 추가
        selectedPresetId: selectedPresetId, // 추가
      );
    } catch (e, stackTrace) {
      Logger.error('Error building settings state', e, stackTrace);
      // 에러 시 기본값 반환
      return SettingsState(promptPresets: _defaultPresets);
    }
  }

  // 기본 설정 초기화
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

      // --- 기본 프리셋 및 선택된 ID 초기화 추가 ---
      await savePromptPresets(_defaultPresets);
      await saveSelectedPresetId(null); // 처음에는 선택 안 함
      // --- ---

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

  // --- 프리셋 관련 저장 메서드 추가 ---

  /// 프리셋 목록 저장
  Future<void> savePromptPresets(List<PromptPreset> presets) async {
    Logger.info('Saving prompt presets: ${presets.length} presets');
    final json = jsonEncode(presets.map((e) => e.toJson()).toList());
    await _settingsDao.saveSetting(AppConstants.settingsKeyPromptPresets, json);
  }

  /// 선택된 프리셋 ID 저장
  Future<void> saveSelectedPresetId(String? presetId) async {
    Logger.info('Saving selected preset ID: $presetId');
    // presetId가 null일 경우 빈 문자열 저장 또는 키 자체를 삭제할 수도 있으나, 여기서는 빈 문자열 저장
    await _settingsDao.saveSetting(AppConstants.settingsKeySelectedPresetId, presetId ?? '');
  }
  // --- ---

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
    await _initializeDefaultSettings(); // 초기화 시 기본 프리셋 포함
  }
}