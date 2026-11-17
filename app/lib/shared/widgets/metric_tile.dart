import 'package:flutter/material.dart';
import 'package:obd_core/obd_core.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/sensor_meta.dart';
import '../../core/units.dart';
import '../../features/live/live_data.dart';
import 'app_card.dart';
import 'sparkline.dart';

/// Live value tile: plain label, big tabular number, status word or mini bar,
/// and a sparkline of the last minute.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.sensor,
    required this.units,
    required this.value,
    required this.history,
    required this.stale,
    this.status,
    this.onTap,
    this.window = const Duration(seconds: 90),
  });

  final Sensor sensor;
  final Units units;
  final double? value;
  final List<TimedValue> history;
  final bool stale;

  /// Plain status word + color, e.g. ("Normal", good).
  final (String, Color)? status;
  final VoidCallback? onTap;
  final Duration window;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final text = sensorText(l, sensor);
    final v = value;
    final display = v == null ? '–' : units.format(sensor, v);
    final unit = units.unitOf(sensor);
    final now = DateTime.now();
    final converted = [for (final p in history) TimedValue(p.t, units.value(sensor, p.v))];

    return AnimatedOpacity(
      opacity: stale && v != null ? 0.45 : 1,
      duration: const Duration(milliseconds: 200),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        semanticLabel: '${text.label}, $display $unit',
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(sensorIcon(sensor), size: 16, color: c.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      text.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelMedium?.copyWith(height: 1.15),
                    ),
                  ),
                  Icon(Icons.info_outline_rounded, size: 15, color: c.textMuted),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(display, style: context.text.displaySmall?.copyWith(fontFeatures: tabular)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(unit, style: context.text.labelMedium),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 22,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: status != null
                      ? ToneChip(label: status!.$1, color: status!.$2, dense: true)
                      : isPercentLike(sensor) && v != null
                          ? _MiniBar(fraction: (v / 100).clamp(0, 1))
                          : const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 4),
              Sparkline(
                points: converted,
                from: adaptiveFrom(history, now, window, const Duration(seconds: 20)),
                to: now,
                height: 30,
                maxGap: const Duration(seconds: 15),
                minRange: _minRange(sensor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static double _minRange(Sensor s) => switch (s.unit) {
        SensorUnit.percent => 10,
        SensorUnit.celsius => 6,
        SensorUnit.volts => s.max > 2 ? 0.6 : 0.2,
        SensorUnit.rpm => 400,
        SensorUnit.kmh => 10,
        _ => 0,
      };
}

/// Start of a live window: grows with the session up to [window], never
/// shorter than [min], so early data isn't squeezed against the edge.
DateTime adaptiveFrom(List<TimedValue> points, DateTime now, Duration window, Duration min) {
  final full = now.subtract(window);
  if (points.isEmpty) return now.subtract(min);
  final first = points.first.t;
  if (first.isBefore(full)) return full;
  final floor = now.subtract(min);
  return first.isAfter(floor) ? floor : first;
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.fraction});
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 6,
        width: 88,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: c.surfaceRaised)),
            FractionallySizedBox(
              widthFactor: fraction,
              heightFactor: 1,
              alignment: AlignmentDirectional.centerStart,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [c.accent, c.accentGlow]),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
