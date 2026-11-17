import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:obd_core/obd_core.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/sensor_meta.dart';
import '../../core/units.dart';
import '../../shared/widgets/states.dart';
import '../../shared/widgets/time_series_chart.dart';
import '../history/history_controller.dart';
import '../live/live_data.dart';

Future<void> showSensorSheet(BuildContext context, Sensor sensor) =>
    showAppSheet<void>(context, builder: (_) => SensorDetailSheet(sensor: sensor));

/// The (i) sheet: explanation + a real-time chart of the last minutes.
class SensorDetailSheet extends ConsumerStatefulWidget {
  const SensorDetailSheet({super.key, required this.sensor});
  final Sensor sensor;

  @override
  ConsumerState<SensorDetailSheet> createState() => _SensorDetailSheetState();
}

class _SensorDetailSheetState extends ConsumerState<SensorDetailSheet> {
  Duration _window = const Duration(minutes: 2);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final s = widget.sensor;
    final units = ref.watch(unitsProvider);
    final live = ref.watch(liveDataProvider);
    final text = sensorText(l, s);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scroll) => ListenableBuilder(
        listenable: live,
        builder: (context, _) {
          final now = DateTime.now();
          final pts = live.recent(s, _window);
          final values = pts.map((p) => units.value(s, p.v)).toList();
          final v = live.value(s);
          final at = live.at(s);
          final age = at == null ? null : now.difference(at);
          return ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
            children: [
              Row(
                children: [
                  Icon(sensorIcon(s), color: c.accent),
                  const SizedBox(width: Space.s),
                  Expanded(child: Text(text.label, style: context.text.titleLarge)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                s.pid == null ? s.name : '${s.name} · PID ${s.pid!.toRadixString(16).padLeft(2, '0').toUpperCase()}',
                style: context.text.bodySmall,
              ),
              const SizedBox(height: Space.l),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(v == null ? '–' : units.format(s, v), style: context.text.displayMedium?.copyWith(fontFeatures: tabular)),
                  const SizedBox(width: 6),
                  Text(units.unitOf(s), style: context.text.titleMedium?.copyWith(color: c.textSecondary)),
                  const Spacer(),
                  if (age != null && live.isStale(s))
                    Text(l.lastUpdated(formatDuration(age)), style: context.text.bodySmall)
                  else if (v != null)
                    _LiveDot(color: c.good, label: l.live),
                ],
              ),
              const SizedBox(height: Space.l),
              SegmentedButton<Duration>(
                segments: [
                  ButtonSegment(value: const Duration(minutes: 1), label: Text(l.minutes(1))),
                  ButtonSegment(value: const Duration(minutes: 2), label: Text(l.minutes(2))),
                  ButtonSegment(value: const Duration(minutes: 5), label: Text(l.minutes(5))),
                  ButtonSegment(value: const Duration(minutes: 15), label: Text(l.minutes(15))),
                ],
                selected: {_window},
                onSelectionChanged: (sel) => setState(() => _window = sel.first),
              ),
              const SizedBox(height: Space.l),
              TimeSeriesChart(
                points: [for (final p in pts) ChartPoint(p.t, units.value(s, p.v))],
                from: now.subtract(_window),
                to: now,
                height: 220,
                animate: false,
                gapThreshold: const Duration(seconds: 15),
                minYRange: _minRange(s),
                formatValue: (x) => Units.number(x, s.decimals),
              ),
              const SizedBox(height: Space.l),
              if (values.isNotEmpty)
                Row(
                  children: [
                    _Stat(label: l.statMin, value: Units.number(values.reduce(min), s.decimals)),
                    _Stat(label: l.statAvg, value: Units.number(values.reduce((a, b) => a + b) / values.length, s.decimals)),
                    _Stat(label: l.statMax, value: Units.number(values.reduce(max), s.decimals)),
                  ],
                ),
              const SizedBox(height: Space.xl),
              Text(l.whatItMeans, style: context.text.titleSmall),
              const SizedBox(height: Space.s),
              Text(text.info, style: context.text.bodyLarge),
              if (s == Sensors.coolant || s == Sensors.battery) ...[
                const SizedBox(height: Space.m),
                Text(s == Sensors.coolant ? l.coolantGuidance : l.batteryGuidance, style: context.text.bodyMedium),
              ],
              const SizedBox(height: Space.xl),
              if (isChartable(s))
                OutlinedButton.icon(
                  icon: const Icon(Icons.show_chart_rounded),
                  label: Text(l.openHistory),
                  onPressed: () {
                    ref.read(historySelectionProvider.notifier).select(s);
                    Navigator.of(context).pop();
                    context.go('/history');
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  static double _minRange(Sensor s) => switch (s.unit) {
        SensorUnit.percent => 10,
        SensorUnit.celsius => 5,
        SensorUnit.volts => s.max > 2 ? 0.5 : 0.2,
        SensorUnit.rpm => 500,
        SensorUnit.kmh => 10,
        _ => 0,
      };
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label.toUpperCase(), style: context.text.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: context.text.titleMedium?.copyWith(fontFeatures: tabular)),
        ],
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: context.text.labelMedium?.copyWith(color: color)),
      ],
    );
  }
}
