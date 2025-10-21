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
    return AlertDialog(
      title: const Text('모델 추가'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '모델 선택',
              style: Theme.of(context).textTheme.titleSmall,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _selectedModel ?? '모델을 선택하세요',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            const SizedBox(height: UIConstants.spacingMd),
            Text(
              '시스템 프롬프트 (선택사항)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: UIConstants.spacingSm),
            TextFormField(
              controller: _promptController,
              decoration: const InputDecoration(
                hintText: '이 모델의 역할과 동작을 정의하세요...',
                border: OutlineInputBorder(),
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
        FilledButton(
          onPressed: _selectedModel == null
              ? null
              : () {
            widget.onAdd(_selectedModel!, _promptController.text);
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}
