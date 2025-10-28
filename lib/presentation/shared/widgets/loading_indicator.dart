import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/app_colors.dart';

/// 통합 로딩 인디케이터 (그라디언트 적용)
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
              size: size,
              strokeWidth: size > 30 ? 4.0 : 3.0,
            )
                : CircularProgressIndicator(
              strokeWidth: size > 30 ? 4.0 : 3.0,
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
class _GradientCircularProgressIndicator extends StatefulWidget {
  final double size;
  final double strokeWidth;

  const _GradientCircularProgressIndicator({
    required this.size,
    required this.strokeWidth,
  });

  @override
  State<_GradientCircularProgressIndicator> createState() =>
      _GradientCircularProgressIndicatorState();
}

class _GradientCircularProgressIndicatorState
    extends State<_GradientCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _GradientCircularProgressPainter(
            progress: _controller.value,
            strokeWidth: widget.strokeWidth,
          ),
        );
      },
    );
  }
}

/// 그라디언트 원형 진행 표시기 페인터
class _GradientCircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  _GradientCircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 배경 원 (옅은 색)
    final backgroundPaint = Paint()
      ..color = AppColors.primary.withAlpha(UIConstants.alpha15)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 그라디언트 원 (회전)
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      colors: [
        AppColors.gradientStart,
        AppColors.gradientEnd,
        AppColors.gradientStart.withAlpha(UIConstants.alpha50),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 0.75, 1.0],
      transform: GradientRotation(progress * 2 * math.pi),
    );

    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 270도 호 그리기 (3/4 원)
    const startAngle = -math.pi / 2;
    const sweepAngle = 3 * math.pi / 2;
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      gradientPaint,
    );

    // 끝부분 강조 (그라디언트 시작점)
    final endAngle = startAngle + sweepAngle;
    final endPoint = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );

    final endPaint = Paint()
      ..color = AppColors.gradientEnd
      ..strokeWidth = strokeWidth * 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(endPoint, strokeWidth / 3, endPaint);
  }

  @override
  bool shouldRepaint(_GradientCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
