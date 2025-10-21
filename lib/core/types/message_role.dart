enum MessageRole {
  user('user'),
  assistant('assistant'),
  system('system');

  final String value;
  const MessageRole(this.value);

  static MessageRole fromString(String value) {
    return MessageRole.values.firstWhere(
          (role) => role.value == value,
      orElse: () => MessageRole.user,
    );
  }
}
