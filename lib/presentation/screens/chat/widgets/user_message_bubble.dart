// lib/presentation/screens/chat/widgets/user_message_bubble.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibe_code/core/theme/app_colors.dart';
import 'package:vibe_code/core/utils/date_formatter.dart';
import 'package:vibe_code/data/database/app_database.dart';
import 'package:vibe_code/core/constants/ui_constants.dart';

/// 사용자 메시지 버블
class UserMessageBubble extends StatefulWidget {
  final Message message;

  const UserMessageBubble({super.key, required this.message});

  @override
  State<UserMessageBubble> createState() => _UserMessageBubbleState();
}

class _UserMessageBubbleState extends State<UserMessageBubble> {
  bool isExpanded = false;
  bool needsExpansion = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.message.content,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      maxLines: 3,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: UIConstants.messageBubbleMaxWidth - 32);

    needsExpansion = textPainter.didExceedMaxLines;

    return RepaintBoundary(
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: UIConstants.spacingMd,
            vertical: UIConstants.spacingSm,
          ),
          constraints: const BoxConstraints(
            maxWidth: UIConstants.messageBubbleMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(UIConstants.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gradientStart.withAlpha(UIConstants.alpha30),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: UIConstants.spacingMd,
                        vertical: UIConstants.spacingSm,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(UIConstants.alpha20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Creator Jun',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () async {
                              await Clipboard.setData(
                                ClipboardData(text: widget.message.content),
                              );

                              // ✅ 스낵바 표시
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('클립보드에 복사되었습니다'),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: AppColors.primary,
                                    margin: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(UIConstants.radiusSm),
                            child: Padding(
                              padding: const EdgeInsets.all(UIConstants.spacingXs),
                              child: Icon(
                                Icons.copy_all,
                                size: UIConstants.iconSm,
                                color: Colors.white.withAlpha(UIConstants.alpha70),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: UIConstants.spacingMd,
                        vertical: UIConstants.spacingSm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            widget.message.content,
                            maxLines: isExpanded || !needsExpansion ? null : 3,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (needsExpansion) ...[
                            const SizedBox(height: UIConstants.spacingXs),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  isExpanded = !isExpanded;
                                });
                              },
                              borderRadius: BorderRadius.circular(UIConstants.radiusSm),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: UIConstants.spacingXs,
                                  vertical: 2,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isExpanded ? '접기' : '더 보기',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withAlpha(UIConstants.alpha90),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      size: UIConstants.iconSm,
                                      color: Colors.white.withAlpha(UIConstants.alpha90),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: UIConstants.spacingXs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacingXs),
                child: Text(
                  DateFormatter.formatMessageTime(widget.message.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withAlpha(UIConstants.alpha70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}