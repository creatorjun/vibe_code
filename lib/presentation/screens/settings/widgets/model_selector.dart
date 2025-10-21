import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/providers/settings_provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/ui_constants.dart';

class ModelSelector extends ConsumerWidget {
  const ModelSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '모델 선택',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: UIConstants.spacingMd),

          DropdownButtonFormField<String>(
            initialValue: settings.selectedModel,
            decoration: const InputDecoration(
              labelText: 'AI 모델',
              helperText: '사용할 AI 모델을 선택하세요',
            ),
            items: ApiConstants.availableModels.map((model) {
              return DropdownMenuItem(
                value: model,
                child: Text(_getModelDisplayName(model)),
              );
            }).toList(),
            onChanged: (value) async {
              if (value != null) {
                await ref.read(settingsProvider.notifier).updateModel(value);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('모델이 ${_getModelDisplayName(value)}(으)로 변경되었습니다'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('설정을 불러올 수 없습니다: $error'),
      ),
    );
  }

  String _getModelDisplayName(String model) {
    final parts = model.split('/');
    if (parts.length == 2) {
      return '${parts[0]} - ${parts[1]}';
    }
    return model;
  }
}
