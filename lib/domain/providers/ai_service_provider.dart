// lib/domain/providers/ai_service_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/openrouter_service.dart';
import '../../data/services/pipeline_service.dart';
import '../../core/utils/logger.dart';
import 'settings_provider.dart';

/// AI 서비스 Provider
final aiServiceProvider = Provider.autoDispose<AIService>((ref) {
  final settings = ref.watch(settingsProvider).requireValue;
  final apiKey = settings.apiKey;

  if (apiKey.isEmpty) {
    Logger.warning('API key is empty');
    throw Exception('API 키가 설정되지 않았습니다');
  }

  Logger.info('Creating AIService with API key');
  final service = OpenRouterService(apiKey);

  ref.onDispose(() {
    Logger.info('Disposing AIService');
    service.dispose();
  });

  return service;
});

/// AI 서비스 팩토리 Provider
/// PipelineService에서 사용하기 위한 팩토리 함수 제공
final aiServiceFactoryProvider = Provider<AIService Function(String apiKey)>((ref) {
  return (String apiKey) {
    Logger.info('Creating AIService via factory');
    return OpenRouterService(apiKey);
  };
});

/// Pipeline 서비스 Provider
final pipelineServiceProvider = Provider.autoDispose<PipelineService>((ref) {
  final settings = ref.watch(settingsProvider).requireValue;
  final apiKey = settings.apiKey;
  final aiServiceFactory = ref.watch(aiServiceFactoryProvider);

  if (apiKey.isEmpty) {
    Logger.warning('API key is empty for pipeline service');
    throw Exception('API 키가 설정되지 않았습니다');
  }

  Logger.info('Creating PipelineService');

  return PipelineService(
    apiKey: apiKey,
    aiServiceFactory: aiServiceFactory,
  );
});
