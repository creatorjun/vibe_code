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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: UIConstants.spacingMd),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusMd),
        side: BorderSide(
          color: widget.config.isEnabled
              ? colorScheme.primary.withAlpha(UIConstants.alpha30)
              : colorScheme.outlineVariant.withAlpha(UIConstants.alpha60),
          width: widget.config.isEnabled ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            // ✅ Leading 영역 개선
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 드래그 핸들
                Container(
                  padding: const EdgeInsets.all(UIConstants.spacingXs),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(UIConstants.radiusSm),
                  ),
                  child: ReorderableDragStartListener(
                    index: widget.index,
                    child: Icon(
                      Icons.drag_handle,
                      size: UIConstants.iconMd,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: UIConstants.spacingSm),
                // 체크박스
                Checkbox(
                  value: widget.config.isEnabled,
                  onChanged: (_) => widget.onToggle(),
                ),
              ],
            ),
            // ✅ 타이틀 개선
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UIConstants.spacingSm,
                    vertical: UIConstants.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: widget.config.isEnabled
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(UIConstants.radiusSm),
                  ),
                  child: Text(
                    '${widget.index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.config.isEnabled
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: UIConstants.spacingSm),
                Expanded(
                  child: Text(
                    _getModelDisplayName(widget.config.modelId),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: widget.config.isEnabled
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withAlpha(UIConstants.alpha50),
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: UIConstants.spacingXs),
              child: Text(
                widget.config.modelId,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            // ✅ Trailing 버튼 개선
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showModelSelector(context),
                  tooltip: '모델 변경',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  tooltip: '시스템 프롬프트',
                  visualDensity: VisualDensity.compact,
                ),
                if (widget.canRemove)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: widget.onRemove,
                    color: colorScheme.error,
                    tooltip: '모델 제거',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          // ✅ 확장 영역 개선
          if (_isExpanded)
            Container(
              margin: const EdgeInsets.fromLTRB(
                UIConstants.spacingMd,
                0,
                UIConstants.spacingMd,
                UIConstants.spacingMd,
              ),
              padding: const EdgeInsets.all(UIConstants.spacingMd),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest
                    .withAlpha(UIConstants.alpha30),
                borderRadius: BorderRadius.circular(UIConstants.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology_outlined,
                        size: UIConstants.iconSm,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: UIConstants.spacingXs),
                      Text(
                        '시스템 프롬프트',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
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
                      fillColor: colorScheme.surface,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: () {
                          widget.onUpdatePrompt(_promptController.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: UIConstants.spacingSm),
                                  Text('시스템 프롬프트가 저장되었습니다'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(UIConstants.radiusMd),
                              ),
                            ),
                          );
                        },
                        tooltip: '저장',
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
            SnackBar(
              content: Text('모델이 변경되었습니다: $modelId'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}
