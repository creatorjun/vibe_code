// lib/data/models/model_info.dart

/// OpenRouter 모델 정보
class ModelInfo {
  final String id;
  final String name;
  final String provider;
  final int contextLength;
  final double inputCost; // per 1M tokens
  final double outputCost; // per 1M tokens
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

  String get priceDisplay {
    if (isFree) return '무료';
    return '\$${inputCost.toStringAsFixed(2)}/\$${outputCost.toStringAsFixed(2)}';
  }

  String get contextDisplay {
    if (contextLength >= 1000000) {
      return '${(contextLength / 1000000).toStringAsFixed(1)}M';
    } else if (contextLength >= 1000) {
      return '${(contextLength / 1000).toStringAsFixed(0)}K';
    }
    return '$contextLength';
  }
}

/// OpenRouter 실제 서비스 중인 모델 리스트 (2025년 10월 27일 기준)
class AvailableModels {
  static const List<ModelInfo> all = [
    // ============================================================================
    // 무료 모델 (10개)
    // ============================================================================

    // 1. Andromeda Alpha (128K 컨텍스트)
    ModelInfo(
      id: 'openrouter/andromeda-alpha',
      name: 'Andromeda Alpha',
      provider: 'OpenRouter',
      contextLength: 128000,
      inputCost: 0,
      outputCost: 0,
      isFree: true,
      modalities: ['text'],
      description: '128K 컨텍스트, 무료',
    ),

    // 2. MiniMax M2 (204K 컨텍스트)
    ModelInfo(
      id: 'minimax/minimax-m2:free',
      name: 'MiniMax M2',
      provider: 'MiniMax',
      contextLength: 204800,
      inputCost: 0,
      outputCost: 0,
      isFree: true,
      modalities: ['text'],
      description: '204K 컨텍스트',
    ),

    // 3. Tongyi DeepResearch 30B A3B
    ModelInfo(
      id: 'alibaba/tongyi-deepresearch-30b-a3b:free',
      name: 'Tongyi DeepResearch 30B',
      provider: 'Alibaba',
      contextLength: 131072,
      inputCost: 0,
      outputCost: 0,
      isFree: true,
      modalities: ['text'],
      description: '131K 컨텍스트',
    ),

    // 4. Meituan LongCat Flash Chat
    ModelInfo(
      id: 'meituan/longcat-flash-chat:free',
      name: 'LongCat Flash Chat',
      provider: 'Meituan',
      contextLength: 131072,
      inputCost: 0,
      outputCost: 0,
      isFree: true,
      modalities: ['text'],
      description: '131K 컨텍스트',
    ),

    // 5. NVIDIA Nemotron Nano 9B V2
    ModelInfo(
      id: 'nvidia/nemotron-nano-9b-v2:free',
      name: 'Nemotron Nano 9B V2',
      provider: 'NVIDIA',
      contextLength: 128000,
      inputCost: 0,
      outputCost: 0,
      isFree: true,
      modalities: ['text'],
      description: '128K 컨텍스트',
    ),

    // 6. DeepSeek V3.1
    ModelInfo(
      id: 'deepseek/deepseek-chat-v3.1:free',
      name: 'DeepSeek V3.1',
      provider: 'DeepSeek',
      contextLength: 163800,
      inputCost: 0,
      outputCost: 0,
      isFree: true,
      modalities: ['text'],
      description: '164K 컨텍스트',
    ),

    // 7. DeepSeek R1
    ModelInfo(
      id: 'deepseek/deepseek-r1:free',
      name: 'DeepSeek R1',
      provider: 'DeepSeek',
      contextLength: 163840,
      inputCost: 0,
      outputCost: 0,
      isFree: true,
      modalities: ['text'],
      description: '164K 컨텍스트, 추론 모델',
    ),

    // 8. Google Gemini 2.0 Flash Experimental
    ModelInfo(
      id: 'google/gemini-2.0-flash-exp:free',
      name: 'Gemini 2.0 Flash Exp',
      provider: 'Google',
      contextLength: 1048576,
      inputCost: 0,
      outputCost: 0,
      isFree: true,
      modalities: ['text', 'image'],
      supportsFunctionCalling: true,
      description: '1M 컨텍스트, 멀티모달',
    ),

    // 9. Meta Llama 3.3 70B Instruct
    ModelInfo(
      id: 'meta-llama/llama-3.3-70b-instruct:free',
      name: 'Llama 3.3 70B',
      provider: 'Meta',
      contextLength: 131072,
      inputCost: 0,
      outputCost: 0,
      isFree: true,
      modalities: ['text'],
      description: '131K 컨텍스트',
    ),

    // 10. Mistral Small 3.2 24B
    ModelInfo(
      id: 'mistralai/mistral-small-3.2-24b-instruct:free',
      name: 'Mistral Small 3.2 24B',
      provider: 'Mistral AI',
      contextLength: 131072,
      inputCost: 0,
      outputCost: 0,
      isFree: true,
      modalities: ['text', 'image'],
      supportsFunctionCalling: true,
      description: '131K 컨텍스트, 비전 지원',
    ),

    // ============================================================================
    // 가성비 모델 (10개) - $1 이하 입력, $5 이하 출력
    // ============================================================================

    // 1. Baidu ERNIE 4.5 21B A3B (가장 저렴)
    ModelInfo(
      id: 'baidu/ernie-4.5-21b-a3b',
      name: 'ERNIE 4.5 21B',
      provider: 'Baidu',
      contextLength: 120000,
      inputCost: 0.07,
      outputCost: 0.28,
      isFree: false,
      modalities: ['text'],
      description: '120K 컨텍스트, 초저가',
    ),

    // 2. Qwen3 VL 8B Instruct (비전 가성비)
    ModelInfo(
      id: 'qwen/qwen3-vl-8b-instruct',
      name: 'Qwen3 VL 8B',
      provider: 'Qwen',
      contextLength: 131072,
      inputCost: 0.08,
      outputCost: 0.50,
      isFree: false,
      modalities: ['text', 'image'],
      description: '131K 컨텍스트, 비전',
    ),

    // 3. Google Gemini 2.5 Flash Lite
    ModelInfo(
      id: 'google/gemini-2.5-flash-lite',
      name: 'Gemini 2.5 Flash Lite',
      provider: 'Google',
      contextLength: 1048576,
      inputCost: 0.10,
      outputCost: 0.40,
      isFree: false,
      modalities: ['text', 'image'],
      supportsFunctionCalling: true,
      description: '1M 컨텍스트, 초저가',
    ),

    // 4. NVIDIA Llama 3.3 Nemotron Super 49B
    ModelInfo(
      id: 'nvidia/llama-3.3-nemotron-super-49b-v1.5',
      name: 'Nemotron Super 49B',
      provider: 'NVIDIA',
      contextLength: 131072,
      inputCost: 0.10,
      outputCost: 0.40,
      isFree: false,
      modalities: ['text'],
      description: '131K 컨텍스트',
    ),

    // 5. OpenAI GPT-4o Mini
    ModelInfo(
      id: 'openai/gpt-4o-mini',
      name: 'GPT-4o Mini',
      provider: 'OpenAI',
      contextLength: 128000,
      inputCost: 0.15,
      outputCost: 0.60,
      isFree: false,
      modalities: ['text', 'image'],
      supportsFunctionCalling: true,
      description: '128K 컨텍스트',
    ),

    // 6. xAI Grok 4 Fast
    ModelInfo(
      id: 'x-ai/grok-4-fast',
      name: 'Grok 4 Fast',
      provider: 'xAI',
      contextLength: 2000000,
      inputCost: 0.20,
      outputCost: 0.50,
      isFree: false,
      modalities: ['text'],
      description: '2M 컨텍스트, 초고속',
    ),

    // 7. DeepSeek V3.2 Exp
    ModelInfo(
      id: 'deepseek/deepseek-v3.2-exp',
      name: 'DeepSeek V3.2 Exp',
      provider: 'DeepSeek',
      contextLength: 163840,
      inputCost: 0.27,
      outputCost: 0.40,
      isFree: false,
      modalities: ['text'],
      description: '164K 컨텍스트',
    ),

    // 8. Google Gemini 2.5 Flash
    ModelInfo(
      id: 'google/gemini-2.5-flash',
      name: 'Gemini 2.5 Flash',
      provider: 'Google',
      contextLength: 1048576,
      inputCost: 0.30,
      outputCost: 2.50,
      isFree: false,
      modalities: ['text', 'image'],
      supportsFunctionCalling: true,
      description: '1M 컨텍스트',
    ),

    // 9. DeepSeek R1
    ModelInfo(
      id: 'deepseek/deepseek-r1',
      name: 'DeepSeek R1',
      provider: 'DeepSeek',
      contextLength: 163840,
      inputCost: 0.40,
      outputCost: 2.0,
      isFree: false,
      modalities: ['text'],
      description: '164K 컨텍스트, 추론 모델',
    ),

    // 10. Anthropic Claude Haiku 4.5
    ModelInfo(
      id: 'anthropic/claude-haiku-4.5',
      name: 'Claude Haiku 4.5',
      provider: 'Anthropic',
      contextLength: 200000,
      inputCost: 1.0,
      outputCost: 5.0,
      isFree: false,
      modalities: ['text', 'image'],
      supportsFunctionCalling: true,
      description: '200K 컨텍스트, 빠르고 저렴',
    ),

    // ============================================================================
    // 최고 성능 모델 (10개)
    // ============================================================================

    // 1. Anthropic Claude Sonnet 4.5 (1위)
    ModelInfo(
      id: 'anthropic/claude-sonnet-4.5',
      name: 'Claude Sonnet 4.5',
      provider: 'Anthropic',
      contextLength: 1000000,
      inputCost: 3.0,
      outputCost: 15.0,
      isFree: false,
      modalities: ['text', 'image'],
      supportsFunctionCalling: true,
      description: '1M 컨텍스트, 최고 품질',
    ),

    // 2. Anthropic Claude Opus 4.1
    ModelInfo(
      id: 'anthropic/claude-opus-4.1',
      name: 'Claude Opus 4.1',
      provider: 'Anthropic',
      contextLength: 200000,
      inputCost: 15.0,
      outputCost: 75.0,
      isFree: false,
      modalities: ['text', 'image'],
      supportsFunctionCalling: true,
      description: '최고 품질, 최강 성능',
    ),

    // 3. OpenAI GPT-5
    ModelInfo(
      id: 'openai/gpt-5',
      name: 'GPT-5',
      provider: 'OpenAI',
      contextLength: 400000,
      inputCost: 1.25,
      outputCost: 10.0,
      isFree: false,
      modalities: ['text', 'image'],
      supportsFunctionCalling: true,
      description: '400K 컨텍스트, 차세대',
    ),

    // 4. OpenAI GPT-5 Pro
    ModelInfo(
      id: 'openai/gpt-5-pro',
      name: 'GPT-5 Pro',
      provider: 'OpenAI',
      contextLength: 400000,
      inputCost: 15.0,
      outputCost: 120.0,
      isFree: false,
      modalities: ['text', 'image'],
      supportsFunctionCalling: true,
      description: '400K 컨텍스트, 프로급',
    ),

    // 5. OpenAI o3 Pro
    ModelInfo(
      id: 'openai/o3-pro',
      name: 'O3 Pro',
      provider: 'OpenAI',
      contextLength: 200000,
      inputCost: 20.0,
      outputCost: 80.0,
      isFree: false,
      modalities: ['text'],
      description: '200K 컨텍스트, 추론 최강',
    ),

    // 6. xAI Grok 4
    ModelInfo(
      id: 'x-ai/grok-4',
      name: 'Grok 4',
      provider: 'xAI',
      contextLength: 256000,
      inputCost: 3.0,
      outputCost: 15.0,
      isFree: false,
      modalities: ['text'],
      description: '256K 컨텍스트',
    ),

    // 7. Google Gemini 2.5 Pro
    ModelInfo(
      id: 'google/gemini-2.5-pro',
      name: 'Gemini 2.5 Pro',
      provider: 'Google',
      contextLength: 1048576,
      inputCost: 1.25,
      outputCost: 10.0,
      isFree: false,
      modalities: ['text', 'image'],
      supportsFunctionCalling: true,
      description: '1M 컨텍스트',
    ),

    // 8. OpenAI GPT-4o
    ModelInfo(
      id: 'openai/gpt-4o',
      name: 'GPT-4o',
      provider: 'OpenAI',
      contextLength: 128000,
      inputCost: 2.50,
      outputCost: 10.0,
      isFree: false,
      modalities: ['text', 'image'],
      supportsFunctionCalling: true,
      description: '128K 컨텍스트',
    ),

    // 9. Qwen3 Max
    ModelInfo(
      id: 'qwen/qwen3-max',
      name: 'Qwen3 Max',
      provider: 'Qwen',
      contextLength: 256000,
      inputCost: 1.20,
      outputCost: 6.0,
      isFree: false,
      modalities: ['text'],
      supportsFunctionCalling: true,
      description: '256K 컨텍스트',
    ),

    // 10. OpenAI o3 Mini High
    ModelInfo(
      id: 'openai/o3-mini-high',
      name: 'O3 Mini High',
      provider: 'OpenAI',
      contextLength: 200000,
      inputCost: 1.10,
      outputCost: 4.40,
      isFree: false,
      modalities: ['text'],
      description: '200K 컨텍스트, 추론',
    ),
  ];

  // 헬퍼 메서드
  static List<ModelInfo> get free => all.where((m) => m.isFree).toList();
  static List<ModelInfo> get paid => all.where((m) => !m.isFree).toList();

  // ID로 모델 찾기
  static ModelInfo? findById(String id) {
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  // Provider별 필터
  static List<ModelInfo> byProvider(String provider) {
    return all.where((m) => m.provider == provider).toList();
  }

  // 가성비 모델 (무료 제외, 입력 $1 이하, 출력 $5 이하)
  static List<ModelInfo> get valueTier {
    return paid
        .where((m) => m.inputCost <= 1.0 && m.outputCost <= 5.0)
        .toList();
  }

  // 프리미엄 모델
  static List<ModelInfo> get premiumTier {
    return paid
        .where((m) => m.inputCost > 1.0 || m.outputCost > 5.0)
        .toList();
  }
}
