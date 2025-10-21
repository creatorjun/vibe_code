import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/logger.dart';

/// 스트리밍 상태 Provider
class StreamingStateNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void start() {
    Logger.info('Streaming started');
    state = true;
  }

  void stop() {
    Logger.info('Streaming stopped');
    state = false;
  }
}

final streamingStateProvider = NotifierProvider<StreamingStateNotifier, bool>(
  StreamingStateNotifier.new,
);

/// 현재 스트리밍 중인 메시지 ID Provider
class CurrentStreamingMessageNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int messageId) {
    Logger.info('Setting streaming message: $messageId');
    state = messageId;
  }

  void clear() {
    Logger.info('Clearing streaming message');
    state = null;
  }
}

final currentStreamingMessageProvider = NotifierProvider<CurrentStreamingMessageNotifier, int?>(
  CurrentStreamingMessageNotifier.new,
);
