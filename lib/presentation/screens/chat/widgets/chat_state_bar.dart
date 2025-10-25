// lib/presentation/screens/chat/widgets/chat_state_bar.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/token_counter.dart';
import '../../../../domain/providers/database_provider.dart';
import '../../settings/settings_screen.dart';

/// ChatStateBar - SliverAppBar의 flexibleSpace에 사용될 위젯
class ChatStateBar extends ConsumerWidget {
  final int? sessionId;

  const ChatStateBar({super.key, this.sessionId});

  static const _borderRadius = BorderRadius.all(
    Radius.circular(UIConstants.radiusLg),
  );
  static final _blurFilter = ImageFilter.blur(
    sigmaX: UIConstants.glassBlur,
    sigmaY: UIConstants.glassBlur,
  );
  static const _padding = EdgeInsets.symmetric(
    horizontal: UIConstants.spacingMd,
  );
  static const _outerPadding = EdgeInsets.all(UIConstants.spacingXs);
  static const double _appBarHeight = 120.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: _outerPadding,
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: _borderRadius,
          child: BackdropFilter(
            filter: _blurFilter,
            child: SizedBox(
              height: _appBarHeight,
              child: Container(
                decoration: _buildContainerDecoration(context),
                child: Padding(
                  padding: _padding,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ✅ 타이틀 영역 - Flexible로 남은 공간만 차지
                      Expanded(
                        child: _buildTitle(context, ref, sessionId),
                      ),

                      // ✅ 우측 액션들 - 항상 우측 정렬 보장
                      if (sessionId != null) ...[
                        _SessionStatsWidget(sessionId: sessionId!),
                        const SizedBox(width: UIConstants.spacingXs),
                        _RefreshButton(sessionId: sessionId!),
                      ],
                      const _SettingsButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildContainerDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: AppColors.gradient,
      borderRadius: _borderRadius,
      border: Border.all(
        color: Theme.of(context)
            .colorScheme
            .outline
            .withAlpha(UIConstants.alpha20),
        width: 1,
      ),
    );
  }

  Widget _buildTitle(BuildContext context, WidgetRef ref, int? sessionId) {
    if (sessionId == null) {
      return const _TitleLabel(title: 'Vibe Code');
    }

    final sessionsAsync = ref.watch(chatSessionsProvider);

    return sessionsAsync.when(
      data: (sessions) {
        final session = sessions.cast<dynamic>().firstWhere(
              (s) => s.id == sessionId,
          orElse: () => null,
        );

        if (session == null) {
          return const _TitleLabel(title: 'Vibe Code');
        }

        // ✅ 타이틀이 너무 길어도 우측 버튼을 밀지 않도록 제한
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              session.title as String,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              DateFormatter.formatChatTime(session.updatedAt as DateTime),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withAlpha(UIConstants.alpha70),
                fontSize: 10,
                height: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.fade,
            ),
          ],
        );
      },
      loading: () => const _TitleLabel(title: 'Vibe Code'),
      error: (_, __) => const _TitleLabel(title: 'Vibe Code'),
    );
  }
}

/// 단순 타이틀 표시용 위젯
class _TitleLabel extends StatelessWidget {
  final String title;

  const _TitleLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// 세션 통계 위젯
class _SessionStatsWidget extends ConsumerWidget {
  final int sessionId;

  const _SessionStatsWidget({required this.sessionId});

  static const _messageIcon = Icon(
    Icons.message_outlined,
    size: UIConstants.iconSm,
    color: Color(0xE6FFFFFF),
  );

  static const _tokenIcon = Icon(
    Icons.data_usage,
    size: UIConstants.iconSm,
    color: Color(0xE6FFFFFF),
  );

  static const _statsDecoration = BoxDecoration(
    color: Color(0x33FFFFFF),
    borderRadius: BorderRadius.all(Radius.circular(UIConstants.radiusSm)),
  );

  static const _statsPadding = EdgeInsets.symmetric(
    horizontal: UIConstants.spacingSm,
    vertical: UIConstants.spacingXs,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(sessionMessagesProvider(sessionId));

    return messagesAsync.when(
      data: (messages) {
        final messageCount = messages.length;
        final totalTokens = messages.fold<int>(
          0,
              (sum, msg) => sum + TokenCounter.estimateTokens(msg.content),
        );

        return Container(
          padding: _statsPadding,
          decoration: _statsDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _messageIcon,
              const SizedBox(width: 4),
              Text(
                '$messageCount',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: UIConstants.spacingSm),
              _tokenIcon,
              const SizedBox(width: 4),
              Text(
                TokenCounter.formatTokenCount(totalTokens),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// 새로고침 버튼
class _RefreshButton extends ConsumerWidget {
  final int sessionId;

  const _RefreshButton({required this.sessionId});

  static const _refreshIcon = Icon(Icons.refresh, color: Colors.white);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: _refreshIcon,
      iconSize: UIConstants.iconMd,
      tooltip: '새로고침',
      padding: const EdgeInsets.all(UIConstants.spacingXs),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      onPressed: () {
        ref.invalidate(sessionMessagesProvider(sessionId));
        ref.invalidate(chatSessionsProvider);
      },
    );
  }
}

/// 설정 버튼
class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  static const _settingsIcon = Icon(
    Icons.settings_outlined,
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _settingsIcon,
      iconSize: UIConstants.iconMd,
      tooltip: '설정',
      padding: const EdgeInsets.all(UIConstants.spacingXs),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const SettingsScreen(),
          ),
        );
      },
    );
  }
}
