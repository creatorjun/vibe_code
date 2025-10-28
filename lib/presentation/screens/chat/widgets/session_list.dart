import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vibe_code/presentation/shared/widgets/loading_indicator.dart';
import 'package:vibe_code/core/constants/ui_constants.dart';
import 'package:vibe_code/core/theme/app_colors.dart';
import 'package:vibe_code/domain/mutations/create_session_mutation.dart';
import 'package:vibe_code/domain/providers/database_provider.dart';
import 'session_tile.dart';

class SessionList extends ConsumerWidget {
  final bool isExpanded;

  const SessionList({
    super.key,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(chatSessionsProvider);

    return Column(
      children: [
        if (isExpanded) const SectionHeader(),
        Expanded(
          child: sessionsAsync.when(
            data: (sessions) {
              if (sessions.isEmpty) {
                return EmptyState(isExpanded: isExpanded);
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: UIConstants.spacingSm,
                  vertical: UIConstants.spacingXs,
                ),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  return SessionTile(
                    key: ValueKey('session-${sessions[index].id}'),
                    session: sessions[index],
                    isCollapsed: !isExpanded,
                  );
                },
              );
            },
            loading: () => const LoadingState(),
            error: (error, stack) => ErrorState(error: error),
          ),
        ),
        NewChatButton(isExpanded: isExpanded),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacingMd,
        vertical: UIConstants.spacingSm,
      ),
      child: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.clockRotateLeft,
            size: UIConstants.iconSm,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withAlpha(UIConstants.alpha60),
          ),
          const SizedBox(width: UIConstants.spacingSm),
          Text(
            '최근 대화',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withAlpha(UIConstants.alpha70),
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: LoadingIndicator(
        message: '대화 불러오는 중...',
        size: UIConstants.iconLg,
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final Object error;

  const ErrorState({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(UIConstants.spacingLg),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .errorContainer
                    .withAlpha(UIConstants.alpha30),
                shape: BoxShape.circle,
              ),
              child: FaIcon(
                FontAwesomeIcons.triangleExclamation,
                size: UIConstants.iconLg,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: UIConstants.spacingMd),
            Text(
              '오류 발생',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: UIConstants.spacingSm),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(UIConstants.alpha60),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final bool isExpanded;

  const EmptyState({
    super.key,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    if (!isExpanded) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(UIConstants.spacingXl),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withAlpha(UIConstants.alpha30),
                shape: BoxShape.circle,
              ),
              child: FaIcon(
                FontAwesomeIcons.commentDots,
                size: UIConstants.iconLg * 1.5,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(UIConstants.alpha30),
              ),
            ),
            const SizedBox(height: UIConstants.spacingLg),
            Text(
              '대화 내역 없음',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(UIConstants.alpha60),
              ),
            ),
            const SizedBox(height: UIConstants.spacingSm),
            Text(
              'NEW 버튼을 눌러 대화를 시작하세요',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(UIConstants.alpha40),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class NewChatButton extends ConsumerWidget {
  final bool isExpanded;

  const NewChatButton({
    super.key,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.all(
        isExpanded ? UIConstants.spacingMd : UIConstants.spacingSm,
      ),
      child: isExpanded
          ? _buildExpandedButton(context, ref)
          : _buildCollapsedButton(context, ref),
    );
  }

  Widget _buildExpandedButton(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _createNewSession(ref),
        borderRadius: BorderRadius.circular(UIConstants.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(UIConstants.spacingMd),
          decoration: BoxDecoration(
            gradient: AppColors.gradient,
            borderRadius: BorderRadius.circular(UIConstants.radiusMd),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(UIConstants.alpha40),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: FaIcon(
              FontAwesomeIcons.circlePlus,
              color: Colors.white,
              size: UIConstants.iconLg,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedButton(BuildContext context, WidgetRef ref) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _createNewSession(ref),
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(UIConstants.alpha30),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.circlePlus,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _createNewSession(WidgetRef ref) {
    createNewSession(ref);
  }
}
