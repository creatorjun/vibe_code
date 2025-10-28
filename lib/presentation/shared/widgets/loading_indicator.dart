import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/app_colors.dart';

/// 통합 로딩 인디케이터 (기존 LoadingIndicator + AdaptiveLoading 통합)
class LoadingIndicator extends ConsumerWidget {
  final String? message;
  final double size;
  final bool useGradient;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 40.0,
    this.useGradient = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: useGradient
                ? _GradientCircularProgressIndicator(
              strokeWidth: size > 30 ? 3 : 2,
            )
                : CircularProgressIndicator(
              strokeWidth: size > 30 ? 3 : 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: size > 30 ? 16 : 12),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(UIConstants.alpha70),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// 그라디언트 CircularProgressIndicator
class _GradientCircularProgressIndicator extends StatelessWidget {
  final double strokeWidth;

  const _GradientCircularProgressIndicator({
    this.strokeWidth = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 배경 원 (옅은 색)
        CircularProgressIndicator(
          strokeWidth: strokeWidth,
          value: 1.0,
          valueColor: AlwaysStoppedAnimation<Color>(
            AppColors.primary.withAlpha(UIConstants.alpha20),
          ),
        ),
        // 그라디언트 효과를 위한 애니메이션 원
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1500),
          builder: (context, value, child) {
            return CircularProgressIndicator(
              strokeWidth: strokeWidth,
              value: null, // 무한 회전
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            );
          },
          onEnd: () {
            // 애니메이션 반복을 위한 트릭 (실제로는 무한 회전이므로 필요없음)
          },
        ),
      ],
    );
  }
}
