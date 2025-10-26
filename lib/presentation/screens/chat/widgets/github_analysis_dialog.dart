// lib/presentation/screens/chat/widgets/github_analysis_dialog.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(UIConstants.spacingXl),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(UIConstants.radiusXl),
          border: Border.all(
            color: colorScheme.outline.withAlpha(UIConstants.alpha20),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? UIConstants.alpha40 : UIConstants.alpha20),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ 현대적인 헤더
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(UIConstants.spacingMd),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withAlpha(UIConstants.alpha70),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(UIConstants.radiusMd),
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.github,
                    size: UIConstants.iconLg,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: UIConstants.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GitHub 프로젝트 분석',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '저장소 구조와 코드를 분석합니다',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withAlpha(UIConstants.alpha60),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: FaIcon(
                    FontAwesomeIcons.xmark,
                    size: UIConstants.iconSm,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(UIConstants.radiusSm),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: UIConstants.spacingXl),

            // ✅ GitHub URL 입력
            Text(
              '원격 저장소',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: UIConstants.spacingSm),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'https://github.com/owner/repo',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(UIConstants.spacingMd),
                  child: FaIcon(
                    FontAwesomeIcons.link,
                    size: UIConstants.iconSm,
                    color: colorScheme.primary,
                  ),
                ),
                suffixIcon: _isUrlValid
                    ? Padding(
                  padding: const EdgeInsets.all(UIConstants.spacingMd),
                  child: FaIcon(
                    FontAwesomeIcons.circleCheck,
                    size: UIConstants.iconSm,
                    color: Colors.green,
                  ),
                )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withAlpha(UIConstants.alpha50),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UIConstants.radiusMd),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UIConstants.radiusMd),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _isUrlValid = _validateGitHubUrl(value);
                });
              },
            ),

            const SizedBox(height: UIConstants.spacingLg),

            // ✅ 구분선
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: colorScheme.outline.withAlpha(UIConstants.alpha30),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UIConstants.spacingMd,
                  ),
                  child: Text(
                    '또는',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withAlpha(UIConstants.alpha60),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: colorScheme.outline.withAlpha(UIConstants.alpha30),
                  ),
                ),
              ],
            ),

            const SizedBox(height: UIConstants.spacingLg),

            // ✅ 로컬 폴더 선택
            Text(
              '로컬 폴더',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: UIConstants.spacingSm),

            OutlinedButton.icon(
              onPressed: _pickDirectory,
              icon: FaIcon(
                FontAwesomeIcons.folderOpen,
                size: UIConstants.iconSm,
              ),
              label: Text(
                _selectedDirectory == null ? '폴더 선택' : '폴더 변경',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: UIConstants.spacingLg,
                  vertical: UIConstants.spacingMd,
                ),
                side: BorderSide(
                  color: colorScheme.outline.withAlpha(UIConstants.alpha50),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(UIConstants.radiusMd),
                ),
              ),
            ),

            if (_selectedDirectory != null) ...[
              const SizedBox(height: UIConstants.spacingMd),
              Container(
                padding: const EdgeInsets.all(UIConstants.spacingMd),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withAlpha(UIConstants.alpha30),
                  borderRadius: BorderRadius.circular(UIConstants.radiusMd),
                  border: Border.all(
                    color: colorScheme.primary.withAlpha(UIConstants.alpha30),
                  ),
                ),
                child: Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.folder,
                      size: UIConstants.iconSm,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: UIConstants.spacingSm),
                    Expanded(
                      child: Text(
                        _selectedDirectory!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: UIConstants.spacingXl),

            // ✅ 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isAnalyzing
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: UIConstants.spacingLg,
                      vertical: UIConstants.spacingMd,
                    ),
                  ),
                  child: const Text(
                    '취소',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: UIConstants.spacingSm),
                FilledButton.icon(
                  onPressed: _isAnalyzing || !_canAnalyze() ? null : _analyze,
                  icon: _isAnalyzing
                      ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onPrimary,
                      ),
                    ),
                  )
                      : FaIcon(
                    FontAwesomeIcons.play,
                    size: UIConstants.iconSm,
                  ),
                  label: Text(
                    _isAnalyzing ? '분석 중...' : '분석 시작',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: UIConstants.spacingLg,
                      vertical: UIConstants.spacingMd,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(UIConstants.radiusMd),
                    ),
                  ),
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
            content: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.triangleExclamation,
                  size: UIConstants.iconSm,
                  color: Colors.white,
                ),
                const SizedBox(width: UIConstants.spacingSm),
                Expanded(
                  child: Text('분석 실패: $e'),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UIConstants.radiusMd),
            ),
          ),
        );
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }
}
