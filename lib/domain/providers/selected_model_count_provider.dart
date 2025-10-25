// lib/domain/providers/selected_model_count_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';

/// 현재 파이프라인에 있는 전체 모델 개수
final pipelineModelCountProvider = Provider<int>((ref) {
  final settingsAsync = ref.watch(settingsProvider);

  return settingsAsync.when(
    data: (settings) => settings.modelPipeline.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// 현재 선택된 파이프라인 깊이 (사용자가 선택한 모델 개수)
class SelectedPipelineDepthNotifier extends Notifier<int> {
  @override
  int build() {
    return 1;
  }

  /// 깊이 설정
  void setDepth(int depth) {
    final pipelineCount = ref.read(pipelineModelCountProvider);
    if (depth >= 1 && depth <= pipelineCount) {
      state = depth;
    }
  }
}

final selectedPipelineDepthProvider =
NotifierProvider<SelectedPipelineDepthNotifier, int>(
  SelectedPipelineDepthNotifier.new,
);
