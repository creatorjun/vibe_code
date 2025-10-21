// lib/presentation/screens/settings/widgets/model_selector_dialog.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../data/models/model_info.dart';

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

  // ✅ AvailableModels 사용
  static final Map<String, List<ModelInfo>> modelCategories = {
    '🆓 무료 모델': AvailableModels.free,
    'Anthropic': AvailableModels.byProvider('Anthropic'),
    'OpenAI': AvailableModels.byProvider('OpenAI'),
    'Google': AvailableModels.byProvider('Google'),
    'Meta': AvailableModels.byProvider('Meta'),
    'Mistral': AvailableModels.byProvider('Mistral AI'),
    'DeepSeek': AvailableModels.byProvider('DeepSeek'),
  };

  List<ModelInfo> get filteredModels {
    List<ModelInfo> allModels = [];

    if (_selectedCategory != null) {
      allModels = modelCategories[_selectedCategory] ?? [];
    } else {
      allModels = AvailableModels.all;
    }

    if (_searchQuery.isEmpty) {
      return allModels;
    }

    return allModels.where((model) {
      final query = _searchQuery.toLowerCase();
      return model.name.toLowerCase().contains(query) ||
          model.id.toLowerCase().contains(query) ||
          (model.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final models = filteredModels;

    return Dialog(
      child: Container(
        width: 650,
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
                  final isSelected = model.id == widget.currentModel;

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
                              model.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (model.isFree)
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
                          if (model.description != null)
                            Text(model.description!),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              // 가격 표시
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: model.isFree
                                      ? Colors.green.withAlpha(51)
                                      : Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  model.priceDisplay,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: model.isFree
                                        ? Colors.green.shade700
                                        : Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 컨텍스트 길이
                              Text(
                                '📄 ${model.contextDisplay}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(153),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            model.id,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(128),
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () {
                        widget.onSelect(model.id);
                      },
                      selected: isSelected,
                    ),
                  );
                },
              ),
            ),

            // 하단 설명
            Container(
              padding: const EdgeInsets.all(UIConstants.spacingSm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color:
                    Theme.of(context).colorScheme.onSurface.withAlpha(153),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '가격: 입력 / 출력 (per 1M tokens)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(153),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
