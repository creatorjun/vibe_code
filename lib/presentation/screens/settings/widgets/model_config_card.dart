// lib/presentation/screens/settings/widgets/model_config_card.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../data/models/settings_state.dart';
import 'model_selector_dialog.dart';

class ModelConfigCard extends StatefulWidget {
  final ModelConfig config;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onToggle;
  final Function(String) onUpdateModel;
  final Function(String) onUpdatePrompt;

  const ModelConfigCard({
    super.key,
    required this.config,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    required this.onToggle,
    required this.onUpdateModel,
    required this.onUpdatePrompt,
  });

  @override
  State<ModelConfigCard> createState() => _ModelConfigCardState();
}

class _ModelConfigCardState extends State<ModelConfigCard> {
  late TextEditingController _promptController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.config.systemPrompt);
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: UIConstants.spacingMd),
      child: Column(
        children: [
          ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReorderableDragStartListener(
                  index: widget.index,
                  child: const Icon(Icons.drag_handle),
                ),
                const SizedBox(width: UIConstants.spacingSm),
                Checkbox(
                  value: widget.config.isEnabled,
                  onChanged: (_) => widget.onToggle(),
                ),
              ],
            ),
            title: Text(
              '${widget.index + 1}. ${_getModelDisplayName(widget.config.modelId)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.config.isEnabled
                    ? null
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            subtitle: Text(
              widget.config.modelId,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showModelSelector(context),
                  tooltip: '모델 변경',
                ),
                IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  tooltip: '시스템 프롬프트',
                ),
                if (widget.canRemove)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: widget.onRemove,
                    color: Theme.of(context).colorScheme.error,
                    tooltip: '모델 제거',
                  ),
              ],
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                UIConstants.spacingLg,
                0,
                UIConstants.spacingLg,
                UIConstants.spacingMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '시스템 프롬프트',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: UIConstants.spacingSm),
                  TextFormField(
                    controller: _promptController,
                    decoration: InputDecoration(
                      hintText: '이 모델의 역할과 동작을 정의하세요...',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: () {
                          widget.onUpdatePrompt(_promptController.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('시스템 프롬프트가 저장되었습니다'),
                            ),
                          );
                        },
                      ),
                    ),
                    maxLines: 5,
                    enabled: widget.config.isEnabled,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getModelDisplayName(String modelId) {
    final parts = modelId.split('/');
    if (parts.length > 1) {
      return parts[1];
    }
    return modelId;
  }

  void _showModelSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ModelSelectorDialog(
        currentModel: widget.config.modelId,
        onSelect: (modelId) {
          widget.onUpdateModel(modelId);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('모델이 변경되었습니다: $modelId')),
          );
        },
      ),
    );
  }
}
