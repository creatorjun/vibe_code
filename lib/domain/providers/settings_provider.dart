// lib/domain/providers/settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Future<SettingsState> build() async {
    Logger.info('Initializing settings provider');
    final db = ref.watch(databaseProvider);
    _repository = SettingsRepository(db.settingsDao);

    final settings = await _repository.loadSettings();
    Logger.info('Settings loaded: ${settings.modelPipeline.length} models');
    return settings;
  }

  // API 키 업데이트
  Future<void> updateApiKey(String apiKey) async {
    state = await AsyncValue.guard(() async {
      Logger.info('Updating API key');
      await _repository.saveApiKey(apiKey);
      return state.requireValue.copyWith(apiKey: apiKey);
    });
  }

  // 모델 파이프라인 전체 업데이트
  Future<void> updateModelPipeline(List<ModelConfig> pipeline) async {
    if (pipeline.length > 5) {
      throw Exception('최대 5개의 모델만 추가할 수 있습니다.');
    }

    state = await AsyncValue.guard(() async {
      Logger.info('Updating model pipeline: ${pipeline.length} models');
      await _repository.saveModelPipeline(pipeline);
      return state.requireValue.copyWith(modelPipeline: pipeline);
    });
  }

  // 모델 추가
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

  // 모델 제거
  Future<void> removeModel(int index) async {
    final current = state.requireValue;

    if (current.modelPipeline.length <= 1) {
      throw Exception('최소 1개의 모델은 유지해야 합니다.');
    }

    final updated = [...current.modelPipeline];
    updated.removeAt(index);

    // order 재정렬
    for (var i = 0; i < updated.length; i++) {
      updated[i] = updated[i].copyWith(order: i);
    }

    await updateModelPipeline(updated);
  }

  // 특정 모델의 설정 업데이트
  Future<void> updateModelConfig(
      int index, {
        String? modelId,
        String? systemPrompt,
        bool? isEnabled,
      }) async {
    final current = state.requireValue;

    if (index < 0 || index >= current.modelPipeline.length) {
      throw Exception('잘못된 모델 인덱스입니다.');
    }

    final updated = [...current.modelPipeline];
    final oldConfig = updated[index];

    // Freezed copyWith 사용
    updated[index] = oldConfig.copyWith(
      modelId: modelId ?? oldConfig.modelId,
      systemPrompt: systemPrompt ?? oldConfig.systemPrompt,
      isEnabled: isEnabled ?? oldConfig.isEnabled,
    );

    await updateModelPipeline(updated);
  }

  // 모델 순서 변경
  Future<void> reorderModels(int oldIndex, int newIndex) async {
    final current = state.requireValue;
    final updated = [...current.modelPipeline];

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);

    // order 재정렬
    for (var i = 0; i < updated.length; i++) {
      updated[i] = updated[i].copyWith(order: i);
    }

    await updateModelPipeline(updated);
  }

  // 모델 활성화/비활성화 토글
  Future<void> toggleModel(int index) async {
    final current = state.requireValue;
    final model = current.modelPipeline[index];

    // 최소 1개는 활성화 상태여야 함
    final enabledCount = current.enabledModels.length;
    if (model.isEnabled && enabledCount <= 1) {
      throw Exception('최소 1개의 모델은 활성화되어야 합니다.');
    }

    await updateModelConfig(index, isEnabled: !model.isEnabled);
  }

  // 테마 모드 업데이트
  Future<void> updateThemeMode(String themeMode) async {
    state = await AsyncValue.guard(() async {
      Logger.info('Updating theme mode: $themeMode');
      await _repository.saveThemeMode(themeMode);
      return state.requireValue.copyWith(themeMode: themeMode);
    });
  }

  // 설정 초기화
  Future<void> resetSettings() async {
    state = await AsyncValue.guard(() async {
      Logger.info('Resetting settings');
      await _repository.resetSettings();
      return const SettingsState();
    });
  }
}
