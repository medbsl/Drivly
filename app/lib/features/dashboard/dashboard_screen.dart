import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:obd_core/obd_core.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/sensor_meta.dart';
import '../../core/units.dart';
import '../../data/settings.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/arc_gauge.dart';
import '../../shared/widgets/metric_tile.dart';
import '../../shared/widgets/states.dart';
import '../../shared/widgets/status_pill.dart';
import '../connection/connection_controller.dart';
import '../connection/connection_errors.dart';
import '../fault_codes/dtc_controller.dart';
import '../fault_codes/dtc_database.dart';
import '../live/live_data.dart';
import 'health_summary.dart';
import 'sensor_detail_sheet.dart';

/// Order of tiles under the gauges: the design's core six first.
const _tileOrder = [
  Sensors.coolant, Sensors.battery, Sensors.load, Sensors.throttle, Sensors.intakeTemp, Sensors.fuelLevel,
];
final _hiddenFromTiles = {Sensors.speed, Sensors.rpm, Sensors.mil, Sensors.dtcCount};

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(connectionProvider);
    final l = context.l10n;
    final showLive = conn.isReady || conn.phase == ConnPhase.reconnecting;

    return Scaffold(
      appBar: AppBar(
        title: const _Wordmark(),
        actions: [
          const StatusPill(),
          IconButton(
            tooltip: l.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: showLive
          ? const _LiveDashboard()
          : conn.isBusy
              ? const _ConnectingSkeleton()
              : conn.isError
                  ? Center(child: SingleChildScrollView(child: ConnectionErrorView(state: conn)))
                  : const _NotConnected(),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            gradient: LinearGradient(colors: [c.accent, c.accentGlow], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Icon(Icons.speed_rounded, size: 18, color: c.onAccent),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Drivly', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          ),
        ),
      ],
    );
  }
}

class _NotConnected extends ConsumerWidget {
  const _NotConnected();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final saved = ref.watch(settingsProvider.select((s) => s.savedAdapterId));
    final hasSaved = saved != null && saved != AdapterRef.demoId;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const _HeroGlow(),
            EmptyState(
              icon: Icons.bluetooth_rounded,
              title: hasSaved ? l.homeNotConnectedTitle : l.homeNoAdapterTitle,
              body: hasSaved ? l.homeNotConnectedBody : l.homeNoAdapterBody,
              primaryLabel: hasSaved ? l.connect : l.connectAdapter,
              onPrimary: hasSaved
                  ? () => ref.read(connectionProvider.notifier).autoConnectNow()
                  : () => context.push('/connect'),
              secondaryLabel: l.tryDemo,
              onSecondary: () => ref.read(connectionProvider.notifier).connectDemo(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Decorative gauge silhouette above the empty state.
class _HeroGlow extends StatelessWidget {
  const _HeroGlow();

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: Padding(
        padding: EdgeInsets.only(top: Space.l),
        child: SizedBox(
          width: 180,
          child: Opacity(
            opacity: 0.55,
            child: ArcGauge(value: 62, max: 100, label: '', unit: '', display: ''),
          ),
        ),
      ),
    );
  }
}

class _ConnectingSkeleton extends StatelessWidget {
  const _ConnectingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Space.l),
      children: [
        const Skeleton(height: 76),
        const SizedBox(height: Space.l),
        Row(
          children: const [
            Expanded(child: Skeleton(height: 170, radius: 999)),
            SizedBox(width: Space.l),
            Expanded(child: Skeleton(height: 170, radius: 999)),
          ],
        ),
        const SizedBox(height: Space.l),
        for (var i = 0; i < 3; i++) ...[
          Row(
            children: const [
              Expanded(child: Skeleton(height: 130)),
              SizedBox(width: Space.m),
              Expanded(child: Skeleton(height: 130)),
            ],
          ),
          const SizedBox(height: Space.m),
        ],
      ],
    );
  }
}

class _LiveDashboard extends ConsumerWidget {
  const _LiveDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveDataProvider);
    return ListenableBuilder(
      listenable: live,
      builder: (context, _) => _LiveBody(live: live),
    );
  }
}

class _LiveBody extends ConsumerWidget {
  const _LiveBody({required this.live});
  final LiveData live;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final units = ref.watch(unitsProvider);
    final conn = ref.watch(connectionProvider);
    final speed = live.value(Sensors.speed);
    final rpm = live.value(Sensors.rpm);
    final moving = (speed ?? 0) > 0;
    final reconnecting = conn.phase == ConnPhase.reconnecting;
    final justReconnected = conn.reconnectedAt != null && DateTime.now().difference(conn.reconnectedAt!) < const Duration(seconds: 2);

