import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vibe_code/domain/providers/chat_provider.dart';
import 'package:vibe_code/core/constants/ui_constants.dart';
import 'package:vibe_code/core/theme/app_colors.dart';
import 'package:vibe_code/core/utils/date_formatter.dart';
import 'package:vibe_code/domain/providers/database_provider.dart';
import 'package:vibe_code/domain/providers/session_stats_provider.dart';
import '../../settings/settings_screen.dart';
import 'export_dialog.dart';

class ChatStateBar extends ConsumerWidget {
  final int? sessionId;

  const ChatStateBar({
    super.key,
    this.sessionId,
  });

  static const padding = EdgeInsets.symmetric(
    vertical: UIConstants.spacingSm,
    horizontal: UIConstants.spacingMd,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: padding,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacingMd),
        decoration: _buildDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: TitleSection(sessionId: sessionId)),
            if (sessionId != null) ..._buildActionButtons(sessionId!),
            const SettingsButton(),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration() {
    return BoxDecoration(
      gradient: AppColors.gradient,
      borderRadius: BorderRadius.circular(UIConstants.radiusLg),
    );
  }

  List<Widget> _buildActionButtons(int sessionId) {
    return [
      SessionStatsWidget(sessionId: sessionId),
      const SizedBox(width: UIConstants.spacingXs),
      ExportButton(sessionId: sessionId),
      const SizedBox(width: UIConstants.spacingXs),
      const RefreshButton(),
    ];
  }
}

class TitleSection extends ConsumerWidget {
  final int? sessionId;

  const TitleSection({
    super.key,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sessionId == null) {
      return const TitleLabel(title: 'Vibe Code');
    }

    final sessionsAsync = ref.watch(chatSessionsProvider);

    return sessionsAsync.when(
      data: (sessions) {
        final session = sessions.findSessionById(sessionId!);
        return session != null
            ? SessionTitle(session: session)
            : const TitleLabel(title: 'Vibe Code');
      },
      loading: () => const TitleLabel(title: 'Vibe Code'),
      error: (_, __) => const TitleLabel(title: 'Vibe Code'),
    );
  }
}

class SessionTitle extends StatelessWidget {
  final dynamic session;

  const SessionTitle({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          session.title as String,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: UIConstants.spacingXs),
        Text(
          DateFormatter.formatChatTime(session.updatedAt as DateTime),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withAlpha(UIConstants.alpha80),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class TitleLabel extends StatelessWidget {
  final String title;

  const TitleLabel({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class SessionStatsWidget extends ConsumerWidget {
  final int sessionId;

  const SessionStatsWidget({
    super.key,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(activeSessionStatsProvider);

    return statsAsync.when(
      data: (stats) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: UIConstants.spacingSm,
          vertical: UIConstants.spacingXs,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(UIConstants.radiusMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatItem(
              icon: FontAwesomeIcons.message,
              value: '${stats.messageCount}',
            ),
            const SizedBox(width: UIConstants.spacingMd),
            StatItem(
              icon: FontAwesomeIcons.coins,
              value: stats.tokenDisplay,
            ),
          ],
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class StatItem extends StatelessWidget {
  final IconData icon;
  final String value;

  const StatItem({
    super.key,
    required this.icon,
    required this.value,
  });

  static const textStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    letterSpacing: 0.5,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FaIcon(
          icon,
          size: UIConstants.iconSm,
          color: Colors.white.withAlpha(UIConstants.alpha90),
        ),
        const SizedBox(width: UIConstants.spacingXs),
        Text(value, style: textStyle),
      ],
    );
  }
}

class ExportButton extends ConsumerWidget {
  final int sessionId;

  const ExportButton({
    super.key,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const FaIcon(FontAwesomeIcons.download),
      color: Colors.white,
      iconSize: UIConstants.iconSm,
      tooltip: '대화 내보내기',
      padding: const EdgeInsets.all(UIConstants.spacingXs),
      onPressed: () => _handleExport(context, ref),
    );
  }

  Future<void> _handleExport(BuildContext context, WidgetRef ref) async {
    final sessionsAsync = ref.read(chatSessionsProvider);
    final messagesAsync = ref.read(sessionMessagesProvider(sessionId));

    await sessionsAsync.when(
      data: (sessions) async {
        final session = sessions.findSessionById(sessionId);
        if (session != null) {
          await messagesAsync.when(
            data: (messages) {
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) => ExportDialog(
                    session: session,
                    messages: messages,
                  ),
                );
              }
            },
            loading: () {},
            error: (_, __) {},
          );
        }
      },
      loading: () {},
      error: (_, __) {},
    );
  }
}

class RefreshButton extends ConsumerWidget {
  const RefreshButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionId = ref.watch(activeSessionProvider);
    if (sessionId == null) return const SizedBox.shrink();

    return IconButton(
      icon: const FaIcon(FontAwesomeIcons.arrowsRotate),
      color: Colors.white,
      iconSize: UIConstants.iconSm,
      tooltip: '새로고침',
      padding: const EdgeInsets.all(UIConstants.spacingXs),
      onPressed: () {
        ref.invalidate(sessionMessagesProvider(sessionId));
        ref.invalidate(chatSessionsProvider);
      },
    );
  }
}

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const FaIcon(FontAwesomeIcons.gear),
      color: Colors.white,
      iconSize: UIConstants.iconSm,
      tooltip: '설정',
      padding: const EdgeInsets.all(UIConstants.spacingXs),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
      },
    );
  }
}

extension SessionListExtension on List<dynamic> {
  dynamic findSessionById(int id) {
    try {
      return cast<dynamic>().firstWhere(
            (s) => s.id == id,
        orElse: () => null,
      );
    } catch (_) {
      return null;
    }
  }
}
