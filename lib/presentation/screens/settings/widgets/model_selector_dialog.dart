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
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusLg),
      ),
      child: Container(
        width: 650,
        height: 700,
        padding: const EdgeInsets.all(UIConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ 헤더 개선
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(UIConstants.spacingSm),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(UIConstants.radiusMd),
                  ),
                  child: Icon(
                    Icons.model_training,
                    size: UIConstants.iconLg,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: UIConstants.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '모델 선택',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${models.length}개의 모델',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.spacingLg),

            // ✅ 검색창 개선
            TextField(
              decoration: InputDecoration(
                hintText: '모델 이름, ID, 설명으로 검색...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UIConstants.radiusMd),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withAlpha(UIConstants.alpha30),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: UIConstants.spacingMd),

            // ✅ 카테고리 필터 개선
            SizedBox(
              height: 42,
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
                    showCheckmark: false,
                  ),
                  const SizedBox(width: UIConstants.spacingSm),
                  ...modelCategories.keys.map((category) {
                    final count = modelCategories[category]!.length;
                    return Padding(
                      padding: const EdgeInsets.only(right: UIConstants.spacingSm),
                      child: FilterChip(
                        label: Text('$category ($count)'),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? category : null;
                          });
                        },
                        showCheckmark: false,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: UIConstants.spacingMd),

            // ✅ 모델 리스트
            Expanded(
              child: models.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: colorScheme.onSurface.withAlpha(102),
                    ),
                    const SizedBox(height: UIConstants.spacingMd),
                    Text(
                      '검색 결과가 없습니다',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: UIConstants.spacingSm),
                    Text(
                      '다른 검색어를 입력하거나 필터를 변경해보세요',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withAlpha(153),
                      ),
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
                    margin: const EdgeInsets.only(bottom: UIConstants.spacingSm),
                    elevation: isSelected ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(UIConstants.radiusMd),
                      side: BorderSide(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? colorScheme.primary : null,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              model.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
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
                          if (model.description != null) ...[
                            const SizedBox(height: 4),
                            Text(model.description!),
                          ],
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              // 가격 칩
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: model.isFree
                                      ? Colors.green.withAlpha(51)
                                      : colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  model.priceDisplay,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: model.isFree
                                        ? Colors.green.shade700
                                        : colorScheme.primary,
                                  ),
                                ),
                              ),
                              // 컨텍스트 칩
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '📄 ${model.contextDisplay}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            model.id,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              color: colorScheme.onSurface.withAlpha(128),
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

            // ✅ 하단 정보 개선
            Container(
              margin: const EdgeInsets.only(top: UIConstants.spacingMd),
              padding: const EdgeInsets.all(UIConstants.spacingMd),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(UIConstants.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(width: UIConstants.spacingSm),
                  Expanded(
                    child: Text(
                      '가격: 입력 / 출력 (per 1M tokens)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withAlpha(153),
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
