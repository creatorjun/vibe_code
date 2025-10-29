// lib/domain/providers/settings_provider.dart

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../data/models/settings_state.dart';
import '../../data/repositories/settings_repository.dart';
import 'database_provider.dart';

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  late final SettingsRepository _repository;
  final _uuid = const Uuid();

  @override
  Future<SettingsState> build() async {
    final database = ref.read(databaseProvider);
    _repository = SettingsRepository(database.settingsDao);
    return await _repository.loadSettings();
  }

  // ===== API Key =====
  Future<void> updateApiKey(String apiKey) async {
    state = await AsyncValue.guard(() async {
      Logger.info('Updating API key');
      await _repository.saveApiKey(apiKey);
      return state.requireValue.copyWith(apiKey: apiKey);
    });
  }

  // ===== Theme Mode =====
  Future<void> updateThemeMode(String themeMode) async {
    state = await AsyncValue.guard(() async {
      Logger.info('Updating theme mode: $themeMode');
      await _repository.saveThemeMode(themeMode);
      return state.requireValue.copyWith(themeMode: themeMode);
    });
  }

  // ===== Max History Messages =====
  Future<void> updateMaxHistoryMessages(int maxMessages) async {
    state = await AsyncValue.guard(() async {
      Logger.info('Updating max history messages: $maxMessages');
      await _repository.saveMaxHistoryMessages(maxMessages);
      return state.requireValue.copyWith(maxHistoryMessages: maxMessages);
    });
  }

  // ===== Prompt Presets =====

  /// 프리셋 선택/해제
  Future<void> selectPreset(String? presetId) async {
    state = await AsyncValue.guard(() async {
      final current = state.requireValue;

      if (presetId == null) {
        Logger.info('Deselecting preset (Off)');
        await _repository.saveSelectedPresetId(null);

        final savedPipelineJson = await _repository.getSetting(
          AppConstants.settingsKeyModelPipeline,
        );

        if (savedPipelineJson != null) {
          try {
            final decoded = jsonDecode(savedPipelineJson) as List;
            final savedPipeline = decoded
                .map((e) => ModelConfig.fromJson(e as Map<String, dynamic>))
                .toList();

            final restoredPipeline = [...current.modelPipeline];
            for (int i = 0; i < restoredPipeline.length; i++) {
              if (i < savedPipeline.length) {
                restoredPipeline[i] = restoredPipeline[i].copyWith(
                  systemPrompt: savedPipeline[i].systemPrompt,
                );
              } else {
                restoredPipeline[i] = restoredPipeline[i].copyWith(
                  systemPrompt: '',
                );
              }
            }

            return current.copyWith(
              selectedPresetId: null,
              modelPipeline: restoredPipeline,
            );
          } catch (e) {
            Logger.error('Failed to restore original prompts.', e);
          }
        }

        return current.copyWith(selectedPresetId: null);
      }

      final preset = current.promptPresets.firstWhere(
            (p) => p.id == presetId,
        orElse: () {
          throw Exception('Preset not found: $presetId');
        },
      );

      Logger.info('Selecting preset: ${preset.name}');
      await _repository.saveSelectedPresetId(presetId);

      final updatedPipeline = [...current.modelPipeline];
      for (int i = 0; i < updatedPipeline.length; i++) {
        if (i < preset.prompts.length) {
          updatedPipeline[i] = updatedPipeline[i].copyWith(
            systemPrompt: preset.prompts[i],
          );
        } else {
          updatedPipeline[i] = updatedPipeline[i].copyWith(systemPrompt: '');
        }
      }

      return current.copyWith(
        selectedPresetId: presetId,
        modelPipeline: updatedPipeline,
      );
    });
  }

  /// 새 프리셋 추가 (최대 5개 제한)
  Future<void> addPreset(String name, List<String> prompts) async {
    state = await AsyncValue.guard(() async {
      final current = state.requireValue;

      // 최대 5개 제한
      if (current.promptPresets.length >= 5) {
        throw Exception('프리셋은 최대 5개까지만 생성할 수 있습니다.');
      }

      final newPreset = PromptPreset(
        id: _uuid.v4(),
        name: name,
        prompts: prompts,
      );

      final updated = [...current.promptPresets, newPreset];

      Logger.info('Adding new preset: $name (ID: ${newPreset.id})');
      await _repository.savePromptPresets(updated);

      return current.copyWith(promptPresets: updated);
    });
  }

  /// 빈 프롬프트로 새 프리셋 추가
  Future<void> addEmptyPreset(String name) async {
    await addPreset(name, ['']);
  }

  /// 프리셋 이름 변경
  Future<void> renamePreset(String id, String newName) async {
    state = await AsyncValue.guard(() async {
      final current = state.requireValue;

      final updatedPresets = current.promptPresets.map((preset) {
        if (preset.id == id) {
          return preset.copyWith(name: newName);
        }
        return preset;
      }).toList();

      Logger.info('Renaming preset ID: $id to "$newName"');
      await _repository.savePromptPresets(updatedPresets);

      return current.copyWith(promptPresets: updatedPresets);
    });
  }

  /// 프리셋 삭제
  Future<void> deletePreset(String id) async {
    state = await AsyncValue.guard(() async {
      final current = state.requireValue;

      final updatedPresets = current.promptPresets
          .where((p) => p.id != id)
          .toList();

      String? newSelectedPresetId = current.selectedPresetId;
      List<ModelConfig> updatedPipeline = current.modelPipeline;

      if (current.selectedPresetId == id) {
        Logger.info('Deselecting preset as it is being removed.');
        newSelectedPresetId = null;
        await _repository.saveSelectedPresetId(null);

        final savedPipelineJson = await _repository.getSetting(
          AppConstants.settingsKeyModelPipeline,
        );

        if (savedPipelineJson != null) {
          try {
            final decoded = jsonDecode(savedPipelineJson) as List;
            final savedPipeline = decoded
                .map((e) => ModelConfig.fromJson(e as Map<String, dynamic>))
                .toList();

            updatedPipeline = [...current.modelPipeline];
            for (int i = 0; i < updatedPipeline.length; i++) {
              if (i < savedPipeline.length) {
                updatedPipeline[i] = updatedPipeline[i].copyWith(
                  systemPrompt: savedPipeline[i].systemPrompt,
                );
              } else {
                updatedPipeline[i] = updatedPipeline[i].copyWith(
                  systemPrompt: '',
                );
              }
            }
          } catch (e) {
            Logger.error(
              'Failed to restore original prompts on preset removal.',
              e,
            );
          }
        }
      }

      Logger.info('Removing preset ID: $id');
      await _repository.savePromptPresets(updatedPresets);

      return current.copyWith(
        promptPresets: updatedPresets,
        selectedPresetId: newSelectedPresetId,
        modelPipeline: updatedPipeline,
      );
    });
  }

  // ===== Model Pipeline =====
  Future<void> updateModelPipeline(List<ModelConfig> pipeline) async {
    if (pipeline.length > 5) {
      throw Exception('최대 5개의 모델만 추가할 수 있습니다.');
    }

    state = await AsyncValue.guard(() async {
      Logger.info('Updating model pipeline: ${pipeline.length} models');

      final currentPreset = state.requireValue.selectedPreset;
      if (currentPreset != null) {
        for (int i = 0; i < pipeline.length; i++) {
          if (i < currentPreset.prompts.length) {
            pipeline[i] = pipeline[i].copyWith(
              systemPrompt: currentPreset.prompts[i],
            );
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
    final current = state.requireValue;
    final model = current.modelPipeline[index];
    final enabledCount = current.enabledModels.length;

    if (model.isEnabled && enabledCount <= 1) {
      throw Exception('최소 1개의 모델은 활성화되어야 합니다.');
    }

    await updateModelConfig(index, isEnabled: !model.isEnabled);
  }

  Future<void> updateModelConfig(
      int index, {
        String? modelId,
        String? systemPrompt,
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
      ModelConfig newConfig = oldConfig;

      if (systemPrompt != null) {
        Logger.info('Updating system prompt at index $index');

        if (selectedPresetId != null) {
          final presetIndex = currentPresets.indexWhere(
                (p) => p.id == selectedPresetId,
          );

          if (presetIndex != -1) {
            final presetToUpdate = currentPresets[presetIndex];
            final updatedPrompts = List<String>.from(presetToUpdate.prompts);

            if (index < updatedPrompts.length) {
              updatedPrompts[index] = systemPrompt;
            } else {
              Logger.warning(
                'Attempted to update prompt outside preset bounds. Index: $index, Preset prompts length: ${updatedPrompts.length}',
              );
              while (updatedPrompts.length <= index) {
                updatedPrompts.add('');
              }
              updatedPrompts[index] = systemPrompt;
            }

            currentPresets[presetIndex] = presetToUpdate.copyWith(
              prompts: updatedPrompts,
            );

            await _repository.savePromptPresets(currentPresets);
            Logger.info(
              'Updated preset "${presetToUpdate.name}" prompt at index $index.',
            );

            newConfig = newConfig.copyWith(systemPrompt: systemPrompt);
            currentPipeline[index] = newConfig;

            return current.copyWith(
              promptPresets: currentPresets,
              modelPipeline: currentPipeline,
            );
          } else {
            Logger.error(
              'Selected preset ID $selectedPresetId not found in presets list.',
            );
            await _repository.saveSelectedPresetId(null);

            newConfig = newConfig.copyWith(systemPrompt: systemPrompt);
            currentPipeline[index] = newConfig;
            await _repository.saveModelPipeline(currentPipeline);

            return current.copyWith(
              modelPipeline: currentPipeline,
              selectedPresetId: null,
            );
          }
        } else {
          newConfig = newConfig.copyWith(systemPrompt: systemPrompt);
          currentPipeline[index] = newConfig;
          await _repository.saveModelPipeline(currentPipeline);

          Logger.info(
            'Updated model pipeline system prompt at index $index (no preset).',
          );

          return current.copyWith(modelPipeline: currentPipeline);
        }
      }

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
        Logger.info(
          'Updating model config (modelId/isEnabled) at index $index',
        );
        await _repository.saveModelPipeline(currentPipeline);
        return current.copyWith(modelPipeline: currentPipeline);
      }

      return current;
    });
  }
}
