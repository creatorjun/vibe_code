class ChatMessage {
  final String role;
  final String content;

  const ChatMessage({
    required this.role,
    required this.content,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
}

class ChatRequest {
  final String model;
  final List<ChatMessage> messages;
  final bool stream;
  final double temperature;
  final int maxTokens;

  const ChatRequest({
    required this.model,
    required this.messages,
    this.stream = true,
    this.temperature = 0.7,
    this.maxTokens = 4096,
  });

  factory ChatRequest.fromJson(Map<String, dynamic> json) {
    return ChatRequest(
      model: json['model'] as String,
      messages: (json['messages'] as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      stream: json['stream'] as bool? ?? true,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: json['max_tokens'] as int? ?? 4096,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'stream': stream,
      'temperature': temperature,
      'max_tokens': maxTokens,
    };
  }
}
