// lib/presentation/screens/settings/widgets/add_model_dialog.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/ui_constants.dart';
import 'model_selector_dialog.dart';

class AddModelDialog extends StatefulWidget {
  final Function(String modelId, String systemPrompt) onAdd;

  const AddModelDialog({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddModelDialog> createState() => _AddModelDialogState();
}

class _AddModelDialogState extends State<AddModelDialog> {
  String? _selectedModel;
  final _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      // ✅ 아이콘 추가
      icon: Container(
        padding: const EdgeInsets.all(UIConstants.spacingMd),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.add_circle_outline,
          size: UIConstants.iconLg * 1.5,
          color: colorScheme.primary,
        ),
      ),
      title: const Text('모델 추가'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ 모델 선택 섹션
            Row(
              children: [
                Icon(
                  Icons.smart_toy_outlined,
                  size: UIConstants.iconSm,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: UIConstants.spacingXs),
                Text(
                  '모델 선택',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.spacingSm),
            OutlinedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ModelSelectorDialog(
                    currentModel: _selectedModel,
                    onSelect: (modelId) {
                      setState(() {
                        _selectedModel = modelId;
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(UIConstants.spacingMd),
                alignment: Alignment.centerLeft,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _selectedModel ?? '모델을 선택하세요',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: _selectedModel != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: _selectedModel != null
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            const SizedBox(height: UIConstants.spacingMd),

            // ✅ 시스템 프롬프트 섹션
            Row(
              children: [
                Icon(
                  Icons.psychology_outlined,
                  size: UIConstants.iconSm,
                  color: colorScheme.secondary,
                ),
                const SizedBox(width: UIConstants.spacingXs),
                Text(
                  '시스템 프롬프트',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: UIConstants.spacingXs),
                Text(
                  '(선택사항)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.spacingSm),
            TextFormField(
              controller: _promptController,
              decoration: InputDecoration(
                hintText: '이 모델의 역할과 동작을 정의하세요...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UIConstants.radiusMd),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest
                    .withAlpha(UIConstants.alpha30),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton.icon(
          onPressed: _selectedModel == null
              ? null
              : () {
            widget.onAdd(_selectedModel!, _promptController.text);
          },
          icon: const Icon(Icons.add),
          label: const Text('추가'),
        ),
      ],
    );
  }
}
