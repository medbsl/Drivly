import 'dart:async';

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
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/metric_tile.dart' show adaptiveFrom;
import '../../shared/widgets/sparkline.dart';
import '../../shared/widgets/states.dart';
import '../../shared/widgets/status_pill.dart';
import '../../shared/widgets/time_series_chart.dart';
import '../connection/connection_controller.dart';
import '../live/live_data.dart';
import 'history_controller.dart';

String rangeLabel(AppLocalizations l, HistoryRange r) => switch (r) {
      HistoryRange.live => l.rangeLive,
      HistoryRange.hour => l.range1h,
      HistoryRange.day => l.range24h,
      HistoryRange.week => l.range7d,
      HistoryRange.month => l.range30d,
      HistoryRange.all => l.rangeAll,
    };

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    // While connected, keep the stored-range charts moving with new data.
    _refresh = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      final sel = ref.read(historySelectionProvider);
      if (ref.read(connectionProvider).isReady && sel.range != HistoryRange.live && sel.range.span <= const Duration(days: 1)) {
        ref.read(historySelectionProvider.notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sel = ref.watch(historySelectionProvider);
    final vehicle = ref.watch(currentVehicleProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.tabHistory),
            if (vehicle != null) Text(vehicleTitle(l, vehicle), style: context.text.bodySmall),
          ],
        ),
        actions: [
          const StatusPill(),
          IconButton(tooltip: l.settings, icon: const Icon(Icons.settings_outlined), onPressed: () => context.push('/settings')),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(historySelectionProvider.notifier).refresh();
          ref.read(dataVersionProvider.notifier).bump();
        },
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.l, Space.s, Space.l, Space.xxl),
          children: [
            _RangeBar(selected: sel.range),
            const SizedBox(height: Space.l),
            if (sel.range == HistoryRange.live) const _LiveSection() else const _StoredSection(),
            const _TripsSection(),
            const SizedBox(height: Space.xl),
            const _StorageFooter(),
          ],
        ),
      ),
    );
  }
}

String vehicleTitle(AppLocalizations l, Vehicle v) {
  final parts = [
    v.nickname ?? v.make ?? (v.demo ? l.demoCar : l.yourCar),
    if (v.modelYear != null) v.modelYearCertain ? '${v.modelYear}' : l.likelyYear(v.modelYear!),
  ];
  return parts.join(' · ');
}

class _RangeBar extends ConsumerWidget {
  const _RangeBar({required this.selected});
  final HistoryRange selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.outline),
        ),
        child: Row(
          children: [
            for (final r in HistoryRange.values)
              _RangeChip(
                label: rangeLabel(l, r),
                selected: r == selected,
                live: r == HistoryRange.live,
                onTap: () => ref.read(historySelectionProvider.notifier).setRange(r),
              ),
          ],
        ),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({required this.label, required this.selected, required this.onTap, this.live = false});
  final String label;
  final bool selected;
  final bool live;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 40, minWidth: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (live) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: selected ? c.onAccent : c.danger, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: selected ? c.onAccent : c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Focus card shared by live and stored ranges.
class _FocusCard extends ConsumerWidget {
  const _FocusCard({
    required this.sensor,
    required this.points,
    required this.from,
    required this.to,
    required this.stats,
    required this.available,
    this.loading = false,
    this.live = false,
  });

  final Sensor sensor;
  final List<ChartPoint> points;
  final DateTime from;
  final DateTime to;
  final (double, double, double)? stats;
  final List<Sensor> available;
  final bool loading;
  final bool live;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final units = ref.watch(unitsProvider);
    final text = sensorText(l, sensor);
    final unit = units.unitOf(sensor);
    final headline = points.isEmpty ? null : (live ? points.last.v : stats?.$2);
    final bucket = to.difference(from) ~/ 180;

    return AppCard(
      glow: true,
      padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(sensorIcon(sensor), size: 18, color: c.accent),
              const SizedBox(width: Space.s),
              Expanded(child: Text(text.label, style: context.text.titleMedium)),
              Text(live ? l.now : l.statAvg, style: context.text.labelMedium),
            ],
          ),
          const SizedBox(height: Space.s),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                headline == null ? '–' : Units.number(headline, sensor.decimals),
                style: context.text.displayMedium?.copyWith(fontFeatures: tabular),
              ),
              const SizedBox(width: 6),
              Text(unit, style: context.text.titleMedium?.copyWith(color: c.textSecondary)),
              const Spacer(),
              if (stats != null) ...[
                _MiniStat(label: l.statMin, value: Units.number(stats!.$1, sensor.decimals)),
                const SizedBox(width: Space.l),
                _MiniStat(label: l.statMax, value: Units.number(stats!.$3, sensor.decimals)),
              ],
            ],
          ),
          const SizedBox(height: Space.l),
          if (loading && points.isEmpty)
            const Skeleton(height: 240, radius: 12)
          else if (points.isEmpty)
            SizedBox(
              height: 240,
              child: Center(child: Text(l.noDataInRange, style: context.text.bodyMedium, textAlign: TextAlign.center)),
            )
          else
            TimeSeriesChart(
              points: points,
              from: from,
              to: to,
              height: 240,
              animate: !live,
              gapThreshold: live ? const Duration(seconds: 15) : bucket * 3 + const Duration(seconds: 30),
              minYRange: _minRange(sensor),
              formatValue: (v) => Units.number(v, sensor.decimals),
            ),
          const SizedBox(height: Space.m),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: available.length,
              separatorBuilder: (_, _) => const SizedBox(width: Space.s),
              itemBuilder: (context, i) {
                final s = available[i];
                return ChoiceChip(
                  avatar: Icon(sensorIcon(s), size: 16, color: s == sensor ? c.accent : c.textSecondary),
                  label: Text(sensorText(l, s).label),
                  selected: s == sensor,
                  onSelected: (_) => ref.read(historySelectionProvider.notifier).select(s),
                );
              },
            ),
          ),
        ],
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label.toUpperCase(), style: context.text.labelSmall),
        Text(value, style: context.text.titleSmall?.copyWith(fontFeatures: tabular)),
      ],
    );
  }
}

