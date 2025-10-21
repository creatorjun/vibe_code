// lib/presentation/screens/settings/widgets/model_selector_dialog.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/ui_constants.dart';

class ModelSelectorDialog extends StatefulWidget {
  final String? currentModel;
  final Function(String) onSelect;

  const ModelSelectorDialog({
    super.key,
    this.currentModel,
    required this.onSelect,
  });

  @override
  State<ModelSelectorDialog> createState() => _ModelSelectorDialogState();
}

class _ModelSelectorDialogState extends State<ModelSelectorDialog> {
  String? _selectedCategory;
  String _searchQuery = '';

  // 주요 AI 모델 목록 (무료 모델 포함)
  static const Map<String, List<Map<String, String>>> modelCategories = {
    '🆓 무료 모델': [
      {
        'id': 'deepseek/deepseek-r1:free',
        'name': 'DeepSeek R1 (무료)',
        'description': '강력한 추론 능력, 무제한 무료',
      },
      {
        'id': 'deepseek/deepseek-chat:free',
        'name': 'DeepSeek Chat (무료)',
        'description': '일반 채팅용 무료 모델',
      },
      {
        'id': 'meta-llama/llama-3.2-3b-instruct:free',
        'name': 'Llama 3.2 3B (무료)',
        'description': 'Meta의 소형 무료 모델',
      },
      {
        'id': 'meta-llama/llama-3.1-8b-instruct:free',
        'name': 'Llama 3.1 8B (무료)',
        'description': 'Meta의 중형 무료 모델',
      },
      {
        'id': 'google/gemini-flash-1.5:free',
        'name': 'Gemini Flash 1.5 (무료)',
        'description': '빠른 응답, 무료 사용',
      },
      {
        'id': 'google/gemini-pro-1.5:free',
        'name': 'Gemini Pro 1.5 (무료)',
        'description': '대용량 컨텍스트, 무료',
      },
      {
        'id': 'mistralai/mistral-7b-instruct:free',
        'name': 'Mistral 7B (무료)',
        'description': 'Mistral AI 무료 모델',
      },
      {
        'id': 'nousresearch/hermes-3-llama-3.1-405b:free',
        'name': 'Hermes 3 405B (무료)',
        'description': '최대 규모 무료 모델',
      },
      {
        'id': 'qwen/qwen-2.5-7b-instruct:free',
        'name': 'Qwen 2.5 7B (무료)',
        'description': 'Alibaba 무료 모델',
      },
      {
        'id': 'microsoft/phi-3-medium-128k-instruct:free',
        'name': 'Phi-3 Medium (무료)',
        'description': 'Microsoft 소형 무료 모델',
      },
    ],
    'Anthropic': [
      {
        'id': 'anthropic/claude-3.5-sonnet',
        'name': 'Claude 3.5 Sonnet',
        'description': '최고 성능의 Claude 모델',
      },
      {
        'id': 'anthropic/claude-3-opus',
        'name': 'Claude 3 Opus',
        'description': '강력한 추론 능력',
      },
      {
        'id': 'anthropic/claude-3-sonnet',
        'name': 'Claude 3 Sonnet',
        'description': '균형잡힌 성능',
      },
      {
        'id': 'anthropic/claude-3-haiku',
        'name': 'Claude 3 Haiku',
        'description': '빠른 응답 속도',
      },
    ],
    'OpenAI': [
      {
        'id': 'openai/gpt-4-turbo',
        'name': 'GPT-4 Turbo',
        'description': '최신 GPT-4 모델',
      },
      {
        'id': 'openai/gpt-4',
        'name': 'GPT-4',
        'description': '강력한 범용 모델',
      },
      {
        'id': 'openai/gpt-3.5-turbo',
        'name': 'GPT-3.5 Turbo',
        'description': '빠르고 경제적',
      },
      {
        'id': 'openai/gpt-4o-mini',
        'name': 'GPT-4o Mini',
        'description': '소형 고성능 모델',
      },
    ],
    'Google': [
      {
        'id': 'google/gemini-pro-1.5',
        'name': 'Gemini Pro 1.5',
        'description': '대용량 컨텍스트 지원',
      },
      {
        'id': 'google/gemini-pro',
        'name': 'Gemini Pro',
        'description': '다목적 AI 모델',
      },
      {
        'id': 'google/gemini-flash-1.5',
        'name': 'Gemini Flash 1.5',
        'description': '빠른 응답 속도',
      },
    ],
    'Meta': [
      {
        'id': 'meta-llama/llama-3.1-405b-instruct',
        'name': 'Llama 3.1 405B',
        'description': '오픈소스 최대 모델',
      },
      {
        'id': 'meta-llama/llama-3.1-70b-instruct',
        'name': 'Llama 3.1 70B',
        'description': '균형잡힌 오픈소스',
      },
      {
        'id': 'meta-llama/llama-3.2-11b-vision-instruct',
        'name': 'Llama 3.2 11B Vision',
        'description': '비전 기능 포함',
      },
    ],
    'Mistral': [
      {
        'id': 'mistralai/mistral-large',
        'name': 'Mistral Large',
        'description': '유럽산 고성능 모델',
      },
      {
        'id': 'mistralai/mistral-medium',
        'name': 'Mistral Medium',
        'description': '중간 크기 모델',
      },
      {
        'id': 'mistralai/mistral-small',
        'name': 'Mistral Small',
        'description': '소형 경량 모델',
      },
    ],
    'DeepSeek': [
      {
        'id': 'deepseek/deepseek-chat',
        'name': 'DeepSeek Chat',
        'description': '범용 채팅 모델',
      },
      {
        'id': 'deepseek/deepseek-coder',
        'name': 'DeepSeek Coder',
        'description': '코딩 전문 모델',
      },
      {
        'id': 'deepseek/deepseek-r1',
        'name': 'DeepSeek R1',
        'description': '고급 추론 모델',
      },
    ],
  };

