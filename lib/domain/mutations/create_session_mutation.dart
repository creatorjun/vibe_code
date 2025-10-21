import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../../core/utils/logger.dart';

Future<int> createNewSession(WidgetRef ref, [String? title]) async {
  final chatRepo = ref.read(chatRepositoryProvider);

  Logger.info('Creating new session');

  final sessionId = await chatRepo.createSession(title ?? '새 대화');

  ref.read(activeSessionProvider.notifier).select(sessionId);

  Logger.info('Session created successfully: $sessionId');

  return sessionId;
}