/// "Live": the last 15 minutes straight from memory, redrawn ~8×/s.
class _LiveSection extends ConsumerWidget {
  const _LiveSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final live = ref.watch(liveDataProvider);
    final sel = ref.watch(historySelectionProvider);
    final units = ref.watch(unitsProvider);
    return ListenableBuilder(
      listenable: live,
      builder: (context, _) {
        if (!live.hasData) {
          return EmptyState(
            icon: Icons.sensors_rounded,
            title: l.liveEmptyTitle,
            body: l.liveEmptyBody,
            primaryLabel: l.connectAdapter,
            onPrimary: () => context.push('/connect'),
            secondaryLabel: l.tryDemo,
            onSecondary: () => ref.read(connectionProvider.notifier).connectDemo(),
          );
        }
        final now = DateTime.now();
        final available = Sensors.all.where((s) => isChartable(s) && live.recent(s).isNotEmpty).toList();
        final sensor = available.contains(sel.sensor) ? sel.sensor : (available.isEmpty ? sel.sensor : available.first);
        final raw = live.recent(sensor);
        final from = adaptiveFrom(raw, now, HistoryRange.live.span, const Duration(minutes: 1));
        final pts = [for (final p in raw) ChartPoint(p.t, units.value(sensor, p.v))];
        (double, double, double)? stats;
        if (pts.isNotEmpty) {
          var lo = pts.first.v, hi = pts.first.v, sum = 0.0;
          for (final p in pts) {
            if (p.v < lo) lo = p.v;
            if (p.v > hi) hi = p.v;
            sum += p.v;
          }
          stats = (lo, sum / pts.length, hi);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FocusCard(sensor: sensor, points: pts, from: from, to: now, stats: stats, available: available, live: true),
            SectionHeader(l.allValues),
            _OverviewGrid(
              items: [
                for (final s in available)
                  _OverviewItem(
                    sensor: s,
                    value: live.value(s),
                    points: [for (final p in live.recent(s)) TimedValue(p.t, units.value(s, p.v))],
                  ),
              ],
              from: from,
              to: now,
              selected: sensor,
            ),
          ],
        );
      },
    );
  }
}

/// Stored ranges: aggregated in SQL (avg line + min–max band).
class _StoredSection extends ConsumerWidget {
  const _StoredSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final w = ref.watch(historyWindowProvider);
    final sel = ref.watch(historySelectionProvider);
    final units = ref.watch(unitsProvider);
    final summariesAsync = ref.watch(summariesProvider(w));
    final summaries = summariesAsync.valueOrNull ?? const <SensorSummary>[];
    final available = summaries.map((s) => s.sensor).where(isChartable).toList();

    if (summariesAsync.hasValue && available.isEmpty) {
      return EmptyState(
        icon: Icons.insights_rounded,
        title: l.historyEmptyTitle,
        body: l.historyEmptyBody,
        primaryLabel: l.connectAdapter,
        onPrimary: () => context.push('/connect'),
        secondaryLabel: l.tryDemo,
        onSecondary: () => ref.read(connectionProvider.notifier).connectDemo(),
      );
    }

    final sensor = available.contains(sel.sensor) ? sel.sensor : (available.isEmpty ? sel.sensor : available.first);
    final seriesAsync = ref.watch(seriesProvider((sensorId: sensor.id, from: w.from, to: w.to, buckets: 180, vehicleId: w.vehicleId)));
    final series = seriesAsync.valueOrNull ?? const <SeriesPoint>[];
    final pts = [
      for (final p in series)
        ChartPoint(p.t, units.value(sensor, p.avg), lo: units.value(sensor, p.min), hi: units.value(sensor, p.max)),
    ];
    final summary = summaries.where((s) => s.sensor == sensor).firstOrNull;
    final stats = summary == null
        ? null
        : (units.value(sensor, summary.min), units.value(sensor, summary.avg), units.value(sensor, summary.max));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FocusCard(
          sensor: sensor,
          points: pts,
          from: w.from,
          to: w.to,
          stats: stats,
          available: available,
          loading: seriesAsync.isLoading,
        ),
        if (available.length > 1) ...[
          SectionHeader(l.allValues, trailing: Text(l.readingsCount(formatCount(summaries.fold(0, (a, s) => a + s.count))), style: context.text.labelSmall)),
          _StoredOverview(sensors: available, summaries: summaries, window: w, selected: sensor),
        ],
      ],
    );
  }
}

