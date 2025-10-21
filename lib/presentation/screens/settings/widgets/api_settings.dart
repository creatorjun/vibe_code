import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/providers/settings_provider.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/utils/validators.dart';

class ApiSettings extends ConsumerStatefulWidget {
  const ApiSettings({super.key});

  @override
  ConsumerState<ApiSettings> createState() => _ApiSettingsState();
}

class _ApiSettingsState extends ConsumerState<ApiSettings> {
  late final TextEditingController _apiKeyController;
  late final TextEditingController _systemPromptController;
  bool _isApiKeyVisible = false;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _systemPromptController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settingsAsync = ref.read(settingsProvider);
    settingsAsync.whenData((settings) {
      _apiKeyController.text = settings.apiKey;
      _systemPromptController.text = settings.systemPrompt;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'API 설정',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: UIConstants.spacingMd),

          // API 키
          TextField(
            controller: _apiKeyController,
            obscureText: !_isApiKeyVisible,
            decoration: InputDecoration(
              labelText: 'OpenRouter API 키',
              hintText: 'sk-or-v1-...',
              helperText: 'OpenRouter 계정에서 발급받은 API 키를 입력하세요',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _isApiKeyVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    tooltip: _isApiKeyVisible ? 'API 키 숨기기' : 'API 키 보기',
                    onPressed: () {
                      setState(() {
                        _isApiKeyVisible = !_isApiKeyVisible;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.save),
                    tooltip: 'API 키 저장',
                    onPressed: () => _saveApiKey(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: UIConstants.spacingLg),

          // 시스템 프롬프트
          Text(
            '시스템 프롬프트',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: UIConstants.spacingSm),
          TextField(
            controller: _systemPromptController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'AI의 역할과 행동 방식을 정의하세요...',
              helperText: '시스템 프롬프트는 모든 대화의 시작 부분에 포함됩니다',
              suffixIcon: IconButton(
                icon: const Icon(Icons.save),
                tooltip: '시스템 프롬프트 저장',
                onPressed: () => _saveSystemPrompt(),
              ),
            ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('설정을 불러올 수 없습니다: $error'),
      ),
    );
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();

    if (!Validators.isValidApiKey(apiKey)) {
      _showSnackBar('유효하지 않은 API 키입니다', isError: true);
      return;
    }

    await ref.read(settingsProvider.notifier).updateApiKey(apiKey);
    _showSnackBar('API 키가 저장되었습니다');
  }

  Future<void> _saveSystemPrompt() async {
    final prompt = _systemPromptController.text.trim();
    await ref.read(settingsProvider.notifier).updateSystemPrompt(prompt);
    _showSnackBar('시스템 프롬프트가 저장되었습니다');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