    final tiles = [
      ..._tileOrder.where(live.polled.contains),
      ...Sensors.all.where((s) => live.polled.contains(s) && !_tileOrder.contains(s) && !_hiddenFromTiles.contains(s)),
    ];
    final speedMax = units.convert(SensorUnit.kmh, 220);
    final session = ref.read(connectionProvider.notifier).session;
    final trip = session?.trips.current;

    return Column(
      children: [
        if (reconnecting)
          StatusBanner(
            text: l.bannerReconnecting,
            color: c.warn,
            icon: Icons.sync_problem_rounded,
            action: l.stop,
            onAction: () => ref.read(connectionProvider.notifier).disconnect(),
          )
        else if (justReconnected)
          StatusBanner(text: l.bannerReconnected, color: c.good, icon: Icons.check_circle_rounded)
        else if (moving)
          StatusBanner(text: l.passengerStrip, color: c.accent, icon: Icons.airline_seat_recline_normal_rounded),
        Expanded(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: reconnecting ? 0.45 : 1,
            child: LayoutBuilder(builder: (context, box) {
              final wide = box.maxWidth > 720;
              final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
              final columns = wide ? 3 : (scale > 1.5 ? 1 : 2);
              final gauges = Row(
                children: [
                  Expanded(
                    child: ArcGauge(
                      value: speed == null ? null : units.convert(SensorUnit.kmh, speed),
                      max: speedMax,
                      label: l.sensorSpeed,
                      unit: units.unitOf(Sensors.speed),
                      display: speed == null ? '–' : units.format(Sensors.speed, speed),
                      stale: live.isStale(Sensors.speed),
                    ),
                  ),
                  const SizedBox(width: Space.m),
                  Expanded(
                    child: ArcGauge(
                      value: rpm,
                      max: 8000,
                      redlineFrom: 0.8,
                      label: l.sensorRpm,
                      unit: 'rpm',
                      display: rpm == null ? '–' : Units.number(rpm, 0),
                      stale: live.isStale(Sensors.rpm),
                    ),
                  ),
                ],
              );

              final grid = _TileGrid(
                columns: columns,
                children: [
                  for (final s in tiles)
                    MetricTile(
                      sensor: s,
                      units: units,
                      value: live.value(s),
                      history: live.recent(s, const Duration(seconds: 90)),
                      stale: live.isStale(s),
                      status: _statusFor(context, s, live),
                      onTap: () => showSensorSheet(context, s),
                    ),
                ],
              );

              final children = <Widget>[
                const _HealthCard(),
                const SizedBox(height: Space.l),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: box.maxWidth * 0.36, child: gauges),
                      const SizedBox(width: Space.l),
                      Expanded(child: grid),
                    ],
                  )
                else ...[
                  gauges,
                  if (trip != null) ...[const SizedBox(height: Space.s), _TripStrip(distanceKm: trip.distanceKm, duration: trip.duration)],
                  const SizedBox(height: Space.l),
                  grid,
                ],
                if (live.unsupported.isNotEmpty) ...[
                  const SizedBox(height: Space.m),
                  TextButton(
                    onPressed: () => _showUnsupported(context, live),
                    child: Text(l.unsupportedFootnote(live.unsupported.length)),
                  ),
                ],
                const SizedBox(height: Space.s),
                _Footer(live: live, session: session?.savedReadings ?? 0),
                const SizedBox(height: Space.xl),
              ];
              return ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(Space.l, Space.s, Space.l, Space.l),
                children: children,
              );
            }),
          ),
        ),
      ],
    );
  }

  (String, Color)? _statusFor(BuildContext context, Sensor s, LiveData live) {
    final l = context.l10n;
    final c = context.colors;
    final v = live.value(s);
    if (v == null) return null;
    ValueStatus? st;
    if (s == Sensors.coolant || s == Sensors.oilTemp) st = coolantStatus(v);
    if (s == Sensors.battery) st = batteryStatus(v, engineRunning: (live.value(Sensors.rpm) ?? 0) > 300);
    if (st == null) return null;
    final color = switch (st.tone) {
      Tone.good => c.good,
      Tone.warn => c.warn,
      Tone.danger => c.danger,
      Tone.neutral => c.textSecondary,
    };
    return (valueStatusLabel(l, st), color);
  }

  void _showUnsupported(BuildContext context, LiveData live) {
    final l = context.l10n;
    showAppSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.unsupportedTitle, style: ctx.text.titleLarge),
            const SizedBox(height: Space.s),
            Text(l.unsupportedBody, style: ctx.text.bodyMedium),
            const SizedBox(height: Space.l),
            for (final s in live.unsupported)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('• ${sensorText(l, s).label}', style: ctx.text.bodyLarge),
              ),
          ],
        ),
      ),
    );
  }
}

