// lib/data/models/api_request.dart

class ChatMessage {
  final String role;
  final dynamic content; // ✅ String 또는 List<Map> 지원

  const ChatMessage({
    required this.role,
    required this.content,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'], // dynamic으로 받음
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }

  /// ✅ 텍스트 메시지 생성
  factory ChatMessage.text({
    required String role,
    required String text,
  }) {
    return ChatMessage(
      role: role,
      content: text,
    );
  }

  /// ✅ 이미지 포함 메시지 생성 (Vision API)
  factory ChatMessage.withImages({
    required String role,
    required String text,
    required List<String> base64Images, // base64 인코딩된 이미지들
  }) {
    final contentList = <Map<String, dynamic>>[
      {
        'type': 'text',
        'text': text,
      },
      ...base64Images.map((base64) => {
        'type': 'image_url',
        'image_url': {
          'url': 'data:image/jpeg;base64,$base64',
        },
      }),
    ];

    return ChatMessage(
      role: role,
      content: contentList,
    );
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
