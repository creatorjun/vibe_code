// lib/presentation/screens/chat/widgets/github_analysis_dialog.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../data/services/github_analysis_service.dart';

class GitHubAnalysisDialog extends StatefulWidget {
  const GitHubAnalysisDialog({super.key});

  @override
  State<GitHubAnalysisDialog> createState() => _GitHubAnalysisDialogState();
}

class _GitHubAnalysisDialogState extends State<GitHubAnalysisDialog> {
  bool _isAnalyzing = false;
  final _urlController = TextEditingController();
  String? _selectedDirectory;
  bool _isUrlValid = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  bool _validateGitHubUrl(String url) {
    final urlPattern = RegExp(
      r'^https?:\/\/(www\.)?github\.com\/[\w-]+\/[\w.-]+\/?$',
      caseSensitive: false,
    );
    return urlPattern.hasMatch(url.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusLg),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(UIConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ 간소화된 헤더
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: UIConstants.iconLg,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: UIConstants.spacingSm),
                Expanded(
                  child: Text(
                    'GitHub 프로젝트 분석',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: UIConstants.spacingLg),

            // ✅ GitHub URL 입력
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: '원격 저장소',
                hintText: 'https://github.com/owner/repo',
                prefixIcon: const Icon(Icons.link),
                suffixIcon: _isUrlValid
                    ? Icon(Icons.check_circle, color: colorScheme.primary)
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UIConstants.radiusMd),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _isUrlValid = _validateGitHubUrl(value);
                });
              },
            ),

            const SizedBox(height: UIConstants.spacingMd),

            // ✅ 구분선
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UIConstants.spacingSm,
                  ),
                  child: Text(
                    '또는',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface
                          .withAlpha(UIConstants.alpha60),
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: UIConstants.spacingMd),

            // ✅ 로컬 폴더 선택
            OutlinedButton.icon(
              onPressed: _pickDirectory,
              icon: const Icon(Icons.folder_open),
              label: Text(_selectedDirectory == null ? '로컬 폴더 선택' : '폴더 변경'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(UIConstants.spacingMd),
              ),
            ),

            if (_selectedDirectory != null) ...[
              const SizedBox(height: UIConstants.spacingSm),
              Container(
                padding: const EdgeInsets.all(UIConstants.spacingSm),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer
                      .withAlpha(UIConstants.alpha30),
                  borderRadius: BorderRadius.circular(UIConstants.radiusSm),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder,
                      size: UIConstants.iconSm,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: UIConstants.spacingXs),
                    Expanded(
                      child: Text(
                        _selectedDirectory!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: UIConstants.spacingLg),

            // ✅ 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isAnalyzing
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                const SizedBox(width: UIConstants.spacingSm),
                FilledButton.icon(
                  onPressed: _isAnalyzing || !_canAnalyze() ? null : _analyze,
                  icon: _isAnalyzing
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.play_arrow),
                  label: Text(_isAnalyzing ? '분석 중...' : '분석'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _canAnalyze() {
    return _isUrlValid || _selectedDirectory != null;
  }

  Future<void> _pickDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        _selectedDirectory = result;
      });
    }
  }

  Future<void> _analyze() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final service = GitHubAnalysisService();
      final String content;

      if (_isUrlValid && _urlController.text.trim().isNotEmpty) {
        content = await service.analyzeRepository(_urlController.text.trim());
      } else if (_selectedDirectory != null) {
        content = await service.analyzeLocalDirectory(_selectedDirectory!);
      } else {
        return;
      }

      if (mounted) {
        Navigator.of(context).pop(content);
      }
    } catch (e) {
      Logger.error('Analysis failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('분석 실패: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }
}