String valueStatusLabel(AppLocalizations l, ValueStatus s) => switch (s) {
      ValueStatus.warmingUp => l.statusWarmingUp,
      ValueStatus.normal => l.statusNormal,
      ValueStatus.hot => l.statusHot,
      ValueStatus.tooHot => l.statusTooHot,
      ValueStatus.charging => l.statusCharging,
      ValueStatus.lowCharging => l.statusLowCharging,
      ValueStatus.tooHigh => l.statusTooHigh,
      ValueStatus.good => l.statusGood,
      ValueStatus.low => l.statusLow,
      ValueStatus.veryLow => l.statusVeryLow,
    };

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.columns, required this.children});
  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: Space.m),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < columns; j++) ...[
                if (j > 0) const SizedBox(width: Space.m),
                Expanded(child: i + j < children.length ? children[i + j] : const SizedBox.shrink()),
              ],
            ],
          ),
        ),
      ));
    }
    return Column(children: rows);
  }
}

class _HealthCard extends ConsumerWidget {
  const _HealthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final live = ref.watch(liveDataProvider);
    final dtc = ref.watch(dtcControllerProvider);
    final db = ref.watch(dtcDatabaseProvider);
    final units = ref.watch(unitsProvider);
    final last = dtc.last;
    final start = live.sessionStart;
    final checked = last != null && start != null && last.at.isAfter(start.subtract(const Duration(seconds: 5)));
    final battery = live.value(Sensors.battery);
    final result = computeHealth(HealthInput(
      checked: checked,
      milOn: last?.milOn ?? false,
      storedSeverities: [for (final d in last?.stored ?? const <Dtc>[]) db.lookup(d.code).severity],
      pendingCount: last?.pending.length ?? 0,
      coolant: live.value(Sensors.coolant),
      battery: battery,
      engineRunning: (live.value(Sensors.rpm) ?? 0) > 300,
    ));

    final batteryText = battery == null ? null : l.healthBattery(units.formatWithUnit(Sensors.battery, battery));
    final (icon, title, subtitle, color) = switch (result.status) {
      HealthStatus.notChecked => (Icons.radar_rounded, l.healthChecking, l.healthCheckingBody, c.textSecondary),
      HealthStatus.good => (
          Icons.check_circle_rounded,
          l.healthGood,
          [l.healthNoProblems, ?batteryText].join(' · '),
          c.good,
        ),
      HealthStatus.checkSoon => (
          Icons.error_outline_rounded,
          l.healthCheckSoon,
          [
            if (result.problems > 0) l.healthProblems(result.problems),
            if (result.hotEngine) l.healthEngineHot,
            if (result.lowBattery) l.healthBatteryLow,
          ].join(' · '),
          c.warn,
        ),
      HealthStatus.needsAttention => (
          Icons.warning_rounded,
          l.healthNeedsAttention,
          [
            if (result.milOn) l.healthMilOn,
            if (result.problems > 0) l.healthProblems(result.problems),
            if (result.hotEngine) l.healthEngineTooHot,
            if (result.lowBattery) l.healthBatteryVeryLow,
          ].join(' · '),
          c.danger,
        ),
    };

    return AppCard(
      tint: result.status == HealthStatus.notChecked ? null : color,
      onTap: () => context.go('/codes'),
      semanticLabel: '$title. $subtitle',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Row(
          key: ValueKey(result.status),
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
              child: dtc.scanning && result.status == HealthStatus.notChecked
                  ? Padding(padding: const EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2.5, color: color))
                  : Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleMedium?.copyWith(color: result.status == HealthStatus.notChecked ? null : color)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: context.text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}

class _TripStrip extends ConsumerWidget {
  const _TripStrip({required this.distanceKm, required this.duration});
  final double distanceKm;
  final Duration duration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final units = ref.watch(unitsProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fiber_manual_record_rounded, size: 12, color: c.danger),
          const SizedBox(width: 8),
          Text(context.l10n.tripRecording, style: context.text.labelMedium?.copyWith(color: c.textPrimary)),
          const SizedBox(width: 10),
          Text(
            '${formatDuration(duration)} · ${units.distance(distanceKm)}',
            style: context.text.labelMedium?.copyWith(fontFeatures: tabular),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.live, required this.session});
  final LiveData live;
  final int session;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.bolt_rounded, size: 14, color: c.textMuted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            l.liveFooter(live.requestsPerSecond.toStringAsFixed(1), formatCount(live.sessionReadings)),
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: c.textMuted, fontFeatures: tabular),
          ),
        ),
      ],
    );
  }
}
