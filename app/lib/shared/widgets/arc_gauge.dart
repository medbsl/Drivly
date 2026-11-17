import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';

/// 270° arc gauge. The number dominates; the arc is secondary.
/// Fills clockwise in every locale (never mirrored in RTL).
class ArcGauge extends StatelessWidget {
  const ArcGauge({
    super.key,
    required this.value,
    required this.max,
    required this.label,
    required this.unit,
    required this.display,
    this.stale = false,
    this.redlineFrom,
  });

  final double? value;
  final double max;
  final String label;
  final String unit;

  /// Formatted number shown in the middle.
  final String display;
  final bool stale;

  /// Fraction (0–1) where the warning zone starts, e.g. engine redline.
  final double? redlineFrom;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final target = ((value ?? 0) / max).clamp(0.0, 1.0);
    return Semantics(
      label: '$label, $display $unit',
      child: AnimatedOpacity(
        opacity: stale ? 0.4 : 1,
        duration: const Duration(milliseconds: 200),
        child: AspectRatio(
          aspectRatio: 1,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: target),
            duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => CustomPaint(
              painter: _ArcPainter(fraction: t, colors: c, redlineFrom: redlineFrom),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30, 26, 30, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            value == null ? '–' : display,
                            style: context.text.displayLarge?.copyWith(fontFeatures: tabular),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(unit, style: context.text.labelMedium),
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
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.fraction, required this.colors, this.redlineFrom});

  final double fraction;
  final DrivlyColors colors;
  final double? redlineFrom;

  static const _start = 135 * pi / 180;
  static const _sweep = 270 * pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.07;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2 - stroke / 2 - 6);

    // Ticks.
    final tick = Paint()
      ..color = colors.textMuted.withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final c = rect.center;
    final r = rect.width / 2;
    for (var i = 0; i <= 40; i++) {
      final a = _start + _sweep * i / 40;
      final major = i % 10 == 0;
      final inner = r - stroke / 2 - (major ? 9 : 5);
      final outer = r - stroke / 2 - 3;
      tick.strokeWidth = major ? 1.8 : 1;
      canvas.drawLine(c + Offset(cos(a), sin(a)) * inner, c + Offset(cos(a), sin(a)) * outer, tick);
    }

    // Track.
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = colors.surfaceRaised;
    canvas.drawArc(rect, _start, _sweep, false, track);

    final red = redlineFrom;
    if (red != null) {
      canvas.drawArc(
        rect,
        _start + _sweep * red,
        _sweep * (1 - red),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = colors.danger.withValues(alpha: 0.18),
      );
    }

    if (fraction <= 0.001) return;
    final shader = SweepGradient(
      startAngle: _start,
      endAngle: _start + _sweep,
      colors: [colors.accent, colors.accentGlow],
      transform: const GradientRotation(0),
    ).createShader(rect);

    // Soft glow under the value arc.
    canvas.drawArc(
      rect,
      _start,
      _sweep * fraction,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 1.6
        ..strokeCap = StrokeCap.round
        ..shader = shader
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 0.9)
        ..color = colors.accent.withValues(alpha: 0.5),
    );
    canvas.drawArc(
      rect,
      _start,
      _sweep * fraction,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = shader,
    );

    // Bright head.
    final a = _start + _sweep * fraction;
    canvas.drawCircle(c + Offset(cos(a), sin(a)) * r, stroke * 0.32, Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.fraction != fraction || old.colors != colors || old.redlineFrom != redlineFrom;
}
