import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BeamOverlay extends StatelessWidget {
  final Offset? topRightTarget;
  final Offset? bottomLeftTarget;
  final double progress;
  final double fade;

  const BeamOverlay({
    super.key,
    required this.topRightTarget,
    required this.bottomLeftTarget,
    required this.progress,
    required this.fade,
  });

  @override
  Widget build(BuildContext context) {
    if (topRightTarget == null || bottomLeftTarget == null) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: BeamPainter(
          topRightTarget!,
          bottomLeftTarget!,
          progress,
          fade,
        ),
      ),
    );
  }
}

class BeamPainter extends CustomPainter {
  final Offset topRight;
  final Offset bottomLeft;
  final double progress;
  final double fade;

  BeamPainter(
    this.topRight,
    this.bottomLeft,
    this.progress,
    this.fade,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final leftStart = Offset(0, topRight.dy);
    final rightStart = Offset(size.width, bottomLeft.dy);

    final currentLeft =
        Offset.lerp(leftStart, topRight, progress)!;

    final currentRight =
        Offset.lerp(rightStart, bottomLeft, progress)!;

    if (progress <= 0) return;

    /// 🔥 핵심: 전체 잔상 opacity (5~8초 서서히 감소)
    final globalOpacity = (1.0 - fade).clamp(0.0, 1.0);

    /// 꼬리 효과 (빔이 끝쪽으로 갈수록 흐려짐)
    final tailFade = progress > 0.75
        ? ((progress - 0.75) / 0.25).clamp(0.0, 1.0)
        : 0.0;

    //----------------------------------
    // LEFT BEAM
    //----------------------------------

    final leftRect = Rect.fromPoints(leftStart, currentLeft);

    final leftPaint = Paint()
      ..strokeWidth = 4 * globalOpacity   // 🔥 잔상 약해지면 두께도 감소
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          AppColors.border.withOpacity(globalOpacity),
          AppColors.border.withOpacity(globalOpacity),
          AppColors.border.withOpacity(globalOpacity * (1 - tailFade)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.75, 0.92, 1.0],
      ).createShader(leftRect);

    canvas.drawLine(leftStart, currentLeft, leftPaint);

    //----------------------------------
    // RIGHT BEAM
    //----------------------------------

    final rightRect = Rect.fromPoints(currentRight, rightStart);

    final rightPaint = Paint()
      ..strokeWidth = 4 * globalOpacity
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          AppColors.border.withOpacity(globalOpacity),
          AppColors.border.withOpacity(globalOpacity),
          AppColors.border.withOpacity(globalOpacity * (1 - tailFade)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.75, 0.92, 1.0],
      ).createShader(rightRect);

    canvas.drawLine(rightStart, currentRight, rightPaint);
  }

  @override
  bool shouldRepaint(covariant BeamPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.fade != fade ||
        oldDelegate.topRight != topRight ||
        oldDelegate.bottomLeft != bottomLeft;
  }
}