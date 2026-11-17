import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;

import '../../app/theme/tokens.dart';
import '../../core/sensor_meta.dart';
import '../../data/settings.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/states.dart';
import '../settings/settings_screen.dart';
import 'ble_scanner.dart';
import 'connection_controller.dart';
import 'connection_errors.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  bool _showOthers = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(bleScanProvider.notifier).start());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final scan = ref.watch(bleScanProvider);
    final lastUsed = ref.watch(settingsProvider.select((s) => s.savedAdapterId));
    final devices = scan.devices.values.toList()
      ..sort((a, b) {
        if (a.id == lastUsed) return -1;
        if (b.id == lastUsed) return 1;
        return b.rssi.compareTo(a.rssi);
      });
    final likely = devices.where((d) => d.likely).toList();
    final others = devices.where((d) => !d.likely).toList();

    ref.listen(connectionProvider, (prev, next) {
      if (next.isReady && prev?.isReady != true && context.mounted) {
        HapticFeedback.lightImpact();
        final seen = ref.read(settingsProvider).safetyNoticeSeen;
        context.go('/dashboard');
        if (!seen) Future.microtask(() => showSafetyNoticeGlobal(ref));
      }
    });

    final problem = scan.problem;
    return Scaffold(
      appBar: AppBar(title: Text(l.connectAdapter)),
      body: problem != null
          ? Center(child: SingleChildScrollView(child: _ProblemView(problem: problem)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xxl),
              children: [
                _ScanRow(scanning: scan.scanning, onRescan: () => ref.read(bleScanProvider.notifier).start()),
                if (likely.isNotEmpty) ...[
                  SectionHeader(l.likelyAdapters),
                  for (final d in likely) ...[_DeviceCard(device: d, lastUsed: d.id == lastUsed), const SizedBox(height: Space.s)],
                ],
                if (scan.finished && likely.isEmpty)
                  AppCard(
                    tint: c.warn,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.noAdapterFound, style: context.text.titleMedium),
                        const SizedBox(height: Space.s),
                        Text(l.troubleshootShort, style: context.text.bodyMedium),
                      ],
                    ),
                  ),
                if (others.isNotEmpty) ...[
                  const SizedBox(height: Space.s),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.otherDevices(others.length), style: context.text.labelSmall),
                    trailing: Icon(_showOthers ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                    onTap: () => setState(() => _showOthers = !_showOthers),
                  ),
                  if (_showOthers)
                    for (final d in others) ...[_DeviceCard(device: d, lastUsed: false), const SizedBox(height: Space.s)],
                ],
                const SizedBox(height: Space.l),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded),
                  title: Text(l.cantFindAdapter),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _troubleshoot(context),
                ),
                ListTile(
                  leading: const Icon(Icons.play_circle_outline_rounded),
                  title: Text(l.tryDemo),
                  subtitle: Text(l.demoHint),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    ref.read(bleScanProvider.notifier).stop();
                    _openConnecting(context, ref, const AdapterRef.demo());
                  },
                ),
              ],
            ),
    );
  }

  void _troubleshoot(BuildContext context) {
    final l = context.l10n;
    showAppSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.cantFindAdapter, style: ctx.text.titleLarge),
            const SizedBox(height: Space.l),
            for (final (i, t) in [l.trouble1, l.trouble2, l.trouble3, l.trouble4, l.trouble5].indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.m),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CircleAvatar(radius: 12, backgroundColor: ctx.colors.surfaceRaised, child: Text('${i + 1}', style: ctx.text.labelMedium)),
                  const SizedBox(width: Space.m),
                  Expanded(child: Text(t, style: ctx.text.bodyLarge)),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

void _openConnecting(BuildContext context, WidgetRef ref, AdapterRef device) {
  final ctrl = ref.read(connectionProvider.notifier);
  if (device.demo) {
    ctrl.connectDemo();
  } else {
    ctrl.connectBle(device.id, device.name);
  }
  showAppSheet<void>(context, scrollable: false, builder: (_) => const ConnectingSheet());
}

class _ScanRow extends StatelessWidget {
  const _ScanRow({required this.scanning, required this.onRescan});
  final bool scanning;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.s),
      child: Row(
        children: [
          if (scanning)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
          else
            Icon(Icons.bluetooth_searching_rounded, color: context.colors.textSecondary),
          const SizedBox(width: Space.m),
          Expanded(child: Text(scanning ? l.lookingForAdapters : l.scanFinished, style: context.text.bodyLarge)),
          if (!scanning) TextButton(onPressed: onRescan, child: Text(l.scanAgain)),
        ],
      ),
    );
  }
}

