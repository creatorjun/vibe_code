// lib/domain/providers/ai_service_provider.dart (신규)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/openrouter_service.dart';
import 'settings_provider.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  final settings = ref.watch(settingsProvider).requireValue;

  // API 키가 없으면 예외
  if (settings.apiKey.isEmpty) {
    throw Exception('API 키가 설정되지 않았습니다.');
  }

  final service = OpenRouterService(settings.apiKey);

  // Provider가 dispose될 때 서비스도 정리
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
