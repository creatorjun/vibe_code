import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../common/constants/app_colors.dart';
import '../../common/constants/ui_constants.dart';

/// Sticky 헤더가 있는 코드 스니펫 위젯
///
/// 스크롤 시 헤더가 화면 상단에 고정되며,
/// 코드 내용은 가로 스크롤을 지원합니다.
/// 통합된 말풍선의 일부로 표시될 수 있도록 isFirst/LastInSection 속성을 가집니다.
class StickyCodeSnippet extends StatelessWidget {
  final String code;
  final String language;
  final bool isFirstInSection;
  final bool isLastInSection;

  const StickyCodeSnippet({
    super.key,
    required this.code,
    this.language = 'dart',
    this.isFirstInSection = true,
    this.isLastInSection = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: UIConstants.spacing16,
        vertical: isFirstInSection && isLastInSection ? UIConstants.spacing4 : 0,
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _CodeHeaderDelegate(
              language: language,
              code: code,
              isDark: isDark,
              isFirstInSection: isFirstInSection,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildCodeContent(isDark),
          ),
        ],
      ),
    );
  }

  /// 코드 높이 계산 (✅ 수정된 함수)
  double _calculateCodeHeight() {
    final trimmedCode = code.trim();
    // 코드가 비어있으면 높이를 0으로 반환합니다.
    if (trimmedCode.isEmpty) {
      return 0.0;
    }
    // 올바른 줄 수를 세어 높이를 계산합니다.
    final lineCount = trimmedCode.split('\n').length;
    return lineCount * UIConstants.codeLineHeight;
  }

  /// 코드 콘텐츠 빌더
  Widget _buildCodeContent(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(UIConstants.glassAlphaLow),
        border: Border(
          left: BorderSide(
            color: Colors.white.withAlpha(UIConstants.glassAlphaBorder),
            width: UIConstants.codeBorderWidth,
          ),
          right: BorderSide(
            color: Colors.white.withAlpha(UIConstants.glassAlphaBorder),
            width: UIConstants.codeBorderWidth,
          ),
          bottom: BorderSide(
            color: Colors.white.withAlpha(UIConstants.glassAlphaBorder),
            width: UIConstants.codeBorderWidth,
          ),
        ),
        borderRadius: isLastInSection
            ? const BorderRadius.only(
          bottomLeft: Radius.circular(UIConstants.radiusLarge),
          bottomRight: Radius.circular(UIConstants.radiusLarge),
        )
            : null,
      ),
      padding: const EdgeInsets.all(UIConstants.spacing16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          code,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: UIConstants.fontMedium,
            color: Colors.white,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

/// 코드 스니펫 헤더 Delegate
///
/// SliverPersistentHeader에 사용되는 delegate로,
/// 스티키 상태와 섹션 내 위치에 따라 border radius를 조정합니다.
class _CodeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String language;
  final String code;
  final bool isDark;
  final bool isFirstInSection;

  _CodeHeaderDelegate({
    required this.language,
    required this.code,
    required this.isDark,
    required this.isFirstInSection,
  });

  @override
  double get minExtent => UIConstants.codeHeaderHeight;

  @override
  double get maxExtent => UIConstants.codeHeaderHeight;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    final isSticky = shrinkOffset > 0;
    final borderRadius = (isFirstInSection && !isSticky)
        ? const BorderRadius.only(
      topLeft: Radius.circular(UIConstants.radiusLarge),
      topRight: Radius.circular(UIConstants.radiusLarge),
    )
        : BorderRadius.zero;

    return Container(
      height: UIConstants.codeHeaderHeight,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withAlpha(UIConstants.glassAlphaVeryHigh)
            : Colors.black.withAlpha(UIConstants.glassAlphaHigh),
        border: Border(
          left: BorderSide(
            color: Colors.white.withAlpha(UIConstants.glassAlphaBorder),
            width: UIConstants.codeBorderWidth,
          ),
          right: BorderSide(
            color: Colors.white.withAlpha(UIConstants.glassAlphaBorder),
            width: UIConstants.codeBorderWidth,
          ),
          top: BorderSide(
            color: Colors.white.withAlpha(UIConstants.glassAlphaBorder),
            width: UIConstants.codeBorderWidth,
          ),
        ),
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: UIConstants.blurSigmaMedium,
            sigmaY: UIConstants.blurSigmaMedium,
          ),
          child: _buildHeaderContent(context),
        ),
      ),
    );
  }

  /// 헤더 콘텐츠 빌더
  Widget _buildHeaderContent(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: UIConstants.codeHeaderPadding),
        _buildLanguageTag(),
        const Spacer(),
        _buildExportButton(context),
        const SizedBox(width: UIConstants.spacing4),
        _buildCopyButton(context),
        const SizedBox(width: UIConstants.spacing12),
      ],
    );
  }

  /// 언어 태그 빌더
  Widget _buildLanguageTag() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacing10,
        vertical: UIConstants.spacing4,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
      ),
      child: Text(
        language.toUpperCase(),
        style: const TextStyle(
          fontSize: UIConstants.fontTiny,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  /// 내보내기 버튼 빌더
  Widget _buildExportButton(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.download_outlined,
        size: UIConstants.iconSmall,
        color: Colors.white70,
      ),
      onPressed: () {
        _showSnackBar(context, '코드 내보내기 (구현 예정)');
      },
      tooltip: '내보내기',
      padding: const EdgeInsets.all(UIConstants.spacing8),
      constraints: const BoxConstraints(),
    );
  }

  /// 복사 버튼 빌더
  Widget _buildCopyButton(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.copy_outlined,
        size: UIConstants.iconSmall,
        color: Colors.white70,
      ),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: code));
        _showSnackBar(context, '코드가 복사되었습니다');
      },
      tooltip: '복사',
      padding: const EdgeInsets.all(UIConstants.spacing8),
      constraints: const BoxConstraints(),
    );
  }

  /// 스낵바 표시 헬퍼
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  bool shouldRebuild(_CodeHeaderDelegate oldDelegate) {
    return language != oldDelegate.language ||
        code != oldDelegate.code ||
        isDark != oldDelegate.isDark ||
        isFirstInSection != oldDelegate.isFirstInSection;
  }
}