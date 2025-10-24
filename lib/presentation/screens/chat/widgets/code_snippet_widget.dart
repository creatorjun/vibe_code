// lib/presentation/screens/chat/widgets/code_snippet_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/app_colors.dart';

class CodeSnippetSliver extends StatelessWidget {
  final String code;
  final String language;
  final Color backgroundColor;
  final bool isIntegrated;

  const CodeSnippetSliver({
    super.key,
    required this.code,
    required this.language,
    required this.backgroundColor,
    this.isIntegrated = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codeBackgroundColor = isDark
        ? AppColors.codeBackgroundDark
        : AppColors.codeBackgroundLight;

    return SliverMainAxisGroup(
      slivers: [
        // 스티키 헤더
        SliverPersistentHeader(
          pinned: true,
          delegate: _CodeHeaderDelegate(
            language: language,
            code: code,
            isIntegrated: isIntegrated,
          ),
        ),

        // 코드 본문
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(UIConstants.spacingMd),
            decoration: BoxDecoration(
              color: codeBackgroundColor,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                code,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? Colors.white.withAlpha(230) : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CodeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String language;
  final String code;
  final bool isIntegrated;

  static const double _headerHeight = 44.0;

  _CodeHeaderDelegate({
    required this.language,
    required this.code,
    required this.isIntegrated,
  });

  @override
  double get minExtent => _headerHeight;

  @override
  double get maxExtent => _headerHeight;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: _headerHeight,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF2D2D2D),
      ),
      child: _CodeHeader(
        language: language,
        code: code,
      ),
    );
  }

  @override
  bool shouldRebuild(_CodeHeaderDelegate oldDelegate) {
    return language != oldDelegate.language ||
        code != oldDelegate.code ||
        isIntegrated != oldDelegate.isIntegrated;
  }
}

class _CodeHeader extends StatefulWidget {
  final String language;
  final String code;

  const _CodeHeader({
    required this.language,
    required this.code,
  });

  @override
  State<_CodeHeader> createState() => _CodeHeaderState();
}

class _CodeHeaderState extends State<_CodeHeader> {
  bool _isCopied = false;

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _isCopied = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('코드 복사 완료'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // 2초 후 아이콘 원래대로
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isCopied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16),
        _buildLanguageTag(),
        const Spacer(),
        _buildCopyButton(),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildLanguageTag() {
    final displayLanguage = _getLanguageDisplayName(widget.language);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.code,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            displayLanguage.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _copyToClipboard,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isCopied ? Icons.check_circle : Icons.content_copy,
                size: 16,
                color: _isCopied ? Colors.greenAccent : Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                _isCopied ? '복사됨!' : '복사',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _isCopied ? Colors.greenAccent : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageDisplayName(String lang) {
    const languageMap = {
      'dart': 'Dart',
      'javascript': 'JavaScript',
      'js': 'JavaScript',
      'typescript': 'TypeScript',
      'ts': 'TypeScript',
      'python': 'Python',
      'py': 'Python',
      'java': 'Java',
      'kotlin': 'Kotlin',
      'swift': 'Swift',
      'go': 'Go',
      'rust': 'Rust',
      'cpp': 'C++',
      'c': 'C',
      'csharp': 'C#',
      'php': 'PHP',
      'ruby': 'Ruby',
      'html': 'HTML',
      'css': 'CSS',
      'json': 'JSON',
      'yaml': 'YAML',
      'xml': 'XML',
      'sql': 'SQL',
      'bash': 'Bash',
      'shell': 'Shell',
      'text': 'Text',
    };
    return languageMap[lang.toLowerCase()] ?? lang;
  }
}
