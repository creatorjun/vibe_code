import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// Sliver 기반 코드 스니펫 위젯 (버블과 시각적 통합)
class CodeSnippetSliver extends StatelessWidget {
  final String code;
  final String language;
  final Color backgroundColor;

  const CodeSnippetSliver({
    super.key,
    required this.code,
    this.language = 'text',
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        // 상단 패딩 (버블 배경색)
        SliverToBoxAdapter(
          child: Container(
            height: UIConstants.spacingSm,
            color: backgroundColor,
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _CodeHeaderDelegate(
            language: language,
            code: code,
          ),
        ),
        SliverToBoxAdapter(
          child: _buildCodeContent(),
        ),
        // 하단 패딩 (버블 배경색)
        SliverToBoxAdapter(
          child: Container(
            height: UIConstants.spacingSm,
            color: backgroundColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeContent() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 100,
        maxHeight: 400,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(50),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(UIConstants.radiusLg),
          bottomRight: Radius.circular(UIConstants.radiusLg),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          code,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: Colors.white,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

class _CodeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String language;
  final String code;

  _CodeHeaderDelegate({
    required this.language,
    required this.code,
  });

  @override
  double get minExtent => 44;

  @override
  double get maxExtent => 44;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withAlpha(230)
            : Colors.black.withAlpha(200),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(UIConstants.radiusLg),
          topRight: Radius.circular(UIConstants.radiusLg),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(UIConstants.radiusLg),
          topRight: Radius.circular(UIConstants.radiusLg),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              const SizedBox(width: 16),
              _buildLanguageTag(),
              const Spacer(),
              _buildCopyButton(context),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTag() {
    final displayLanguage = _getLanguageDisplayName(language);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        displayLanguage.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCopyButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.copy_outlined, size: 18, color: Colors.white70),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('코드 복사 완료'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      tooltip: '복사',
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
    );
  }

  String _getLanguageDisplayName(String lang) {
    const languageMap = {
      'dart': 'Dart', 'javascript': 'JavaScript', 'js': 'JavaScript',
      'typescript': 'TypeScript', 'ts': 'TypeScript', 'python': 'Python',
      'py': 'Python', 'java': 'Java', 'kotlin': 'Kotlin', 'swift': 'Swift',
      'go': 'Go', 'rust': 'Rust', 'cpp': 'C++', 'c': 'C', 'csharp': 'C#',
      'php': 'PHP', 'ruby': 'Ruby', 'html': 'HTML', 'css': 'CSS',
      'json': 'JSON', 'yaml': 'YAML', 'xml': 'XML', 'sql': 'SQL',
      'bash': 'Bash', 'shell': 'Shell', 'text': 'Text',
    };
    return languageMap[lang.toLowerCase()] ?? lang;
  }

  @override
  bool shouldRebuild(_CodeHeaderDelegate oldDelegate) {
    return language != oldDelegate.language || code != oldDelegate.code;
  }
}
