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
  String _searchQuery = '';
  String? _selectedCategory;

  // 주요 AI 모델 목록
  static const Map<String, List<Map<String, String>>> modelCategories = {
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
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
                      padding: const EdgeInsets.only(right: UIConstants.spacingSm),
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

            // 모델 목록
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
                          .withValues(alpha: 0.5),
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
                  final isSelected = model['id'] == widget.currentModel;

                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: UIConstants.spacingSm,
                    ),
                    color: isSelected
                        ? Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        : null,
                    child: ListTile(
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(
                        model['name']!,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model['id']!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            model['description']!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => widget.onSelect(model['id']!),
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
