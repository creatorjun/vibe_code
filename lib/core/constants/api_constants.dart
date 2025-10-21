class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://openrouter.ai/api/v1';

  // Endpoints
  static const String chatCompletionsEndpoint = '/chat/completions';
  static const String modelsEndpoint = '/models';

  // Headers
  static const String headerAuthorization = 'Authorization';
  static const String headerContentType = 'Content-Type';
  static const String headerHttpReferer = 'HTTP-Referer';
  static const String headerXTitle = 'X-Title';

  // Content Types
  static const String contentTypeJson = 'application/json';
  static const String contentTypeStream = 'text/event-stream';

  // Request Settings
  static const bool streamEnabled = true;
  static const double defaultTemperature = 0.7;
  static const int defaultMaxTokens = 4096;

  // Models
  static const String defaultModel = 'anthropic/claude-3.5-sonnet';
  static const List<String> availableModels = [
    'anthropic/claude-3.5-sonnet',
    'anthropic/claude-3-opus',
    'anthropic/claude-3-haiku',
    'openai/gpt-4-turbo',
    'openai/gpt-4',
    'openai/gpt-3.5-turbo',
    'google/gemini-pro',
    'meta-llama/llama-3-70b-instruct',
  ];

  // System Prompts
  static const String defaultSystemPrompt = '''
You are a helpful AI assistant specialized in coding and technical discussions.
You provide clear, concise, and accurate responses.
When writing code, always use proper formatting and include comments when necessary.
''';

  // Private constructor
  ApiConstants._();
}
