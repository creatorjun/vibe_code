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

class _GitHubAnalysisDialogState extends State<GitHubAnalysisDialog>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  bool _isAnalyzing = false;
  final _urlController = TextEditingController();
  String? _selectedDirectory;
  bool _isUrlValid = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tabController.dispose();
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
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(UIConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                const Icon(Icons.code, size: 28),
                const SizedBox(width: UIConstants.spacingSm),
                Text(
                  'GitHub 프로젝트 분석',
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

            // 탭
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '원격 저장소'),
                Tab(text: '로컬 프로젝트'),
              ],
            ),
            const SizedBox(height: UIConstants.spacingLg),

            // 컨텐츠
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 원격 저장소
                  Column(
                    children: [
                      TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'Repository URL',
                          hintText: 'https://github.com/owner/repo',
                          prefixIcon: Icon(Icons.link),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _isUrlValid = _validateGitHubUrl(value);
                          });
                        },
                      ),
                      const SizedBox(height: UIConstants.spacingMd),
                      Text(
                        '예: https://github.com/flutter/flutter',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  // 로컬 프로젝트
                  Column(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickDirectory,
                        icon: const Icon(Icons.folder_open),
                        label: Text(
                          _selectedDirectory ?? '폴더 선택',
                        ),
                      ),
                      if (_selectedDirectory != null) ...[
                        const SizedBox(height: UIConstants.spacingMd),
                        Text(
                          _selectedDirectory!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // 하단 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                  _isAnalyzing ? null : () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                const SizedBox(width: UIConstants.spacingSm),
                ElevatedButton.icon(
                  onPressed: _isAnalyzing ||
                      (_selectedTab == 0 && !_isUrlValid) ||
                      (_selectedTab == 1 && _selectedDirectory == null)
                      ? null
                      : _analyze,
                  icon: _isAnalyzing
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.analytics),
                  label: Text(_isAnalyzing ? '분석 중...' : '분석 시작'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

      if (_selectedTab == 0) {
        content = await service.analyzeRepository(_urlController.text.trim());
      } else {
        content = await service.analyzeLocalDirectory(_selectedDirectory!);
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
          ),
        );
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }
}
