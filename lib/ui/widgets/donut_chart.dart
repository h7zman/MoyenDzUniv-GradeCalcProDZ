import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/grade_formatters.dart';

class DonutChart extends StatefulWidget {
  const DonutChart({
    super.key,
    required this.score,
    required this.maxScore,
    this.size = 188,
    this.thickness = 20,
  });

  final double score;
  final double maxScore;
  final double size;
  final double thickness;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  double _startProgress = 0;
  double _targetProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _targetProgress = _computeProgress(widget.score, widget.maxScore);
    _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant DonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _computeProgress(widget.score, widget.maxScore);
    if ((next - _targetProgress).abs() < 0.0001) return;

    _startProgress = _currentProgress;
    _targetProgress = next;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _computeProgress(double score, double maxScore) {
    if (maxScore <= 0) return 0;
    return (score.clamp(0, maxScore) / maxScore).toDouble();
  }

  double get _currentProgress =>
      _startProgress + (_targetProgress - _startProgress) * _curve.value;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final safeMax = widget.maxScore <= 0 ? 20.0 : widget.maxScore;
    final primaryText = theme.colorScheme.onSurface;
    final secondaryText = tokens.textMuted;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, _) {
          final progress = _currentProgress.clamp(0.0, 1.0).toDouble();
          final scoreText = formatGrade(
            widget.score.clamp(0, safeMax).toDouble(),
          );
          final maxText = formatGrade(safeMax);

          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _DonutPainter(
                  progress: progress,
                  thickness: widget.thickness,
                  activeColor: tokens.accent,
                  activeColorEnd: tokens.accent.withValues(alpha: 0.78),
                  inactiveColor: tokens.chip.withValues(alpha: 0.9),
                ),
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.all(widget.thickness + 6),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'AVERAGE:',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: tokens.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            text: scoreText,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: primaryText,
                            ),
                            children: [
                              TextSpan(
                                text: '/$maxText',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.progress,
    required this.thickness,
    required this.activeColor,
    required this.activeColorEnd,
    required this.inactiveColor,
  });

  final double progress;
  final double thickness;
  final Color activeColor;
  final Color activeColorEnd;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - thickness) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = thickness;

    canvas.drawCircle(center, radius, trackPaint);

    final start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;

    final activePaint = Paint()
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: start + 2 * math.pi,
        stops: const [0.0, 0.7, 1.0],
        colors: [activeColor, activeColor, activeColorEnd],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = thickness;

    canvas.drawArc(rect, start, sweep, false, activePaint);

    if (progress > 0.001) {
      final endAngle = start + sweep;
      final capCenter = Offset(
        center.dx + math.cos(endAngle) * radius,
        center.dy + math.sin(endAngle) * radius,
      );

      final capPaint = Paint()..color = activeColor.withValues(alpha: 0.25);
      canvas.drawCircle(capCenter, thickness * 0.72, capPaint);
      canvas.drawCircle(
        capCenter,
        thickness * 0.38,
        Paint()..color = activeColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.thickness != thickness ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.activeColorEnd != activeColorEnd ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
