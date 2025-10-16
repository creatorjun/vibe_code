enum MessageRole {
  user,
  assistant,
}

class Message {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
  });

  // Mock 데이터 생성용
  factory Message.mock({
    required String content,
    required MessageRole role,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: role,
      timestamp: DateTime.now(),
    );
  }
}
