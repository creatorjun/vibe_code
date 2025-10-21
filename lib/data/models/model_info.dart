// lib/data/models/model_info.dart
/// OpenRouter 모델 정보
class ModelInfo {
  final String id;
  final String name;
  final String provider;
  final int contextLength;
  final double inputCost;  // $ per 1M tokens
  final double outputCost; // $ per 1M tokens
  final bool isFree;
  final List<String> modalities;
  final bool supportsFunctionCalling;
  final String? description;

  const ModelInfo({
    required this.id,
    required this.name,
    required this.provider,
    required this.contextLength,
    required this.inputCost,
    required this.outputCost,
    required this.isFree,
    required this.modalities,
    this.supportsFunctionCalling = false,
    this.description,
  });

  /// 가격 표시 (한국어)
  String get priceDisplay {
    if (isFree) return '무료';
    return '입력: \$${inputCost.toStringAsFixed(2)}/1M · 출력: \$${outputCost.toStringAsFixed(2)}/1M';
  }

  /// Context 길이 표시
  String get contextDisplay {
    if (contextLength >= 1000000) {
      return '${(contextLength / 1000000).toStringAsFixed(1)}M';
    } else if (contextLength >= 1000) {
      return '${(contextLength / 1000).toStringAsFixed(0)}K';
    }
    return '$contextLength';
  }
}

