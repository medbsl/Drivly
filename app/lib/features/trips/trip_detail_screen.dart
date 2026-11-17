import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:obd_core/obd_core.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/sensor_meta.dart';
import '../../core/units.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/time_series_chart.dart';
import '../history/history_controller.dart';

final tripProvider = FutureProvider.family<Trip?, String>((ref, id) {
  ref.watch(dataVersionProvider);
  return ref.watch(tripRepoProvider).byId(id);
});

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final trip = ref.watch(tripProvider(id)).valueOrNull;
    final units = ref.watch(unitsProvider);
    if (trip == null) return Scaffold(appBar: AppBar());

    final stats = [
      (l.tripDuration, formatDuration(trip.duration), Icons.timer_outlined),
      (l.tripDistance, units.distance(trip.distanceKm), Icons.route_rounded),
      (l.tripAvgSpeed, units.speedText(trip.avgSpeed), Icons.speed_rounded),
      (l.tripMaxSpeed, units.speedText(trip.maxSpeed), Icons.trending_up_rounded),
      (l.tripMaxTemp, trip.maxCoolant == null ? '–' : units.tempText(trip.maxCoolant!), Icons.thermostat_rounded),
      (l.tripIdle, formatDuration(Duration(seconds: trip.idleSeconds)), Icons.hourglass_bottom_rounded),
      if (trip.fuelUsedL != null) (l.tripFuel, '${Units.number(trip.fuelUsedL!, 2)} L', Icons.local_gas_station_rounded),
      if (trip.consumption != null) (l.tripConsumption, '${Units.number(trip.consumption!, 1)} L/100 km', Icons.eco_outlined),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat.yMMMEd().format(trip.startedAt)),
        actions: [
          IconButton(
            tooltip: l.deleteTrip,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l.deleteTripConfirm),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
                  ],
                ),
              );
              if (ok != true) return;
              await ref.read(tripRepoProvider).delete(trip.id);
              ref.read(dataVersionProvider.notifier).bump();
              if (context.mounted) context.pop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
        children: [
          Text(
            '${DateFormat.Hm().format(trip.startedAt)} – ${DateFormat.Hm().format(trip.endedAt)}',
            style: context.text.titleMedium?.copyWith(fontFeatures: tabular, color: context.colors.textSecondary),
          ),
          const SizedBox(height: Space.l),
          LayoutBuilder(builder: (context, box) {
            final w = (box.maxWidth - Space.m) / 2;
            return Wrap(
              spacing: Space.m,
              runSpacing: Space.m,
              children: [
                for (final (label, value, icon) in stats)
                  SizedBox(
                    width: w,
                    child: AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(icon, size: 16, color: context.colors.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(child: Text(label, style: context.text.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ]),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(value, style: context.text.titleLarge?.copyWith(fontFeatures: tabular)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: Space.s),
          for (final s in [Sensors.speed, Sensors.rpm, Sensors.coolant, Sensors.fuelRate]) _TripChart(trip: trip, sensor: s),
          const SizedBox(height: Space.l),
          Text(trip.hasGap ? '${l.tripDistanceNote} ${l.tripGapNote}' : l.tripDistanceNote, style: context.text.bodySmall),
        ],
      ),
    );
  }
}

class _TripChart extends ConsumerWidget {
  const _TripChart({required this.trip, required this.sensor});
  final Trip trip;
  final Sensor sensor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitsProvider);
    final key = (sensorId: sensor.id, from: trip.startedAt, to: trip.endedAt, buckets: 160, vehicleId: trip.vehicleId);
    final series = ref.watch(seriesProvider(key)).valueOrNull;
    if (series == null || series.isEmpty) return const SizedBox.shrink();
    final bucket = trip.duration ~/ 160;
    return Padding(
      padding: const EdgeInsets.only(top: Space.m),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(sensorIcon(sensor), size: 18, color: context.colors.accent),
              const SizedBox(width: Space.s),
              Text('${sensorText(context.l10n, sensor).label} · ${units.unitOf(sensor)}', style: context.text.titleSmall),
            ]),
            const SizedBox(height: Space.m),
            TimeSeriesChart(
              points: [
                for (final p in series)
                  ChartPoint(p.t, units.value(sensor, p.avg), lo: units.value(sensor, p.min), hi: units.value(sensor, p.max)),
              ],
              from: trip.startedAt,
              to: trip.endedAt,
              height: 170,
              zeroBased: sensor != Sensors.coolant,
              gapThreshold: bucket * 3 + const Duration(seconds: 15),
              formatValue: (v) => Units.number(v, sensor.decimals),
            ),
          ],
        ),
      ),
    );
  }
}