class _StoredOverview extends ConsumerWidget {
  const _StoredOverview({required this.sensors, required this.summaries, required this.window, required this.selected});
  final List<Sensor> sensors;
  final List<SensorSummary> summaries;
  final Window window;
  final Sensor selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitsProvider);
    final items = <_OverviewItem>[];
    for (final s in sensors) {
      final series = ref.watch(seriesProvider((sensorId: s.id, from: window.from, to: window.to, buckets: 48, vehicleId: window.vehicleId))).valueOrNull;
      final sum = summaries.firstWhere((x) => x.sensor == s);
      items.add(_OverviewItem(
        sensor: s,
        value: sum.avg,
        points: [for (final p in series ?? const <SeriesPoint>[]) TimedValue(p.t, units.value(s, p.avg))],
        isAverage: true,
      ));
    }
    final bucket = window.to.difference(window.from) ~/ 48;
    return _OverviewGrid(items: items, from: window.from, to: window.to, selected: selected, maxGap: bucket * 3);
  }
}

class _OverviewItem {
  const _OverviewItem({required this.sensor, required this.value, required this.points, this.isAverage = false});
  final Sensor sensor;
  final double? value;
  final List<TimedValue> points;
  final bool isAverage;
}

class _OverviewGrid extends ConsumerWidget {
  const _OverviewGrid({required this.items, required this.from, required this.to, required this.selected, this.maxGap});
  final List<_OverviewItem> items;
  final DateTime from;
  final DateTime to;
  final Sensor selected;
  final Duration? maxGap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final units = ref.watch(unitsProvider);
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final cols = scale > 1.5 ? 1 : 2;
    return LayoutBuilder(builder: (context, box) {
      final w = (box.maxWidth - Space.m * (cols - 1)) / cols;
      return Wrap(
        spacing: Space.m,
        runSpacing: Space.m,
        children: [
          for (final it in items)
            SizedBox(
              width: w,
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                tint: it.sensor == selected ? c.accent : null,
                onTap: () => ref.read(historySelectionProvider.notifier).select(it.sensor),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sensorText(l, it.sensor).label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.labelMedium),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              it.value == null ? '–' : units.format(it.sensor, it.value!),
                              style: context.text.titleLarge?.copyWith(fontFeatures: tabular),
                              maxLines: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(units.unitOf(it.sensor), style: context.text.bodySmall),
                        if (it.isAverage) ...[
                          const Spacer(),
                          Text(l.statAvg, style: context.text.labelSmall?.copyWith(fontSize: 10)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Sparkline(points: it.points, from: from, to: to, height: 32, maxGap: maxGap ?? const Duration(seconds: 15)),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _TripsSection extends ConsumerWidget {
  const _TripsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final trips = ref.watch(recentTripsProvider).valueOrNull ?? const <Trip>[];
    if (trips.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l.recentTrips),
        for (final t in trips) ...[TripCard(trip: t), const SizedBox(height: Space.s)],
      ],
    );
  }
}

class TripCard extends ConsumerWidget {
  const TripCard({super.key, required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final units = ref.watch(unitsProvider);
    final day = DateFormat.MMMEd().format(trip.startedAt);
    final time = '${DateFormat.Hm().format(trip.startedAt)} – ${DateFormat.Hm().format(trip.endedAt)}';
    return AppCard(
      onTap: () => context.push('/history/trip/${trip.id}'),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: c.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.route_rounded, color: c.accent),
          ),
          const SizedBox(width: Space.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$day · $time', style: context.text.titleSmall?.copyWith(fontFeatures: tabular)),
                const SizedBox(height: 2),
                Text(
                  '${formatDuration(trip.duration)} · ${context.l10n.avgSpeed(units.speedText(trip.avgSpeed))}',
                  style: context.text.bodySmall?.copyWith(fontFeatures: tabular),
                ),
              ],
            ),
          ),
          Text(units.distance(trip.distanceKm), style: context.text.titleMedium?.copyWith(fontFeatures: tabular)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: c.textMuted),
        ],
      ),
    );
  }
}

class _StorageFooter extends ConsumerWidget {
  const _StorageFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final stats = ref.watch(storageStatsProvider).valueOrNull;
    if (stats == null || stats.readings == 0) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, size: 14, color: c.textMuted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            l.storageFooter(formatCount(stats.readings), formatBytes(stats.bytes)),
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: c.textMuted),
          ),
        ),
      ],
    );
  }
}