/// 2025년 1월 기준 사용 가능한 모델 목록
class AvailableModels {
  static const List<ModelInfo> all = [
    // === 무료 모델 ===

    // DeepSeek (무료)
    ModelInfo(
      id: 'deepseek/deepseek-r1:free',
      name: 'DeepSeek R1 (무료)',
      provider: 'DeepSeek',
      contextLength: 163840,
      inputCost: 0,
      outputCost: 0,
      isFree: true,
      modalities: ['text'],
      description: '추론 특화 모델, 164K 컨텍스트',
    ),

    ModelInfo(
      id: 'deepseek/deepseek-r1-0528-qwen3-8b:free',
      name: 'DeepSeek R1 0528 Qwen3 8B (무료)',
      provider: 'DeepSeek',
      contextLength: 131072,
      inputCost: 0,
      outputCost: 0,
      isFree: true,
      modalities: ['text'],
      description: '경량화 추론 모델, 131K 컨텍스트',
    ),

    // Mistral (무료)
    ModelInfo(
      id: 'mistralai/mistral-small-3.2-24b:free',
      name: 'Mistral Small 3.2 24B (무료)',
      provider: 'Mistral AI',
      contextLength: 96000,
      inputCost: 0,
      outputCost: 0,
      isFree: true,
      modalities: ['text', 'image'],
      supportsFunctionCalling: true,
      description: '비전 + 함수 호출 지원',
    ),

    ModelInfo(
      id: 'mistralai/devstral-small:free',
      name: 'Devstral Small (무료)',
      provider: 'Mistral AI',
      contextLength: 32768,
      inputCost: 0,
      outputCost: 0,
      isFree: true,
      modalities: ['text'],
      supportsFunctionCalling: true,
      description: '코딩 특화 모델',
    ),

    // Google (무료)
    ModelInfo(
      id: 'google/gemma-3n-2b:free',
      name: 'Gemma 3n 2B (무료)',
      provider: 'Google',
      contextLength: 8192,
      inputCost: 0,
      outputCost: 0,
      isFree: true,
      modalities: ['text'],
      description: '경량 모델',
    ),

    ModelInfo(
      id: 'google/gemma-3n-4b:free',
      name: 'Gemma 3n 4B (무료)',
      provider: 'Google',
      contextLength: 8192,
      inputCost: 0,
      outputCost: 0,
      isFree: true,
      modalities: ['text'],
      description: '경량 모델',
    ),

    // Meta (무료)
    ModelInfo(
      id: 'meta-llama/llama-3.1-8b-instruct:free',
      name: 'Llama 3.1 8B (무료)',
      provider: 'Meta',
      contextLength: 131072,
      inputCost: 0,
      outputCost: 0,
      isFree: true,
      modalities: ['text'],
      description: '범용 모델, 131K 컨텍스트',
    ),

    // OpenRouter (무료)
    ModelInfo(
      id: 'openrouter/cypher-alpha:free',
      name: 'Cypher Alpha (무료)',
      provider: 'OpenRouter',
      contextLength: 1000000,
      inputCost: 0,
      outputCost: 0,
      isFree: true,
      modalities: ['text'],
      supportsFunctionCalling: true,
      description: '1M 컨텍스트, 함수 호출',
    ),

    // Kimi (무료)
    ModelInfo(
      id: 'moonshotai/kimi-dev-72b:free',
      name: 'Kimi Dev 72B (무료)',
      provider: 'Moonshot AI',
      contextLength: 131072,
      inputCost: 0,
      outputCost: 0,
      isFree: true,
      modalities: ['text'],
      description: '중국어 + 영어 특화',
    ),

    // === 유료 모델 (인기) ===

    // Claude
    ModelInfo(
      id: 'anthropic/claude-3.5-sonnet',
      name: 'Claude 3.5 Sonnet',
      provider: 'Anthropic',
      contextLength: 200000,
      inputCost: 3.0,
      outputCost: 15.0,
      isFree: false,
      modalities: ['text', 'image'],
      supportsFunctionCalling: true,
      description: '최고 성능, 비전 + 코딩 우수',
    ),

    ModelInfo(
      id: 'anthropic/claude-haiku-4.5',
      name: 'Claude Haiku 4.5',
      provider: 'Anthropic',
      contextLength: 200000,
      inputCost: 0.8,
      outputCost: 4.0,
      isFree: false,
      modalities: ['text', 'image'],
      description: '저비용 고속 모델',
    ),

    // GPT
    ModelInfo(
      id: 'openai/gpt-4o',
      name: 'GPT-4o',
      provider: 'OpenAI',
      contextLength: 128000,
      inputCost: 2.5,
      outputCost: 10.0,
      isFree: false,
      modalities: ['text', 'image'],
      supportsFunctionCalling: true,
      description: '멀티모달 GPT-4',
    ),

    ModelInfo(
      id: 'openai/gpt-4o-mini',
      name: 'GPT-4o Mini',
      provider: 'OpenAI',
      contextLength: 128000,
      inputCost: 0.15,
      outputCost: 0.6,
      isFree: false,
      modalities: ['text', 'image'],
      supportsFunctionCalling: true,
      description: '저비용 GPT-4',
    ),

    // Gemini
    ModelInfo(
      id: 'google/gemini-2.5-flash-preview',
      name: 'Gemini 2.5 Flash Preview',
      provider: 'Google',
      contextLength: 1000000,
      inputCost: 0.075,
      outputCost: 0.3,
      isFree: false,
      modalities: ['text', 'image'],
      description: '1M 컨텍스트, 고속',
    ),

    // DeepSeek (유료)
    ModelInfo(
      id: 'deepseek/deepseek-r1',
      name: 'DeepSeek R1',
      provider: 'DeepSeek',
      contextLength: 163840,
      inputCost: 0.55,
      outputCost: 2.19,
      isFree: false,
      modalities: ['text'],
      description: '추론 특화 (유료 버전)',
    ),
  ];

  /// 무료 모델만
  static List<ModelInfo> get free => all.where((m) => m.isFree).toList();

  /// 유료 모델만
  static List<ModelInfo> get paid => all.where((m) => !m.isFree).toList();

  /// ID로 모델 찾기
  static ModelInfo? findById(String id) {
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Provider로 필터링
  static List<ModelInfo> byProvider(String provider) {
    return all.where((m) => m.provider == provider).toList();
  }

  /// 가격 범위로 필터링 ($ per 1M tokens)
  static List<ModelInfo> byPriceRange(double maxInput, double maxOutput) {
    return all.where((m) =>
    m.inputCost <= maxInput && m.outputCost <= maxOutput
    ).toList();
  }
}
