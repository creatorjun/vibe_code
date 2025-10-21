import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatInputStateNotifier extends Notifier<double> {
  @override
  double build() {
    return 56.0;
  }

  void updateHeight(double height) {
    state = height;
  }
}

final chatInputHeightProvider = NotifierProvider<ChatInputStateNotifier, double>(
  ChatInputStateNotifier.new,
);
