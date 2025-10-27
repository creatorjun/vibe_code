// lib/presentation/screens/settings/widgets/api_settings.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibe_code/core/constants/ui_constants.dart';
import 'package:vibe_code/domain/providers/settings_provider.dart';

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

  /// OpenRouter API 키 발급 페이지 열기
  Future<void> _launchApiKeyPage() async {
    final uri = Uri.parse('https://openrouter.ai/keys');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          _showErrorSnackBar('링크를 열 수 없습니다');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('링크 열기 실패: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ 섹션 헤더 (현대적 디자인)
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(UIConstants.spacingXs),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(UIConstants.radiusSm),
              ),
              child: const Icon(
                Icons.key_outlined,
                size: UIConstants.iconMd,
              ),
            ),
            const SizedBox(width: UIConstants.spacingSm),
            Text(
              'API 설정',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: UIConstants.spacingMd),

        // ✅ 카드로 감싸기
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.radiusLg),
            side: BorderSide(
              color: colorScheme.outlineVariant.withAlpha(UIConstants.alpha60),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(UIConstants.spacingMd),
            child: settingsAsync.when(
              data: (settings) {
                if (_apiKeyController.text.isEmpty &&
                    settings.apiKey.isNotEmpty) {
                  _apiKeyController.text = settings.apiKey;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ 설명 텍스트 개선
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: UIConstants.iconSm,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: UIConstants.spacingXs),
                        Expanded(
                          child: Text(
                            'OpenRouter API 키를 입력하세요',
                            style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: UIConstants.spacingMd),

                    // ✅ API Key 입력 필드
                    TextField(
                      controller: _apiKeyController,
                      obscureText: _isObscured,
                      decoration: InputDecoration(
                        labelText: 'OpenRouter API Key',
                        hintText: 'sk-or-v1-...',
                        prefixIcon: Icon(
                          Icons.vpn_key,
                          color: colorScheme.primary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscured
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isObscured = !_isObscured;
                            });
                          },
                          tooltip: _isObscured ? '표시' : '숨기기',
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(UIConstants.radiusMd),
                        ),
                      ),
                      onChanged: (value) {
                        ref
                            .read(settingsProvider.notifier)
                            .updateApiKey(value);
                      },
                    ),
                    const SizedBox(height: UIConstants.spacingSm),

                    // ✅ 도움말 링크 (작동하는 버전)
                    TextButton.icon(
                      onPressed: _launchApiKeyPage,
                      icon: const Icon(
                        Icons.open_in_new,
                        size: UIConstants.iconSm,
                      ),
                      label: const Text('API 키 발급받기'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(UIConstants.spacingLg),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.all(UIConstants.spacingMd),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: UIConstants.spacingSm),
                    Expanded(
                      child: Text(
                        '설정을 불러올 수 없습니다: $error',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
