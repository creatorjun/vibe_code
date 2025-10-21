import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../data/services/github_analysis_service.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../shared/widgets/loading_indicator.dart';

class GitHubAnalysisDialog extends ConsumerStatefulWidget {
  const GitHubAnalysisDialog({super.key});

  @override
  ConsumerState<GitHubAnalysisDialog> createState() => _GitHubAnalysisDialogState();
}

class _GitHubAnalysisDialogState extends ConsumerState<GitHubAnalysisDialog> {
  final TextEditingController _urlController = TextEditingController();
  String? _selectedDirectory;
  bool _isAnalyzing = false;
  int _selectedTab = 0;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusLg),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(UIConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.code, size: 28),
                const SizedBox(width: UIConstants.spacingSm),
                Text(
                  '프로젝트 분석',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.spacingLg),

            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('GitHub URL'),
                  icon: Icon(Icons.link),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('로컬 폴더'),
                  icon: Icon(Icons.folder),
                ),
              ],
              selected: {_selectedTab},
              onSelectionChanged: (Set<int> selected) {
                setState(() {
                  _selectedTab = selected.first;
                  _urlController.clear();
                  _selectedDirectory = null;
                });
              },
            ),

            const SizedBox(height: UIConstants.spacingLg),

            if (_selectedTab == 0) ...[
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'GitHub 저장소 URL',
                  hintText: 'https://github.com/user/repo',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: UIConstants.spacingSm),
              Text(
                '공개 저장소 또는 .env에 GITHUB_TOKEN이 설정된 경우\n비공개 저장소도 분석할 수 있습니다.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(UIConstants.spacingMd),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(UIConstants.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder_outlined),
                    const SizedBox(width: UIConstants.spacingSm),
                    Expanded(
                      child: Text(
                        _selectedDirectory ?? '폴더를 선택하세요',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _selectedDirectory == null
                              ? Theme.of(context).textTheme.bodySmall?.color
                              : null,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _pickDirectory,
                      child: const Text('선택'),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: UIConstants.spacingLg),

            if (_isAnalyzing)
              const Column(
                children: [
                  LoadingIndicator(message: '프로젝트 분석 중...'),
                  SizedBox(height: UIConstants.spacingSm),
                  Text(
                    '프로젝트 크기에 따라 시간이 걸릴 수 있습니다.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: UIConstants.spacingSm),
                  ElevatedButton.icon(
                    onPressed: _canAnalyze ? _analyze : null,
                    icon: const Icon(Icons.analytics),
                    label: const Text('분석 시작'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  bool get _canAnalyze {
    if (_selectedTab == 0) {
      return _urlController.text.trim().isNotEmpty;
    } else {
      return _selectedDirectory != null;
    }
  }

  Future<void> _pickDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        setState(() {
          _selectedDirectory = result;
        });
      }
    } catch (e) {
      Logger.error('Failed to pick directory', e, null);
    }
  }

  Future<void> _analyze() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final service = GitHubAnalysisService();
      final String content;

      if (_selectedTab == 0) {
        content = await service.analyzeRepository(_urlController.text.trim());
      } else {
        content = await service.analyzeLocalDirectory(_selectedDirectory!);
      }

      if (mounted) {
        Navigator.of(context).pop(content);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('분석 실패: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }
}
