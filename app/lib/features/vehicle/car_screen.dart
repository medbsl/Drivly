import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../shared/widgets/states.dart';
import '../../shared/widgets/status_pill.dart';
import '../connection/connection_controller.dart';
import '../history/history_controller.dart';
import '../history/history_screen.dart';
import '../live/live_data.dart';

class CarScreen extends ConsumerWidget {
  const CarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final vehicleAsync = ref.watch(currentVehicleProvider);
    final vehicle = vehicleAsync.valueOrNull;
    final conn = ref.watch(connectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tabCar),
        actions: [
          const StatusPill(),
          IconButton(tooltip: l.settings, icon: const Icon(Icons.settings_outlined), onPressed: () => context.push('/settings')),
          const SizedBox(width: 4),
        ],
      ),
      body: vehicle == null
          ? (vehicleAsync.isLoading
              ? const SizedBox.shrink()
              : Center(
                  child: EmptyState(
                    icon: Icons.directions_car_filled_outlined,
                    title: l.carEmptyTitle,
                    body: l.carEmptyBody,
                    primaryLabel: l.connectAdapter,
                    onPrimary: () => context.push('/connect'),
                  ),
                ))
          : ListView(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
              children: [
                _CarHero(vehicle: vehicle),
                const SizedBox(height: Space.l),
                _VinCard(vehicle: vehicle, connected: conn.isReady),
                SectionHeader(l.adapterSection),
                _AdapterCard(conn: conn),
                SectionHeader(l.carSupports(vehicle.supportedPids.where((p) => Sensors.byPid.containsKey(p)).length + 2)),
                _SupportedList(vehicle: vehicle),
              ],
            ),
    );
  }
}

