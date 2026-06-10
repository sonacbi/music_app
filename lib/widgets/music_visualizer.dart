import 'dart:math';
import 'package:flutter/material.dart';

enum TransportState { play, pause, stop }

class MusicVisualizer extends StatefulWidget {
  final TransportState state;
  final bool disabled;

  const MusicVisualizer({
    super.key,
    required this.state,
    this.disabled = false,
  });

  @override
  State<MusicVisualizer> createState() => _MusicVisualizerState();
}

class _MusicVisualizerState extends State<MusicVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final int barCount = 40;

  late final List<double> _values;
  late final List<double> _velocity;
  late final List<double> _phases;

  @override
  void initState() {
    super.initState();

    _values = List.generate(barCount, (_) => 0.0);
    _velocity = List.generate(barCount, (_) => 0.0);

    // 🔥 bar마다 고정 phase (핵심)
    _phases = List.generate(barCount, (i) => i * 0.37);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _noise(int i, double t) {
    final n = sin(i * 12.9898 + t * 6.0) * 43758.5453;
    return n - n.floor();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return CustomPaint(
              painter: _WavePainter(
                t: _controller.value,
                values: _values,
                velocity: _velocity,
                phases: _phases,
                barCount: barCount,
                state: widget.state,
                disabled: widget.disabled,
              ),
              size: Size(
                constraints.maxWidth,
                constraints.maxHeight.isFinite ? constraints.maxHeight : 80,
              ),
            );
          },
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double t;
  final List<double> values;
  final List<double> velocity;
  final List<double> phases;
  final int barCount;
  final TransportState state;
  final bool disabled;

  _WavePainter({
    required this.t,
    required this.values,
    required this.velocity,
    required this.phases,
    required this.barCount,
    required this.state,
    required this.disabled,
  });

  double _noise(int i, double t) {
    final n = sin(i * 12.9898 + t * 6.0) * 43758.5453;
    return n - n.floor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (disabled) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: "NOT CONNECTED",
        style: TextStyle(
          color: Colors.white38,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

    return; // 여기서 그래프 완전 차단
  }
    final time = DateTime.now().millisecondsSinceEpoch * 0.001;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / barCount;
    final centerY = size.height / 2;

    final bool showPulse = state == TransportState.play;

    if (showPulse) {
      final beat = sin(time * 2.2) * 0.5 + 0.5;
      final pulseRadius = beat * 35;

      final pulsePaint = Paint()
        ..color = Colors.white.withOpacity(0.06)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.width / 2, centerY),
        pulseRadius,
        pulsePaint,
      );
    }

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;

      double target;

      if (state == TransportState.play) {
        final fast = sin(i * 2.5 + time * 3.5);
        final micro = sin(i * 6.0 + time * 6.0);
        final noise = _noise(i, time * 0.6);

        final jitter = (fast * 0.5 + micro * 0.3 + noise * 0.2);

        final env = sin(time * 0.45 + phases[i]) * 0.5 + 0.5;

        target = (jitter * 0.6 + env * 0.4).abs();
      } else if (state == TransportState.pause) {
        target = 0.02 + sin(i * 0.4 + time * 2.0) * 0.015;
      } else {
        target = 0.0;
      }

      // 🔥 속도 살짝 증가 (반응 개선)
      const spring = 0.12;
      const damping = 0.92;

      velocity[i] += (target - values[i]) * spring;
      velocity[i] *= damping;
      values[i] += velocity[i];

      values[i] = values[i].clamp(0.0, 1.0);

      // 🔥 중앙 강조 (부드러운 bass zone)
      final distFromCenter = (i - barCount / 2).abs();
      final bassFactor = 1.0 + (1.0 - distFromCenter / (barCount / 2)) * 0.5;

      final barHeight =
          (size.height * 0.02 + values[i] * size.height * 0.92) * bassFactor;

      // glow
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        glowPaint,
      );

      // main
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
