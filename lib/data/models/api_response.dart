class ChatResponseMessage {
  final String role;
  final String content;

  const ChatResponseMessage({
    required this.role,
    required this.content,
  });

  factory ChatResponseMessage.fromJson(Map<String, dynamic> json) {
    return ChatResponseMessage(
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

class ChatResponseChoice {
  final int index;
  final ChatResponseMessage message;
  final String? finishReason;

  const ChatResponseChoice({
    required this.index,
    required this.message,
    this.finishReason,
  });

  factory ChatResponseChoice.fromJson(Map<String, dynamic> json) {
    return ChatResponseChoice(
      index: json['index'] as int,
      message: ChatResponseMessage.fromJson(json['message'] as Map<String, dynamic>),
      finishReason: json['finish_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'message': message.toJson(),
      'finish_reason': finishReason,
    };
  }
}

class ChatResponse {
  final String id;
  final String object;
  final int created;
  final String model;
  final List<ChatResponseChoice> choices;

  const ChatResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      id: json['id'] as String,
      object: json['object'] as String,
      created: json['created'] as int,
      model: json['model'] as String,
      choices: (json['choices'] as List)
          .map((e) => ChatResponseChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'object': object,
      'created': created,
      'model': model,
      'choices': choices.map((c) => c.toJson()).toList(),
    };
  }
}

// 스트리밍 청크용
class ChatStreamDelta {
  final String? role;
  final String? content;

  const ChatStreamDelta({
    this.role,
    this.content,
  });

  factory ChatStreamDelta.fromJson(Map<String, dynamic> json) {
    return ChatStreamDelta(
      role: json['role'] as String?,
      content: json['content'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
}

class ChatStreamChoice {
  final int index;
  final ChatStreamDelta delta;
  final String? finishReason;

  const ChatStreamChoice({
    required this.index,
    required this.delta,
    this.finishReason,
  });

  factory ChatStreamChoice.fromJson(Map<String, dynamic> json) {
    return ChatStreamChoice(
      index: json['index'] as int,
      delta: ChatStreamDelta.fromJson(json['delta'] as Map<String, dynamic>),
      finishReason: json['finish_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'delta': delta.toJson(),
      'finish_reason': finishReason,
    };
  }
}

class ChatStreamResponse {
  final String id;
  final String object;
  final int created;
  final String model;
  final List<ChatStreamChoice> choices;

  const ChatStreamResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
  });

  factory ChatStreamResponse.fromJson(Map<String, dynamic> json) {
    return ChatStreamResponse(
      id: json['id'] as String,
      object: json['object'] as String,
      created: json['created'] as int,
      model: json['model'] as String,
      choices: (json['choices'] as List)
          .map((e) => ChatStreamChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'object': object,
      'created': created,
      'model': model,
      'choices': choices.map((c) => c.toJson()).toList(),
    };
  }
}