  List<Map<String, String>> get filteredModels {
    List<Map<String, String>> allModels = [];

    if (_selectedCategory != null) {
      allModels = modelCategories[_selectedCategory] ?? [];
    } else {
      modelCategories.forEach((category, models) {
        allModels.addAll(models);
      });
    }

    if (_searchQuery.isEmpty) {
      return allModels;
    }

    return allModels.where((model) {
      final query = _searchQuery.toLowerCase();
      return model['name']!.toLowerCase().contains(query) ||
          model['id']!.toLowerCase().contains(query) ||
          model['description']!.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final models = filteredModels;

    return Dialog(
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(UIConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                const Icon(Icons.model_training, size: 28),
                const SizedBox(width: UIConstants.spacingSm),
                Text(
                  '모델 선택',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.spacingLg),

            // 검색창
            TextField(
              decoration: const InputDecoration(
                hintText: '모델 검색...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: UIConstants.spacingMd),

            // 카테고리 필터
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  FilterChip(
                    label: const Text('전체'),
                    selected: _selectedCategory == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = null;
                      });
                    },
                  ),
                  const SizedBox(width: UIConstants.spacingSm),
                  ...modelCategories.keys.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        right: UIConstants.spacingSm,
                      ),
                      child: FilterChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? category : null;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: UIConstants.spacingMd),

            // 모델 개수 표시
            Text(
              '${models.length}개의 모델',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(153),
              ),
            ),
            const SizedBox(height: UIConstants.spacingSm),

            // 모델 리스트
            Expanded(
              child: models.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(153),
                    ),
                    const SizedBox(height: UIConstants.spacingMd),
                    Text(
                      '검색 결과가 없습니다',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: models.length,
                itemBuilder: (context, index) {
                  final model = models[index];
                  final isSelected =
                      model['id'] == widget.currentModel;
                  final isFree = model['id']!.endsWith(':free');

                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: UIConstants.spacingSm,
                    ),
                    child: ListTile(
                      leading: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              model['name']!,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isFree)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'FREE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(model['description']!),
                          const SizedBox(height: 4),
                          Text(
                            model['id']!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              fontFamily: 'monospace',
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(153),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        widget.onSelect(model['id']!);
                      },
                      selected: isSelected,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
