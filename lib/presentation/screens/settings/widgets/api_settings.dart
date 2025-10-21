// lib/presentation/screens/settings/widgets/api_settings.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../domain/providers/settings_provider.dart';

class ApiSettings extends ConsumerStatefulWidget {
  const ApiSettings({super.key});

  @override
  ConsumerState<ApiSettings> createState() => _ApiSettingsState();
}

class _ApiSettingsState extends ConsumerState<ApiSettings> {
  final _apiKeyController = TextEditingController();
  bool _isObscured = true;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'API 설정',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: UIConstants.spacingMd),
        settingsAsync.when(
          data: (settings) {
            if (_apiKeyController.text.isEmpty && settings.apiKey.isNotEmpty) {
              _apiKeyController.text = settings.apiKey;
            }

            return Column(
              children: [
                TextFormField(
                  controller: _apiKeyController,
                  decoration: InputDecoration(
                    labelText: 'OpenRouter API Key',
                    hintText: 'sk-or-v1-...',
                    border: const OutlineInputBorder(),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(_isObscured
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _isObscured = !_isObscured;
                            });
                          },
                        ),
                        if (_apiKeyController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.save),
                            onPressed: () async {
                              await ref
                                  .read(settingsProvider.notifier)
                                  .updateApiKey(_apiKeyController.text.trim());
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('API 키가 저장되었습니다'),
                                  ),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                  obscureText: _isObscured,
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: UIConstants.spacingSm),
                Text(
                  'OpenRouter에서 발급받은 API 키를 입력하세요',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => Text(
            'API 설정을 불러올 수 없습니다: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }
}