class _CarHero extends ConsumerWidget {
  const _CarHero({required this.vehicle});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final model = vehicle.modelUser;
    return AppCard(
      glow: true,
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [c.accent.withValues(alpha: 0.3), c.accent.withValues(alpha: 0.02)]),
            ),
            child: Icon(Icons.directions_car_filled_rounded, size: 44, color: c.accent),
          ),
          const SizedBox(height: Space.m),
          Text(vehicleTitle(l, vehicle), style: context.text.titleLarge, textAlign: TextAlign.center),
          if (model != null || vehicle.nickname != null) ...[
            const SizedBox(height: 2),
            Text([vehicle.make, model].whereType<String>().join(' '), style: context.text.bodyMedium),
          ],
          const SizedBox(height: Space.s),
          TextButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(l.editCar),
            onPressed: () => _editSheet(context, ref, vehicle),
          ),
        ],
      ),
    );
  }

  Future<void> _editSheet(BuildContext context, WidgetRef ref, Vehicle v) async {
    final l = context.l10n;
    final nick = TextEditingController(text: v.nickname ?? '');
    final model = TextEditingController(text: v.modelUser ?? '');
    final year = TextEditingController(text: v.modelYear?.toString() ?? '');
    await showAppSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.editCar, style: ctx.text.titleLarge),
            const SizedBox(height: Space.l),
            TextField(controller: nick, decoration: InputDecoration(labelText: l.nickname)),
            const SizedBox(height: Space.m),
            TextField(controller: model, decoration: InputDecoration(labelText: l.model)),
            const SizedBox(height: Space.m),
            TextField(
              controller: year,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
              decoration: InputDecoration(labelText: l.modelYear),
            ),
            const SizedBox(height: Space.xl),
            FilledButton(
              onPressed: () async {
                final y = int.tryParse(year.text);
                await ref.read(vehicleRepoProvider).update(
                      v.id,
                      nickname: nick.text.trim(),
                      modelUser: model.text.trim(),
                      modelYear: y != null && y >= 1980 && y <= DateTime.now().year + 1 && y != v.modelYear ? y : null,
                    );
                ref.read(dataVersionProvider.notifier).bump();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _VinCard extends ConsumerWidget {
  const _VinCard({required this.vehicle, required this.connected});
  final Vehicle vehicle;
  final bool connected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final units = ref.watch(unitsProvider);
    final live = ref.watch(liveDataProvider);
    final vin = vehicle.vin;

    Widget row(String k, Widget v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Expanded(child: Text(k, style: context.text.bodyMedium)),
            const SizedBox(width: Space.m),
            Flexible(child: Align(alignment: AlignmentDirectional.centerEnd, child: v)),
          ]),
        );
    Text val(String s) => Text(s, style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontFeatures: tabular), textAlign: TextAlign.end);

    return ListenableBuilder(
      listenable: live,
      builder: (context, _) {
        final odo = live.value(Sensors.odometer);
        final sinceClear = live.value(Sensors.distanceSinceClear);
        return AppCard(
          child: Column(
            children: [
              if (vin != null)
                Row(children: [
                  Text('VIN', style: context.text.bodyMedium),
                  const SizedBox(width: Space.m),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(vin, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 15)),
                        ),
                      ),
                    ),
                  ),
                    IconButton(
                      tooltip: l.copy,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.copy_rounded, size: 18, color: c.textSecondary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: vin));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.copied)));
                      },
                    ),
                ])
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.vinNotShared, style: context.text.bodyMedium),
                      TextButton(onPressed: () => _enterVin(context, ref), child: Text(l.enterVin)),
                    ],
                  ),
                ),
              if (vehicle.country != null) row(l.madeIn, val(vehicle.country!)),
              if (vehicle.obdProtocol != null)
                row(l.connectionType, val(vehicle.obdProtocol!.isCan ? l.protocolCan : l.protocolLegacy)),
              row(l.valuesAvailable, val('${vehicle.supportedPids.where((p) => Sensors.byPid.containsKey(p)).length + 2}')),
              if (odo != null) row(l.sensorOdometer, val(units.distance(odo, decimals: 0))),
              if (sinceClear != null) row(l.sensorDistanceSinceClear, val(units.distance(sinceClear, decimals: 0))),
              if (!connected) row(l.lastSeen, val(DateFormat.yMMMd().add_Hm().format(vehicle.updatedAt))),
            ],
          ),
        );
      },
    );
  }

  Future<void> _enterVin(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ctrl = TextEditingController();
    String? error;
    await showAppSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.enterVin, style: ctx.text.titleLarge),
              const SizedBox(height: Space.s),
              Text(l.enterVinHint, style: ctx.text.bodyMedium),
              const SizedBox(height: Space.l),
              TextField(
                controller: ctrl,
                textCapitalization: TextCapitalization.characters,
                maxLength: 17,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 18),
                decoration: InputDecoration(errorText: error),
              ),
              const SizedBox(height: Space.m),
              FilledButton(
                onPressed: () async {
                  final vin = ctrl.text.trim().toUpperCase();
                  if (!isValidVin(vin)) {
                    setState(() => error = l.vinInvalid);
                    return;
                  }
                  await ref.read(vehicleRepoProvider).update(vehicle.id, vin: vin);
                  ref.read(dataVersionProvider.notifier).bump();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(l.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdapterCard extends ConsumerWidget {
  const _AdapterCard({required this.conn});
  final ConnState conn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final info = conn.info;
    final live = ref.watch(liveDataProvider);
    final units = ref.watch(unitsProvider);
    if (!conn.isReady || info == null) {
      return AppCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.bluetooth_rounded),
          title: Text(l.notConnected),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push('/connect'),
        ),
      );
    }
    return ListenableBuilder(
      listenable: live,
      builder: (context, _) {
        final batt = live.value(Sensors.battery);
        Widget kv(String k, String v) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Expanded(child: Text(k, style: context.text.bodyMedium)),
                Text(v, style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontFeatures: tabular)),
              ]),
            );
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${conn.device?.name ?? ''} · ${info.elmVersion}', style: context.text.titleSmall),
              const SizedBox(height: Space.s),
              if (batt != null) kv(l.batteryAtPort, units.formatWithUnit(Sensors.battery, batt)),
              kv(l.protocol, info.protocol?.technicalName ?? '–'),
              kv(l.fastMode, info.multiPid ? l.stateOn : l.stateOff),
              kv(l.updatesPerSecond, live.requestsPerSecond.toStringAsFixed(1)),
              const SizedBox(height: Space.s),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await ref.read(connectionProvider.notifier).disconnect();
                      if (context.mounted) context.push('/connect');
                    },
                    child: Text(l.changeAdapter),
                  ),
                ),
                const SizedBox(width: Space.m),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref.read(connectionProvider.notifier).disconnect(),
                    child: Text(l.disconnect),
                  ),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }
}

class _SupportedList extends ConsumerWidget {
  const _SupportedList({required this.vehicle});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final sensors = Sensors.all.where((s) => s.isPid ? vehicle.supportedPids.contains(s.pid) : true).where((s) => s != Sensors.dtcCount);
    final groups = <SensorGroup, List<Sensor>>{};
    for (final s in sensors) {
      groups.putIfAbsent(s.group, () => []).add(s);
    }
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: Space.s),
      child: Column(
        children: [
          for (final g in groups.entries)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Icon(sensorIcon(g.value.first), color: c.textSecondary),
                title: Text(groupLabel(l, g.key), style: context.text.titleSmall),
                trailing: Text('${g.value.length}', style: context.text.labelMedium),
                children: [
                  for (final s in g.value)
                    ListTile(
                      dense: true,
                      title: Text(sensorText(l, s).label),
                      subtitle: Text(s.name, style: context.text.bodySmall),
                      trailing: isChartable(s) ? Icon(Icons.show_chart_rounded, size: 18, color: c.textMuted) : null,
                      onTap: isChartable(s)
                          ? () {
                              ref.read(historySelectionProvider.notifier).select(s);
                              context.go('/history');
                            }
                          : null,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
