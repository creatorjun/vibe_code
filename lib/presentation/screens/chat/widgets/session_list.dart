// lib/presentation/screens/chat/widgets/session_list.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/mutations/create_session_mutation.dart';
import '../../../../domain/providers/database_provider.dart';
import '../../../shared/widgets/adaptive_loading.dart';
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
        // ✅ NEW 버튼 - 독립적으로 최적화
        _NewChatButton(isExpanded: isExpanded),

        // ✅ 대화 목록 헤더 - 상수 위젯으로 최적화
        if (isExpanded) const _SectionHeader(),

        // ✅ 세션 리스트
        Expanded(
          child: sessionsAsync.when(
            data: (sessions) {
              if (sessions.isEmpty) {
                return _EmptyState(isExpanded: isExpanded);
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
            loading: () => const _LoadingState(),
            error: (error, stack) => _ErrorState(error: error),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// ✅ 최적화: 독립적인 위젯으로 분리하여 불필요한 리빌드 방지
// ============================================================================

/// NEW 버튼 - 독립 위젯
class _NewChatButton extends ConsumerWidget {
  final bool isExpanded;

  const _NewChatButton({required this.isExpanded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(UIConstants.spacingSm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => createNewSession(ref, '새로운 대화'),
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
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.circlePlus,
                color: Colors.white,
                size: isExpanded ? UIConstants.iconLg : UIConstants.iconSm,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 대화 목록 헤더 - 상수 위젯
class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

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
            '대화 목록',
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

/// 로딩 상태 - 상수 위젯
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: AdaptiveLoading(
        message: '...',
        size: UIConstants.iconLg,
      ),
    );
  }
}

/// 에러 상태 - 독립 위젯
class _ErrorState extends StatelessWidget {
  final Object error;

  const _ErrorState({required this.error});

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

/// 빈 상태 - 독립 위젯
class _EmptyState extends StatelessWidget {
  final bool isExpanded;

  const _EmptyState({required this.isExpanded});

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
              '대화가 없습니다',
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
              'NEW 버튼을 눌러\n새로운 대화를 시작하세요',
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
