// lib/domain/providers/settings_provider.dart (수정)
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/settings_state.dart';
import '../../data/repositories/settings_repository.dart';
import '../../core/utils/logger.dart';
import 'database_provider.dart';

// Settings Provider
final settingsProvider =
AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  late final SettingsRepository _repository;
  final Uuid _uuid = const Uuid();

  @override
  Future<SettingsState> build() async {
    Logger.info('Initializing settings provider');
    final db = ref.watch(databaseProvider);
    _repository = SettingsRepository(db.settingsDao);

    final settings = await _repository.loadSettings();
    Logger.info('Settings loaded: ${settings.modelPipeline.length} models, ${settings.promptPresets.length} presets');
    return settings;
  }

  // --- 기존 메서드들 (API 키, 테마 등) ---
  Future<void> updateApiKey(String apiKey) async {
    state = await AsyncValue.guard(() async {
      final current = state.requireValue;
      Logger.info('Updating API key');
      await _repository.saveApiKey(apiKey);
      return current.copyWith(apiKey: apiKey);
    });
  }

  Future<void> updateThemeMode(String themeMode) async {
    state = await AsyncValue.guard(() async {
      final current = state.requireValue;
      Logger.info('Updating theme mode: $themeMode');
      await _repository.saveThemeMode(themeMode);
      return current.copyWith(themeMode: themeMode);
    });
  }

  Future<void> resetSettings() async {
    state = await AsyncValue.guard(() async {
      Logger.info('Resetting all settings');
      await _repository.resetSettings();
      return await _repository.loadSettings();
    });
  }


  // --- 모델 파이프라인 관련 메서드 ---

  Future<void> updateModelPipeline(List<ModelConfig> pipeline) async {
    if (pipeline.length > 5) {
      throw Exception('최대 5개의 모델만 추가할 수 있습니다.');
    }

    state = await AsyncValue.guard(() async {
      Logger.info('Updating model pipeline: ${pipeline.length} models');
      final currentPreset = state.requireValue.selectedPreset;
      if (currentPreset != null) {
        // 프리셋이 선택된 경우, 시스템 프롬프트를 프리셋 값으로 덮어씀
        for (int i = 0; i < pipeline.length; i++) {
          if (i < currentPreset.prompts.length) {
            pipeline[i] = pipeline[i].copyWith(systemPrompt: currentPreset.prompts[i]);
          } else {
            pipeline[i] = pipeline[i].copyWith(systemPrompt: '');
          }
        }
        Logger.info('Applied preset prompts to model pipeline');
      }
      await _repository.saveModelPipeline(pipeline);
      return state.requireValue.copyWith(modelPipeline: pipeline);
    });
  }

  Future<void> addModel(String modelId, {String systemPrompt = ''}) async {
    final current = state.requireValue;

    if (current.modelPipeline.length >= 5) {
      throw Exception('최대 5개의 모델만 추가할 수 있습니다.');
    }

    final newModel = ModelConfig(
      modelId: modelId,
      systemPrompt: systemPrompt,
      order: current.modelPipeline.length,
    );

    final updated = [...current.modelPipeline, newModel];
    await updateModelPipeline(updated);
  }

  Future<void> removeModel(int index) async {
    final current = state.requireValue;

    if (current.modelPipeline.length <= 1) {
      throw Exception('최소 1개의 모델은 유지해야 합니다.');
    }

    final updated = [...current.modelPipeline];
    updated.removeAt(index);

    for (var i = 0; i < updated.length; i++) {
      updated[i] = updated[i].copyWith(order: i);
    }

    await updateModelPipeline(updated);
  }

  Future<void> reorderModels(int oldIndex, int newIndex) async {
    // ... (기존 코드 유지)
    final current = state.requireValue;
    final updated = [...current.modelPipeline];

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);

    for (var i = 0; i < updated.length; i++) {
      updated[i] = updated[i].copyWith(order: i);
    }

    await updateModelPipeline(updated);
  }

  Future<void> toggleModel(int index) async {
    // ... (기존 코드 유지)
    final current = state.requireValue;
    final model = current.modelPipeline[index];

    final enabledCount = current.enabledModels.length;
    if (model.isEnabled && enabledCount <= 1) {
      throw Exception('최소 1개의 모델은 활성화되어야 합니다.');
    }

    await updateModelConfig(index, isEnabled: !model.isEnabled);
  }

  /// 특정 모델의 설정 업데이트 (시스템 프롬프트 편집 로직 수정)
  Future<void> updateModelConfig(
      int index, {
        String? modelId,
        String? systemPrompt, // 새로 입력된 시스템 프롬프트 값
        bool? isEnabled,
      }) async {
    state = await AsyncValue.guard(() async {
      final current = state.requireValue;
      final currentPipeline = [...current.modelPipeline];
      final currentPresets = [...current.promptPresets];
      final selectedPresetId = current.selectedPresetId;

      if (index < 0 || index >= currentPipeline.length) {
        throw Exception('잘못된 모델 인덱스입니다.');
      }

      final oldConfig = currentPipeline[index];
      ModelConfig newConfig = oldConfig; // 수정될 모델 설정

      // --- 시스템 프롬프트 업데이트 로직 ---
      if (systemPrompt != null) {
        Logger.info('Updating system prompt at index $index');

        if (selectedPresetId != null) {
          // **프리셋 선택된 경우: 프리셋 데이터를 직접 수정**
          final presetIndex = currentPresets.indexWhere((p) => p.id == selectedPresetId);
          if (presetIndex != -1) {
            final presetToUpdate = currentPresets[presetIndex];
            // prompts 리스트 복사 및 수정
            final updatedPrompts = List<String>.from(presetToUpdate.prompts);
            if (index < updatedPrompts.length) {
              updatedPrompts[index] = systemPrompt; // 해당 인덱스의 프롬프트 변경
            } else {
              // 파이프라인 인덱스가 프리셋 프롬프트 길이보다 길 경우 (이론상 발생하기 어려움)
              // 필요하다면 리스트를 확장하고 값을 채우는 로직 추가 가능
              Logger.warning('Attempted to update prompt outside preset bounds. Index: $index, Preset prompts length: ${updatedPrompts.length}');
              // 일단 길이에 맞춰서 추가 (선택적)
              while (updatedPrompts.length <= index) {
                updatedPrompts.add('');
              }
              updatedPrompts[index] = systemPrompt;
            }

            // 수정된 prompts로 프리셋 객체 업데이트
            currentPresets[presetIndex] = presetToUpdate.copyWith(prompts: updatedPrompts);

            // 변경된 프리셋 목록 저장
            await _repository.savePromptPresets(currentPresets);
            Logger.info('Updated preset "${presetToUpdate.name}" prompt at index $index.');

            // UI 반영을 위해 modelPipeline의 systemPrompt도 업데이트
            newConfig = newConfig.copyWith(systemPrompt: systemPrompt);
            currentPipeline[index] = newConfig;
            // modelPipeline 저장 불필요 (프리셋이 원본 데이터)

            // 상태 업데이트 (presets와 pipeline 둘 다 업데이트)
            return current.copyWith(
              promptPresets: currentPresets,
              modelPipeline: currentPipeline, // UI 즉시 반영 위함
            );

          } else {
            // 선택된 ID에 해당하는 프리셋이 없는 비정상 상황
            Logger.error('Selected preset ID $selectedPresetId not found in presets list.');
            // 이 경우, 프리셋 선택을 해제하고 모델 파이프라인 직접 수정
            await _repository.saveSelectedPresetId(null);
            newConfig = newConfig.copyWith(systemPrompt: systemPrompt);
            currentPipeline[index] = newConfig;
            await _repository.saveModelPipeline(currentPipeline);
            return current.copyWith(
              modelPipeline: currentPipeline,
              selectedPresetId: null, // 프리셋 선택 해제
            );
          }

        } else {
          // **프리셋 "끄기" 상태: 모델 파이프라인 직접 수정**
          newConfig = newConfig.copyWith(systemPrompt: systemPrompt);
          currentPipeline[index] = newConfig;
          await _repository.saveModelPipeline(currentPipeline); // 변경된 파이프라인 저장
          Logger.info('Updated model pipeline system prompt at index $index (no preset).');

          // 상태 업데이트
          return current.copyWith(modelPipeline: currentPipeline);
        }
      }
      // --- ---

      // 다른 설정(modelId, isEnabled) 업데이트 로직 (기존과 유사)
      bool configChanged = false;
      if (modelId != null && modelId != oldConfig.modelId) {
        newConfig = newConfig.copyWith(modelId: modelId);
        configChanged = true;
      }
      if (isEnabled != null && isEnabled != oldConfig.isEnabled) {
        newConfig = newConfig.copyWith(isEnabled: isEnabled);
        configChanged = true;
      }

      if (configChanged) {
        currentPipeline[index] = newConfig;
        Logger.info('Updating model config (modelId/isEnabled) at index $index');
        await _repository.saveModelPipeline(currentPipeline);
        return current.copyWith(modelPipeline: currentPipeline);
      }

      // 변경 사항이 없으면 기존 상태 반환
      return current;
    });
  }


  // --- 프리셋 관련 메서드 ---

  /// 프리셋 선택 (ID 또는 null 전달)
  Future<void> selectPreset(String? presetId) async {
    state = await AsyncValue.guard(() async {
      // ... (이전과 동일, 수정 없음) ...
      final current = state.requireValue;
      PromptPreset? selectedPreset;
      if (presetId != null) {
        try {
          selectedPreset = current.promptPresets.firstWhere((p) => p.id == presetId);
        } catch (_) {
          Logger.warning('Preset with ID $presetId not found.');
          presetId = null;
        }
      }

      Logger.info('Selecting preset: $presetId');
      await _repository.saveSelectedPresetId(presetId);

      List<ModelConfig> updatedPipeline = [...current.modelPipeline];
      if (selectedPreset != null) {
        // 파이프라인에 프리셋 프롬프트 적용
        Logger.info('Applying selected preset prompts to pipeline.');
        for (int i = 0; i < updatedPipeline.length; i++) {
          if (i < selectedPreset.prompts.length) {
            updatedPipeline[i] = updatedPipeline[i].copyWith(systemPrompt: selectedPreset.prompts[i]);
          } else {
            updatedPipeline[i] = updatedPipeline[i].copyWith(systemPrompt: '');
          }
        }
        // 프리셋 적용 시에는 ModelPipeline을 저장하지 않음 (UI 반영용 임시 값)
        // await _repository.saveModelPipeline(updatedPipeline);
      } else {
        // 프리셋 해제 시: ModelConfig에 저장된 원래 프롬프트로 복원
        Logger.info('Deselecting preset, restoring original prompts to pipeline.');
        // 저장된 ModelPipeline 설정을 다시 로드하여 적용
        final savedPipelineJson = await _repository.getSetting(AppConstants.settingsKeyModelPipeline);
        if (savedPipelineJson != null) {
          try {
            final decoded = jsonDecode(savedPipelineJson) as List;
            final savedPipeline = decoded
                .map((e) => ModelConfig.fromJson(e as Map<String, dynamic>))
                .toList();

            // 현재 파이프라인 길이에 맞춰서 저장된 프롬프트 적용
            for (int i = 0; i < updatedPipeline.length; i++) {
              if (i < savedPipeline.length) {
                updatedPipeline[i] = updatedPipeline[i].copyWith(systemPrompt: savedPipeline[i].systemPrompt);
              } else {
                updatedPipeline[i] = updatedPipeline[i].copyWith(systemPrompt: ''); // 길이를 넘어가는 부분은 초기화
              }
            }

          } catch(e) {
            Logger.error('Failed to restore original prompts on preset deselection.', e);
            // 복원 실패 시 현재 상태 유지 또는 다른 처리 가능
          }
        }
      }

      return current.copyWith(
        selectedPresetId: presetId,
        modelPipeline: updatedPipeline, // UI 반영
      );
    });
  }

  /// 프리셋 추가 (SettingsScreen에서 사용)
  Future<void> addPreset(String name, List<String> prompts) async {
    // ... (이전과 동일, 수정 없음) ...
    state = await AsyncValue.guard(() async {
      final current = state.requireValue;
      final newPreset = PromptPreset(
        id: _uuid.v4(),
        name: name,
        prompts: prompts,
      );
      final updatedPresets = [...current.promptPresets, newPreset];
      Logger.info('Adding new preset: ${newPreset.name}');
      await _repository.savePromptPresets(updatedPresets);
      return current.copyWith(promptPresets: updatedPresets);
    });
  }

  /// 프리셋 수정 (SettingsScreen에서 사용 - prompts 수정 로직 변경됨)
  Future<void> updatePreset(String id, {String? name, List<String>? prompts}) async {
    state = await AsyncValue.guard(() async {
      final current = state.requireValue;
      final index = current.promptPresets.indexWhere((p) => p.id == id);
      if (index == -1) throw Exception('Preset not found');

      final updatedPresets = [...current.promptPresets];
      final oldPreset = updatedPresets[index];
      // copyWith 사용하여 업데이트
      updatedPresets[index] = oldPreset.copyWith(
        name: name ?? oldPreset.name,
        prompts: prompts ?? oldPreset.prompts,
      );

      Logger.info('Updating preset: ${updatedPresets[index].name}');
      await _repository.savePromptPresets(updatedPresets);

      // 수정된 프리셋이 현재 선택된 프리셋이라면 파이프라인 UI도 업데이트
      List<ModelConfig> updatedPipeline = current.modelPipeline; // 기본값은 현재 파이프라인
      if (current.selectedPresetId == id) {
        Logger.info('Updating pipeline UI for the updated selected preset.');
        updatedPipeline = [...current.modelPipeline]; // 복사본 생성
        final updatedPreset = updatedPresets[index];
        for (int i = 0; i < updatedPipeline.length; i++) {
          if (i < updatedPreset.prompts.length) {
            updatedPipeline[i] = updatedPipeline[i].copyWith(systemPrompt: updatedPreset.prompts[i]);
          } else {
            updatedPipeline[i] = updatedPipeline[i].copyWith(systemPrompt: '');
          }
        }
        // 파이프라인 UI 업데이트 시에는 DB 저장 안 함
        // await _repository.saveModelPipeline(updatedPipeline);
      }

      return current.copyWith(
          promptPresets: updatedPresets,
          modelPipeline: updatedPipeline // UI 업데이트 반영
      );
    });
  }


  /// 프리셋 삭제 (SettingsScreen에서 사용)
  Future<void> removePreset(String id) async {
    state = await AsyncValue.guard(() async {
      final current = state.requireValue;
      final updatedPresets = current.promptPresets.where((p) => p.id != id).toList();

      String? newSelectedPresetId = current.selectedPresetId;
      List<ModelConfig> updatedPipeline = current.modelPipeline; // 기본값

      if (current.selectedPresetId == id) {
        Logger.info('Deselecting preset as it is being removed.');
        newSelectedPresetId = null;
        await _repository.saveSelectedPresetId(null);

        // 프리셋 해제 시 모델 파이프라인 복원 로직 추가 (selectPreset과 동일)
        final savedPipelineJson = await _repository.getSetting(AppConstants.settingsKeyModelPipeline);
        if (savedPipelineJson != null) {
          try {
            final decoded = jsonDecode(savedPipelineJson) as List;
            final savedPipeline = decoded
                .map((e) => ModelConfig.fromJson(e as Map<String, dynamic>))
                .toList();
            updatedPipeline = [...current.modelPipeline]; // 복사본 생성
            for (int i = 0; i < updatedPipeline.length; i++) {
              if (i < savedPipeline.length) {
                updatedPipeline[i] = updatedPipeline[i].copyWith(systemPrompt: savedPipeline[i].systemPrompt);
              } else {
                updatedPipeline[i] = updatedPipeline[i].copyWith(systemPrompt: '');
              }
            }
          } catch(e) {
            Logger.error('Failed to restore original prompts on preset removal.', e);
          }
        }
      }

      Logger.info('Removing preset ID: $id');
      await _repository.savePromptPresets(updatedPresets);
      return current.copyWith(
          promptPresets: updatedPresets,
          selectedPresetId: newSelectedPresetId,
          modelPipeline: updatedPipeline // UI 업데이트 반영
      );
    });
  }
// --- ---
}