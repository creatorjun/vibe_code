// lib/presentation/shared/widgets/markdown_text_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:vibe_code/core/theme/app_colors.dart';
import 'package:vibe_code/core/utils/logger.dart';
import 'package:vibe_code/presentation/screens/settings/widgets/custom_snack_bar.dart';

/// GitHub 스타일 마크다운 텍스트 위젯
class MarkdownTextWidget extends StatelessWidget {
  final String data;
  final TextStyle? baseStyle;
  final Color? textColor;

  const MarkdownTextWidget({
    super.key,
    required this.data,
    this.baseStyle,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MarkdownBody(
      data: data,
      selectable: true,
      // ✅ 핵심 1: softLineBreak 활성화 (단일 줄바꿈 허용)
      softLineBreak: true,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      // ✅ 핵심 2: 스크롤 비활성화 (부모가 스크롤 처리)
      shrinkWrap: true,
      // ✅ 핵심 3: 물리적 스크롤 비활성화
      fitContent: true,
      styleSheet: MarkdownStyleSheet(
        // ✅ 기본 텍스트 (overflow 추가)
        p: baseStyle?.copyWith(
          color: textColor,
          height: 1.5, // ✅ 줄 간격 추가
        ),

        // ✅ 링크 (overflow 추가)
        a: TextStyle(
          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          decoration: TextDecoration.underline,
          height: 1.5, // ✅ 줄 간격
        ),

        // 강조
        strong: baseStyle?.copyWith(
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.5, // ✅ 줄 간격
        ),
        em: baseStyle?.copyWith(
          fontStyle: FontStyle.italic,
          color: textColor,
          height: 1.5, // ✅ 줄 간격
        ),
        del: baseStyle?.copyWith(
          decoration: TextDecoration.lineThrough,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          height: 1.5, // ✅ 줄 간격
        ),

        // 인라인 코드
        code: baseStyle?.copyWith(
          fontFamily: 'monospace',
          fontSize: (baseStyle?.fontSize ?? 14) * 0.9,
          backgroundColor: isDark
              ? AppColors.darkText.withAlpha(26)
              : AppColors.lightText.withAlpha(13),
          color: isDark
              ? AppColors.darkPrimary
              : AppColors.lightPrimary,
          height: 1.5, // ✅ 줄 간격
        ),
        codeblockDecoration: BoxDecoration(
          color: isDark
              ? AppColors.codeBackgroundDark
              : AppColors.codeBackgroundLight,
          borderRadius: BorderRadius.circular(8),
        ),

        // 제목
        h1: baseStyle?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.2,
        ),
        h2: baseStyle?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.2,
        ),
        h3: baseStyle?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.2,
        ),
        h4: baseStyle?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.2,
        ),
        h5: baseStyle?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.2,
        ),
        h6: baseStyle?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          height: 1.2,
        ),

        // 제목 패딩
        h1Padding: const EdgeInsets.only(top: 16, bottom: 8),
        h2Padding: const EdgeInsets.only(top: 16, bottom: 8),
        h3Padding: const EdgeInsets.only(top: 12, bottom: 6),
        h4Padding: const EdgeInsets.only(top: 12, bottom: 6),
        h5Padding: const EdgeInsets.only(top: 8, bottom: 4),
        h6Padding: const EdgeInsets.only(top: 8, bottom: 4),

        // 리스트
        listBullet: baseStyle?.copyWith(
          color: textColor,
          height: 1.5, // ✅ 줄 간격
        ),
        listIndent: 24,

        // 인용구
        blockquote: baseStyle?.copyWith(
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          fontStyle: FontStyle.italic,
          height: 1.5, // ✅ 줄 간격
        ),
        blockquotePadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        blockquoteDecoration: BoxDecoration(
          color: isDark
              ? AppColors.darkText.withAlpha(13)
              : AppColors.lightText.withAlpha(13),
          borderRadius: BorderRadius.circular(4),
          border: Border(
            left: BorderSide(
              color: isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
              width: 4,
            ),
          ),
        ),

        // 수평선
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
              width: 1,
            ),
          ),
        ),

        // 테이블
        tableBorder: TableBorder.all(
          color: isDark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
          width: 1,
        ),
        tableHead: baseStyle?.copyWith(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        tableBody: baseStyle?.copyWith(color: textColor),
        tableCellsPadding: const EdgeInsets.all(8),

        // 체크박스
        checkbox: baseStyle?.copyWith(color: textColor),

        // 여백
        blockSpacing: 8.0,
        listBulletPadding: const EdgeInsets.only(right: 8),
        // ✅ 추가: 단락 간격
        pPadding: const EdgeInsets.only(bottom: 8),
      ),

      // 링크 탭 핸들러
      onTapLink: (text, href, title) {
        if (href != null && href.isNotEmpty) {
          _launchUrl(context, href);
        }
      },
    );
  }

  /// URL 열기
  Future<void> _launchUrl(BuildContext context, String url) async {
    try {
      Logger.debug('[MarkdownTextWidget] Launching URL: $url');
      final uri = Uri.parse(url);

      // URL 유효성 검사
      if (!uri.hasScheme) {
        Logger.warning('[MarkdownTextWidget] Invalid URL (no scheme): $url');
        if (context.mounted) {
          _showErrorSnackBar(context, 'URL 형식이 올바르지 않습니다.');
        }
        return;
      }

      // URL 열기 시도
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        Logger.debug('[MarkdownTextWidget] URL launched successfully');
      } else {
        Logger.warning('[MarkdownTextWidget] Cannot launch URL: $url');
        if (context.mounted) {
          _showErrorSnackBar(context, '링크를 열 수 없습니다.');
        }
      }
    } catch (e) {
      Logger.error('[MarkdownTextWidget] Error launching URL: $e');
      if (context.mounted) {
        _showErrorSnackBar(context, '링크를 여는 중 오류가 발생했습니다.');
      }
    }
  }

  /// 에러 스낵바 표시
  void _showErrorSnackBar(BuildContext context, String message) {
    CustomSnackBar.showError(context, message);
  }
}
