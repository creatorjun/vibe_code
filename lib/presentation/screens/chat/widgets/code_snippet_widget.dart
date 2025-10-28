// lib/presentation/screens/chat/widgets/code_snippet_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// 코드 스니펫 Sliver 위젯
class CodeSnippetSliver {
  final String code;
  final String language;

  const CodeSnippetSliver({
    required this.code,
    required this.language,
  });

  /// SliverMainAxisGroup으로 헤더와 본문을 그룹화
  List<Widget> buildAsSliverWithBackground(BuildContext context) {
    final colors = _getColorScheme(context);

    return [
      SliverMainAxisGroup(
        slivers: [
          // Sticky 헤더 (디바이더 포함)
          SliverPersistentHeader(
            pinned: true,
            delegate: _CodeHeaderDelegate(
              language: language,
              code: code,
              colors: colors,
              horizontalPadding: UIConstants.spacingLg,
            ),
          ),

          // 코드 본문 (하이라이팅 + JetBrains Mono 폰트 적용)
          SliverToBoxAdapter(
            child: Container(
              color: colors.bubbleColor,
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.spacingLg,
              ),
              child: _CodeBody(
                code: code,
                language: language,
                backgroundColor: colors.codeBackground,
                isDark: colors.isDark,
              ),
            ),
          ),
        ],
      ),
    ];
  }

  /// 색상 스키마 계산
  _CodeColorScheme _getColorScheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _CodeColorScheme(
      isDark: isDark,
      bubbleColor: isDark ? AppColors.aiBubbleDark : AppColors.aiBubbleLight,
      codeBackground: isDark ? AppColors.codeBackgroundDark : AppColors.codeBackgroundLight,
      textColor: isDark ? Colors.white.withAlpha(230) : Colors.black87,
    );
  }
}

/// 색상 스키마
class _CodeColorScheme {
  final bool isDark;
  final Color bubbleColor;
  final Color codeBackground;
  final Color textColor;

  const _CodeColorScheme({
    required this.isDark,
    required this.bubbleColor,
    required this.codeBackground,
    required this.textColor,
  });
}

/// 테마 캐시 - 성능 최적화
class CodeSnippetThemeCache {
  static Map<String, TextStyle>? _cachedDarkTheme;
  static Map<String, TextStyle>? _cachedLightTheme;

  static Map<String, TextStyle> getTheme(bool isDark) {
    if (isDark) {
      return _cachedDarkTheme ??= _createCustomTheme(monokaiSublimeTheme);
    } else {
      return _cachedLightTheme ??= _createCustomTheme(githubTheme);
    }
  }

  static Map<String, TextStyle> _createCustomTheme(Map<String, TextStyle> baseTheme) {
    final customTheme = Map<String, TextStyle>.from(baseTheme);

    // 배경색 제거
    if (customTheme.containsKey('root')) {
      customTheme['root'] = customTheme['root']!.copyWith(
        backgroundColor: Colors.transparent,
      );
    } else {
      customTheme['root'] = const TextStyle(backgroundColor: Colors.transparent);
    }

    return customTheme;
  }

  /// 앱 테마 변경 시 캐시 초기화
  static void clearCache() {
    _cachedDarkTheme = null;
    _cachedLightTheme = null;
  }
}

/// 코드 본문 위젯 (하이라이팅 + JetBrains Mono 적용)
class _CodeBody extends StatelessWidget {
  final String code;
  final String language;
  final Color backgroundColor;
  final bool isDark;

  const _CodeBody({
    required this.code,
    required this.language,
    required this.backgroundColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // AppConstants에서 언어 매핑 조회
    final highlightLanguage = AppConstants.languageMap[language.toLowerCase()] ?? 'plaintext';

    // 캐시된 테마 사용
    final theme = CodeSnippetThemeCache.getTheme(isDark);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(UIConstants.radiusSm),
          bottomRight: Radius.circular(UIConstants.radiusSm),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.spacingMd),
          child: HighlightView(
            code,
            language: highlightLanguage,
            theme: theme,
            padding: EdgeInsets.zero,
            textStyle: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// 코드 헤더 Delegate (디바이더 포함)
class _CodeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String language;
  final String code;
  final _CodeColorScheme colors;
  final double horizontalPadding;
  static const double _headerHeight = 44.0;
  static const double _dividerHeight = 1.0;

  const _CodeHeaderDelegate({
    required this.language,
    required this.code,
    required this.colors,
    this.horizontalPadding = 0,
  });

  @override
  double get minExtent => _headerHeight + _dividerHeight;

  @override
  double get maxExtent => _headerHeight + _dividerHeight;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    final borderRadius = shrinkOffset == 0
        ? const BorderRadius.only(
      topLeft: Radius.circular(UIConstants.radiusSm),
      topRight: Radius.circular(UIConstants.radiusSm),
    )
        : BorderRadius.zero;

    return Container(
      color: colors.bubbleColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Container(
            height: _headerHeight,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Container(
              decoration: BoxDecoration(
                color: colors.codeBackground,
                borderRadius: borderRadius,
              ),
              child: _CodeHeader(
                language: language,
                code: code,
              ),
            ),
          ),

          // 디바이더
          Container(
            height: _dividerHeight,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_CodeHeaderDelegate oldDelegate) {
    return language != oldDelegate.language ||
        code != oldDelegate.code ||
        colors.isDark != oldDelegate.colors.isDark ||
        horizontalPadding != oldDelegate.horizontalPadding;
  }
}

/// 코드 헤더 위젯
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

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;

    setState(() => _isCopied = true);
    _showCopiedSnackBar();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  void _showCopiedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('코드가 복사되었습니다'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: UIConstants.spacingMd),
        _buildLanguageTag(),
        const Spacer(),
        _buildCopyButton(),
        const SizedBox(width: UIConstants.spacingMd),
      ],
    );
  }

  Widget _buildLanguageTag() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacingSm,
        vertical: UIConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(UIConstants.radiusSm),
      ),
      child: Text(
        widget.language.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCopyButton() {
    return InkWell(
      onTap: _copyToClipboard,
      borderRadius: BorderRadius.circular(UIConstants.radiusSm),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacingXs),
        child: Icon(
          _isCopied ? Icons.check : Icons.copy_all,
          size: UIConstants.iconSm,
          color: _isCopied ? Colors.green : Colors.white.withAlpha(230),
        ),
      ),
    );
  }
}
