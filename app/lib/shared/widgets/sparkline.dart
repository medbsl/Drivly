import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../../features/live/live_data.dart';

/// Tiny time-scaled line with a fading fill. Used in metric tiles and the
/// History overview. Gaps longer than [maxGap] break the line.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.points,
    required this.from,
    required this.to,
    this.height = 36,
    this.maxGap,
    this.minRange,
  });

  final List<TimedValue> points;
  final DateTime from;
  final DateTime to;
  final double height;
  final Duration? maxGap;

  /// Smallest y-range drawn, so a flat noisy signal doesn't look dramatic.
  final double? minRange;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _SparkPainter(points, from, to, context.colors, maxGap, minRange),
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.points, this.from, this.to, this.colors, this.maxGap, this.minRange);

  final List<TimedValue> points;
  final DateTime from;
  final DateTime to;
  final DrivlyColors colors;
  final Duration? maxGap;
  final double? minRange;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    var lo = double.infinity;
    var hi = -double.infinity;
    for (final p in points) {
      if (p.v < lo) lo = p.v;
      if (p.v > hi) hi = p.v;
    }
    final need = minRange ?? 0;
    if (hi - lo < need) {
      final mid = (hi + lo) / 2;
      lo = mid - need / 2;
      hi = mid + need / 2;
    }
    if (hi - lo < 1e-9) {
      lo -= 1;
      hi += 1;
    }
    final span = to.difference(from).inMilliseconds.toDouble();
    if (span <= 0) return;
    const pad = 3.0;
    Offset at(TimedValue p) => Offset(
          (p.t.difference(from).inMilliseconds / span).clamp(0.0, 1.0) * size.width,
          pad + (1 - (p.v - lo) / (hi - lo)) * (size.height - pad * 2),
        );

    final segments = <List<Offset>>[[]];
    TimedValue? prev;
    for (final p in points) {
      if (prev != null && maxGap != null && p.t.difference(prev.t) > maxGap!) segments.add([]);
      segments.last.add(at(p));
      prev = p;
    }

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = colors.accent;
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [colors.accent.withValues(alpha: 0.28), colors.accent.withValues(alpha: 0)],
      ).createShader(Offset.zero & size);

    for (final seg in segments) {
      if (seg.length < 2) continue;
      final path = Path()..moveTo(seg.first.dx, seg.first.dy);
      for (final o in seg.skip(1)) {
        path.lineTo(o.dx, o.dy);
      }
      final area = Path.from(path)
        ..lineTo(seg.last.dx, size.height)
        ..lineTo(seg.first.dx, size.height)
        ..close();
      canvas.drawPath(area, fill);
      canvas.drawPath(path, line);
    }
    final last = segments.last.isEmpty ? null : segments.last.last;
    if (last != null) {
      canvas.drawCircle(last, 3.5, Paint()..color = colors.accent);
      canvas.drawCircle(last, 1.6, Paint()..color = colors.surface);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.points != points || old.from != from || old.to != to || old.colors != colors;
}
