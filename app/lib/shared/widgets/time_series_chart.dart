import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';

/// One point of a time series. [lo]/[hi] give the min–max band of an
/// aggregated bucket (null for raw live samples).
class ChartPoint {
  const ChartPoint(this.t, this.v, {this.lo, this.hi});
  final DateTime t;
  final double v;
  final double? lo;
  final double? hi;
}

/// Single-series time chart: 2px accent line, gradient area, faint min–max
/// band, recessive grid, crosshair + tooltip. One axis, always.
class TimeSeriesChart extends StatelessWidget {
  const TimeSeriesChart({
    super.key,
    required this.points,
    required this.from,
    required this.to,
    required this.formatValue,
    this.height = 220,
    this.gapThreshold,
    this.minYRange,
    this.zeroBased = false,
    this.animate = true,
  });

  final List<ChartPoint> points;
  final DateTime from;
  final DateTime to;

  /// Formats a value for axis labels and tooltip (already in display units).
  final String Function(double v) formatValue;
  final double height;

  /// Consecutive points further apart than this are not connected.
  final Duration? gapThreshold;
  final double? minYRange;
  final bool zeroBased;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(child: Text('—', style: context.text.bodyMedium)),
      );
    }

    final x0 = from.millisecondsSinceEpoch.toDouble();
    final x1 = max(to.millisecondsSinceEpoch.toDouble(), x0 + 1000);
    var lo = double.infinity;
    var hi = -double.infinity;
    for (final p in points) {
      lo = min(lo, p.lo ?? p.v);
      hi = max(hi, p.hi ?? p.v);
    }
    if (zeroBased && lo > 0) lo = 0;
    final need = minYRange ?? 0;
    if (hi - lo < need) {
      final mid = (hi + lo) / 2;
      lo = zeroBased ? max(0, mid - need / 2) : mid - need / 2;
      hi = lo + need;
    }
    if (hi - lo < 1e-6) {
      hi += 1;
      lo -= 1;
    }
    final pad = (hi - lo) * 0.08;
    final minY = zeroBased && lo >= 0 ? lo : lo - pad;
    final maxY = hi + pad;

    final avg = <FlSpot>[];
    final bandLo = <FlSpot>[];
    final bandHi = <FlSpot>[];
    final hasBand = points.any((p) => p.lo != null && p.hi != null && p.hi! - p.lo! > 1e-9);
    DateTime? prev;
    for (final p in points) {
      if (prev != null && gapThreshold != null && p.t.difference(prev) > gapThreshold!) {
        avg.add(FlSpot.nullSpot);
        bandLo.add(FlSpot.nullSpot);
        bandHi.add(FlSpot.nullSpot);
      }
      final x = p.t.millisecondsSinceEpoch.toDouble();
      avg.add(FlSpot(x, p.v));
      bandLo.add(FlSpot(x, p.lo ?? p.v));
      bandHi.add(FlSpot(x, p.hi ?? p.v));
      prev = p.t;
    }

    // Buckets with no neighbour (a short drive on its own day) can't form a
    // line: draw them as a dot with a min–max whisker instead.
    final isolatedX = <double>{};
    final whiskers = <LineChartBarData>[];
    for (var i = 0; i < points.length; i++) {
      final g = gapThreshold;
      final gapBefore = i == 0 || (g != null && points[i].t.difference(points[i - 1].t) > g);
      final gapAfter = i == points.length - 1 || (g != null && points[i + 1].t.difference(points[i].t) > g);
      if (!(gapBefore && gapAfter)) continue;
      final p = points[i];
      final x = p.t.millisecondsSinceEpoch.toDouble();
      isolatedX.add(x);
      if (p.lo != null && p.hi != null && p.hi! - p.lo! > 1e-9) {
        whiskers.add(LineChartBarData(
          spots: [FlSpot(x, p.lo!), FlSpot(x, p.hi!)],
          color: c.accent.withValues(alpha: 0.4),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
        ));
      }
    }

    final spanMs = x1 - x0;
    final timeFmt = spanMs <= 10 * 60 * 1000 ? DateFormat.Hms() : (spanMs <= 36 * 3600 * 1000 ? DateFormat.Hm() : DateFormat.MMMd());
    final tipFmt = spanMs <= 2 * 3600 * 1000 ? DateFormat.Hms() : DateFormat.MMMd().add_Hm();
    final yInterval = _niceStep((maxY - minY) / 4);
    final xInterval = spanMs / 4;

    LineChartBarData invisible(List<FlSpot> s) => LineChartBarData(
          spots: s,
          isCurved: false,
          color: Colors.transparent,
          barWidth: 0,
          dotData: const FlDotData(show: false),
        );

    final main = LineChartBarData(
      spots: avg,
      isCurved: points.length < 400,
      curveSmoothness: 0.18,
      preventCurveOverShooting: true,
      color: c.accent,
      barWidth: 2,
      isStrokeCapRound: true,
      isStrokeJoinRound: true,
      dotData: FlDotData(
        show: isolatedX.isNotEmpty,
        checkToShowDot: (spot, _) => isolatedX.contains(spot.x),
        getDotPainter: (_, _, _, _) => FlDotCirclePainter(radius: 3.5, color: c.accent, strokeWidth: 1.5, strokeColor: c.surface),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.accent.withValues(alpha: 0.22), c.accent.withValues(alpha: 0.0)],
        ),
      ),
    );

    final mainIndex = (hasBand ? 2 : 0) + whiskers.length;
    final labelStyle = TextStyle(color: c.textMuted, fontSize: 11, fontFeatures: tabular);
    return SizedBox(
      height: height,
      child: LineChart(
        duration: animate && !context.reduceMotion ? const Duration(milliseconds: 250) : Duration.zero,
        LineChartData(
          minX: x0,
          maxX: x1,
          minY: minY,
          maxY: maxY,
          clipData: const FlClipData.all(),
          lineBarsData: [
            if (hasBand) invisible(bandLo),
            if (hasBand) invisible(bandHi),
            ...whiskers,
            main,
          ],
          betweenBarsData: hasBand ? [BetweenBarsData(fromIndex: 0, toIndex: 1, color: c.accent.withValues(alpha: 0.12))] : const [],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (_) => FlLine(color: c.chartGrid, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: yInterval,
                getTitlesWidget: (v, meta) {
                  if (v == meta.max || v == meta.min) return const SizedBox.shrink();
                  return SideTitleWidget(meta: meta, space: 6, child: Text(formatValue(v), style: labelStyle));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: xInterval,
                getTitlesWidget: (v, meta) {
                  if (v == meta.min || v == meta.max) return const SizedBox.shrink();
                  final t = DateTime.fromMillisecondsSinceEpoch(v.round());
                  return SideTitleWidget(meta: meta, space: 6, child: Text(timeFmt.format(t), style: labelStyle));
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchSpotThreshold: 40,
            getTouchedSpotIndicator: (bar, idx) => idx
                .map((_) => bar.barWidth != 2 // only the main line (2px) gets a crosshair
                    ? null
                    : TouchedSpotIndicatorData(
                        FlLine(color: c.textSecondary.withValues(alpha: 0.5), strokeWidth: 1, dashArray: [3, 3]),
                        FlDotData(
                          getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                            radius: 5,
                            color: c.accent,
                            strokeWidth: 2,
                            strokeColor: c.surface,
                          ),
                        ),
                      ))
                .toList(),
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => c.surfaceRaised,
              tooltipBorder: BorderSide(color: c.outline),
              tooltipBorderRadius: BorderRadius.circular(12),
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              maxContentWidth: 180,
              getTooltipItems: (spots) => spots.map((s) {
                if (s.barIndex != mainIndex) return null;
                final t = DateTime.fromMillisecondsSinceEpoch(s.x.round());
                final p = _nearest(points, t);
                final range = p?.lo != null && p?.hi != null && (p!.hi! - p.lo!) > 1e-9
                    ? '\n${formatValue(p.lo!)} – ${formatValue(p.hi!)}'
                    : '';
                return LineTooltipItem(
                  formatValue(s.y),
                  TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700, fontSize: 15, fontFeatures: tabular),
                  children: [
                    TextSpan(
                      text: '$range\n${tipFmt.format(t)}',
                      style: TextStyle(color: c.textSecondary, fontWeight: FontWeight.w500, fontSize: 12, fontFeatures: tabular),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  static ChartPoint? _nearest(List<ChartPoint> pts, DateTime t) {
    ChartPoint? best;
    var bestD = 1 << 62;
    for (final p in pts) {
      final d = (p.t.millisecondsSinceEpoch - t.millisecondsSinceEpoch).abs();
      if (d < bestD) {
        bestD = d;
        best = p;
      }
    }
    return best;
  }

  static double _niceStep(double raw) {
    if (raw <= 0 || raw.isNaN) return 1;
    final exp = pow(10, (log(raw) / ln10).floor()).toDouble();
    final f = raw / exp;
    final nice = f < 1.5 ? 1 : (f < 3 ? 2 : (f < 7 ? 5 : 10));
    return nice * exp;
  }
}