class _DeviceCard extends ConsumerWidget {
  const _DeviceCard({required this.device, required this.lastUsed});
  final FoundDevice device;
  final bool lastUsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    return AppCard(
      onTap: () {
        ref.read(bleScanProvider.notifier).stop();
        _openConnecting(context, ref, AdapterRef(id: device.id, name: device.name));
      },
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: c.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.settings_input_component_rounded, color: c.accent),
          ),
          const SizedBox(width: Space.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name, style: context.text.titleSmall),
                if (lastUsed) Text(l.lastUsed, style: context.text.bodySmall),
              ],
            ),
          ),
          _SignalBars(bars: device.bars),
        ],
      ),
    );
  }
}

/// Signal bars are not mirrored in RTL.
class _SignalBars extends StatelessWidget {
  const _SignalBars({required this.bars});
  final int bars;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: '$bars/3',
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 1; i <= 3; i++)
              Container(
                width: 4,
                height: 6.0 + i * 4,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: i <= bars ? c.textPrimary : c.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProblemView extends ConsumerWidget {
  const _ProblemView({required this.problem});
  final ScanProblem problem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final scan = ref.read(bleScanProvider.notifier);
    void demo() => _openConnecting(context, ref, const AdapterRef.demo());
    return switch (problem) {
      ScanProblem.bluetoothOff => EmptyState(
          icon: Icons.bluetooth_disabled_rounded,
          tone: StatusTone.warn,
          title: l.btOffTitle,
          body: l.btOffBody,
          primaryLabel: Theme.of(context).platform == TargetPlatform.android ? l.turnOn : l.openSettings,
          onPrimary: () async {
            if (Theme.of(context).platform == TargetPlatform.android && await scan.enableBluetooth()) {
              await scan.start();
            } else {
              await openAppSettings();
            }
          },
          secondaryLabel: l.tryDemo,
          onSecondary: demo,
        ),
      ScanProblem.permissionDenied => EmptyState(
          icon: Icons.lock_outline_rounded,
          tone: StatusTone.warn,
          title: l.permTitle,
          body: l.permBody,
          primaryLabel: l.allow,
          onPrimary: scan.start,
          secondaryLabel: l.openSettings,
          onSecondary: openAppSettings,
        ),
      _ => EmptyState(
          icon: Icons.error_outline_rounded,
          tone: StatusTone.warn,
          title: l.errGenericTitle,
          body: l.errGenericBody,
          primaryLabel: l.tryAgain,
          onPrimary: scan.start,
          secondaryLabel: l.tryDemo,
          onSecondary: demo,
        ),
    };
  }
}

/// Three-stage checklist that mirrors the state machine, then the
/// stage-specific error with fix steps.
class ConnectingSheet extends ConsumerWidget {
  const ConnectingSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(connectionProvider);
    ref.listen(connectionProvider, (prev, next) {
      if (next.isReady && context.mounted) Navigator.of(context).maybePop();
    });

    if (s.isError) {
      return Padding(
        padding: const EdgeInsets.only(bottom: Space.l),
        child: ConnectionErrorView(state: s, onChooseAnother: () => Navigator.of(context).pop()),
      );
    }

    int stage = switch (s.phase) {
      ConnPhase.connectingTransport => 0,
      ConnPhase.initializingAdapter => 1,
      ConnPhase.searchingCar => 2,
      ConnPhase.ready => 3,
      _ => 0,
    };
    final steps = [l.stageAdapter, l.stageTalkAdapter, l.stageTalkCar];
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.connectingTo(s.device?.name ?? ''), style: context.text.titleLarge),
          const SizedBox(height: Space.l),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: i < stage
                      ? Icon(Icons.check_circle_rounded, color: context.colors.good)
                      : i == stage
                          ? const Padding(padding: EdgeInsets.all(3), child: CircularProgressIndicator(strokeWidth: 2.5))
                          : Icon(Icons.radio_button_unchecked_rounded, color: context.colors.outline),
                ),
                const SizedBox(width: Space.m),
                Text(steps[i], style: context.text.bodyLarge?.copyWith(color: i > stage ? context.colors.textMuted : null)),
              ]),
            ),
          const SizedBox(height: Space.s),
          Text(l.mayTake15s, style: context.text.bodySmall),
          const SizedBox(height: Space.l),
          OutlinedButton(
            onPressed: () {
              ref.read(connectionProvider.notifier).disconnect();
              Navigator.of(context).pop();
            },
            child: Text(l.cancel),
          ),
        ],
      ),
    );
  }
}
