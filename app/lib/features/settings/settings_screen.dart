import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/theme/tokens.dart';
import '../../core/sensor_meta.dart';
import '../../core/units.dart';
import '../../data/settings.dart';
import '../../shared/widgets/app_card.dart';
import '../../app/router.dart';
import '../connection/connection_controller.dart';

const repoUrl = 'https://github.com/medbsl/Drivly';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final conn = ref.watch(connectionProvider);
    final stats = ref.watch(storageStatsProvider).valueOrNull;

    Widget group(List<Widget> children) => AppCard(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: children));

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xxl),
        children: [
          SectionHeader(l.general),
          group([
            _Choice<SpeedUnit>(
              title: l.unitsSpeed,
              value: s.speedUnit,
              options: const {SpeedUnit.kmh: 'km/h', SpeedUnit.mph: 'mph'},
              onChanged: ctrl.setSpeedUnit,
            ),
            _Choice<TempUnit>(
              title: l.unitsTemp,
              value: s.tempUnit,
              options: const {TempUnit.celsius: '°C', TempUnit.fahrenheit: '°F'},
              onChanged: ctrl.setTempUnit,
            ),
            _Choice<ThemeMode>(
              title: l.theme,
              value: s.themeMode,
              options: {ThemeMode.dark: l.themeDark, ThemeMode.light: l.themeLight, ThemeMode.system: l.themeSystem},
              onChanged: ctrl.setThemeMode,
            ),
            SwitchListTile(
              title: Text(l.keepScreenOn),
              subtitle: Text(l.keepScreenOnHint),
              value: s.keepScreenOn,
              onChanged: ctrl.setKeepScreenOn,
            ),
          ]),
          SectionHeader(l.adapterSection),
          group([
            ListTile(
              title: Text(l.savedAdapter),
              subtitle: Text(s.savedAdapterName ?? l.none),
              trailing: s.savedAdapterId == null
                  ? null
                  : TextButton(
                      onPressed: () {
                        ref.read(connectionProvider.notifier).disconnect();
                        ctrl.forgetAdapter();
                      },
                      child: Text(l.forget),
                    ),
            ),
            SwitchListTile(title: Text(l.connectAutomatically), value: s.autoConnect, onChanged: ctrl.setAutoConnect),
            ListTile(
              title: Text(l.adapterLog),
              subtitle: Text(l.adapterLogHint),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/settings/log'),
            ),
          ]),
          SectionHeader(l.historyAndTrips),
          group([
            SwitchListTile(title: Text(l.recordTrips), value: s.autoRecordTrips, onChanged: ctrl.setAutoRecordTrips),
            ListTile(
              title: Text(l.storedHistory),
              subtitle: Text(stats == null
                  ? '…'
                  : l.storageDetail(
                      formatCount(stats.readings),
                      formatCount(stats.trips),
                      formatBytes(stats.bytes),
                      stats.since == null ? '–' : DateFormat.yMMMd().format(stats.since!),
                    )),
            ),
            ListTile(
              title: Text(l.deleteOlder),
              leading: const Icon(Icons.auto_delete_outlined),
              onTap: () => _confirm(context, l.deleteOlderConfirm, () async {
                await ref.read(historyRepoProvider).deleteOlderThan(DateTime.now().subtract(const Duration(days: 90)));
                ref.read(dataVersionProvider.notifier).bump();
              }),
            ),
            ListTile(
              title: Text(l.deleteAllHistory, style: TextStyle(color: context.colors.danger)),
              leading: Icon(Icons.delete_forever_outlined, color: context.colors.danger),
              onTap: () => _confirm(context, l.deleteAllConfirm, () async {
                await ref.read(historyRepoProvider).deleteAll();
                ref.read(dataVersionProvider.notifier).bump();
              }),
            ),
          ]),
          SectionHeader(l.demo),
          group([
            ListTile(
              leading: const Icon(Icons.play_circle_outline_rounded),
              title: Text(conn.isDemo ? l.demoRunning : l.startDemo),
              subtitle: Text(l.demoHint),
              onTap: conn.isDemo ? null : () => ref.read(connectionProvider.notifier).connectDemo(),
            ),
            if (conn.isDemo && conn.isReady) ...[
              ListTile(
                leading: const Icon(Icons.link_off_rounded),
                title: Text(l.simulateDrop),
                onTap: () => ref.read(connectionProvider.notifier).simulator?.simulateLinkDrop(),
              ),
              ListTile(
                leading: const Icon(Icons.key_off_rounded),
                title: Text(l.simulateIgnitionOff),
                onTap: () {
                  final sim = ref.read(connectionProvider.notifier).simulator;
                  if (sim == null) return;
                  sim.faults.carOff = true;
                  Future<void>.delayed(const Duration(seconds: 6), () => sim.faults.carOff = false);
                },
              ),
            ],
          ]),
          SectionHeader(l.safetyPrivacy),
          group([
            ListTile(
              leading: const Icon(Icons.health_and_safety_outlined),
              title: Text(l.safetyNotice),
              onTap: () => showSafetyNotice(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline_rounded),
              title: Text(l.privacy),
              subtitle: Text(l.privacyBody),
            ),
          ]),
          SectionHeader(l.about),
          group([
            ListTile(title: Text(l.version), trailing: const Text('0.1.0')),
            ListTile(
              title: Text(l.sourceCode),
              subtitle: const Text('GPL-3.0'),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              onTap: () => launchUrl(Uri.parse(repoUrl), mode: LaunchMode.externalApplication),
            ),
            ListTile(title: Text(l.licenses), onTap: () => showLicensePage(context: context, applicationName: 'Drivly')),
            ListTile(
              title: Text(l.showOnboarding),
              onTap: () {
                ctrl.setOnboardingDone(false);
                context.go('/onboarding');
              },
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context, String text, Future<void> Function() action) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok == true) await action();
  }
}

class _Choice<T> extends StatelessWidget {
  const _Choice({required this.title, required this.value, required this.options, required this.onChanged});
  final String title;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.text.bodyLarge)),
          SegmentedButton<T>(
            showSelectedIcon: false,
            segments: [for (final e in options.entries) ButtonSegment(value: e.key, label: Text(e.value))],
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ],
      ),
    );
  }
}

Future<void> showSafetyNotice(BuildContext context, WidgetRef ref) {
  final l = context.l10n;
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.health_and_safety_rounded, color: ctx.colors.accent, size: 36),
      title: Text(l.safetyTitle),
      content: Text(l.safetyBody),
      actions: [
        FilledButton(
          onPressed: () {
            ref.read(settingsProvider.notifier).setSafetyNoticeSeen();
            Navigator.pop(ctx);
          },
          child: Text(l.iUnderstand),
        ),
      ],
    ),
  );
}

class AdapterLogScreen extends ConsumerWidget {
  const AdapterLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final log = ref.watch(adapterLogProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.adapterLog),
        actions: [
          IconButton(
            tooltip: l.share,
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => SharePlus.instance.share(ShareParams(text: log.export())),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: log.stream,
        builder: (context, _) {
          final entries = log.entries.reversed.toList();
          if (entries.isEmpty) return Center(child: Text(l.logEmpty, style: context.text.bodyMedium));
          return ListView.builder(
            padding: const EdgeInsets.all(Space.l),
            itemCount: entries.length,
            itemBuilder: (context, i) => Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                entries[i].toString(),
                style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: context.colors.textSecondary, height: 1.5),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// For callers without a context below the navigator (after a route change).
void showSafetyNoticeGlobal(WidgetRef ref) {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx != null) showSafetyNotice(ctx, ref);
}
