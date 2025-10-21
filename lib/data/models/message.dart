class MessageModel {
  final int id;
  final int sessionId;
  final String content;
  final String role;
  final DateTime createdAt;
  final bool isStreaming;
  final String? model;

  const MessageModel({
    required this.id,
    required this.sessionId,
    required this.content,
    required this.role,
    required this.createdAt,
    this.isStreaming = false,
    this.model,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int,
      sessionId: json['sessionId'] as int,
      content: json['content'] as String,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isStreaming: json['isStreaming'] as bool? ?? false,
      model: json['model'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'content': content,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'isStreaming': isStreaming,
      'model': model,
    };
  }

  MessageModel copyWith({
    int? id,
    int? sessionId,
    String? content,
    String? role,
    DateTime? createdAt,
    bool? isStreaming,
    String? model,
  }) {
    return MessageModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      content: content ?? this.content,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      isStreaming: isStreaming ?? this.isStreaming,
      model: model ?? this.model,
    );
  }
}
