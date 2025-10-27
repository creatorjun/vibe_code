// lib/presentation/screens/chat/widgets/code_snippet_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// 코드 스니펫 Sliver 위젯
class CodeSnippetSliver {
  final String code;
  final String language;
  final bool isIntegrated;

  const CodeSnippetSliver({
    required this.code,
    required this.language,
    this.isIntegrated = false,
  });

  /// ✅ SliverMainAxisGroup으로 헤더와 본문을 그룹화
  /// 코드 블록이 화면을 벗어나면 헤더도 자연스럽게 사라짐
  List<Widget> buildAsSliverWithBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codeBackgroundColor = isDark
        ? AppColors.codeBackgroundDark
        : AppColors.codeBackgroundLight;

    // ✅ AppColors에서 bubbleColor 가져오기
    final bubbleColor = isDark
        ? AppColors.aiBubbleDark
        : AppColors.aiBubbleLight;

    return [
      // ✅ 헤더와 본문을 하나의 그룹으로 묶음
      SliverMainAxisGroup(
        slivers: [
          // Sticky 헤더 (이 그룹 범위 내에서만 유효)
          SliverPersistentHeader(
            pinned: true,
            delegate: _CodeHeaderDelegate(
              language: language,
              code: code,
              isDark: isDark,
              isIntegrated: isIntegrated,
              bubbleColor: bubbleColor,
              horizontalPadding: UIConstants.spacingLg,
            ),
          ),
          // 코드 본문
          SliverToBoxAdapter(
            child: Container(
              color: bubbleColor,
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.spacingLg,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(UIConstants.spacingMd),
                decoration: BoxDecoration(
                  color: codeBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(UIConstants.radiusSm),
                    bottomRight: Radius.circular(UIConstants.radiusSm),
                  ),
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
          ),
        ],
      ),
    ];
  }

  /// 기본 Sliver 리스트로 변환 (독립 사용)
  List<Widget> buildAsSliver(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codeBackgroundColor = isDark
        ? AppColors.codeBackgroundDark
        : AppColors.codeBackgroundLight;

    // ✅ AppColors에서 bubbleColor 가져오기
    final bubbleColor = isDark
        ? AppColors.aiBubbleDark
        : AppColors.aiBubbleLight;

    return [
      SliverMainAxisGroup(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _CodeHeaderDelegate(
              language: language,
              code: code,
              isDark: isDark,
              isIntegrated: false,
              bubbleColor: bubbleColor,
              horizontalPadding: 0,
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(UIConstants.spacingMd),
              decoration: BoxDecoration(
                color: codeBackgroundColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(UIConstants.radiusSm),
                  bottomRight: Radius.circular(UIConstants.radiusSm),
                ),
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
      ),
    ];
  }
}

/// 코드 헤더 Delegate (Sticky Header)
class _CodeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String language;
  final String code;
  final bool isDark;
  final bool isIntegrated;
  final Color bubbleColor;
  final double horizontalPadding;

  static const double _headerHeight = 44.0;

  _CodeHeaderDelegate({
    required this.language,
    required this.code,
    required this.isDark,
    required this.isIntegrated,
    required this.bubbleColor,
    this.horizontalPadding = 0,
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
    final borderRadius = shrinkOffset == 0
        ? const BorderRadius.only(
      topLeft: Radius.circular(UIConstants.radiusSm),
      topRight: Radius.circular(UIConstants.radiusSm),
    )
        : BorderRadius.zero;

    return Container(
      height: _headerHeight,
      color: isIntegrated ? bubbleColor : null,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          borderRadius: borderRadius,
        ),
        child: _CodeHeader(
          language: language,
          code: code,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_CodeHeaderDelegate oldDelegate) {
    return language != oldDelegate.language ||
        code != oldDelegate.code ||
        isDark != oldDelegate.isDark ||
        isIntegrated != oldDelegate.isIntegrated ||
        bubbleColor != oldDelegate.bubbleColor ||
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

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _isCopied = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('코드가 복사되었습니다'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

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
          color: _isCopied
              ? Colors.green
              : Colors.white.withAlpha(230),
        ),
      ),
    );
  }
}
