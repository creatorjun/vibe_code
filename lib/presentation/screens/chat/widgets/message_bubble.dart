// lib/presentation/screens/chat/widgets/message_bubble.dart

import 'package:flutter/material.dart';
import 'package:vibe_code/data/database/app_database.dart';
import 'user_message_bubble.dart';
import 'ai_message_bubble.dart';

/// 메시지 버블 팩토리
class MessageBubble {
  final Message message;

  const MessageBubble({required this.message});

  /// 메시지를 Sliver로 변환
  List<Widget> buildAsSliver(BuildContext context) {
    if (message.role == 'user') {
      return [SliverToBoxAdapter(child: UserMessageBubble(message: message))];
    } else {
      return AiMessageBubble(message: message).buildAsSliver(context);
    }
  }
}
