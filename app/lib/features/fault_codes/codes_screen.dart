import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:obd_core/obd_core.dart';

import '../../app/theme/tokens.dart';
import '../../core/sensor_meta.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/states.dart';
import '../../shared/widgets/status_pill.dart';
import '../connection/connection_controller.dart';
import '../live/live_data.dart';
import 'dtc_controller.dart';
import 'dtc_database.dart';

(String, Color, IconData) severityStyle(BuildContext context, Severity s) {
  final l = context.l10n;
  final c = context.colors;
  return switch (s) {
    Severity.high => (l.severityHigh, c.danger, Icons.warning_rounded),
    Severity.medium => (l.severityMedium, c.warn, Icons.error_outline_rounded),
    // Minor is neutral: green means "good" everywhere else.
    Severity.minor => (l.severityMinor, c.textSecondary, Icons.info_outline_rounded),
  };
}

String severityAction(AppLocalizations l, Severity s) => switch (s) {
      Severity.high => l.actionHigh,
      Severity.medium => l.actionMedium,
      Severity.minor => l.actionMinor,
    };

class CodesScreen extends ConsumerWidget {
  const CodesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final dtc = ref.watch(dtcControllerProvider);
    final conn = ref.watch(connectionProvider);
    final db = ref.watch(dtcDatabaseProvider);
    final last = dtc.last;

    Widget body;
    if (dtc.scanning && last == null) {
      body = ListView(
        padding: const EdgeInsets.all(Space.l),
        children: [
          Text(l.askingYourCar, style: context.text.bodyMedium),
          const SizedBox(height: Space.m),
          for (var i = 0; i < 3; i++) ...[const Skeleton(height: 92), const SizedBox(height: Space.m)],
        ],
      );
    } else if (last == null) {
      body = Center(
        child: EmptyState(
          icon: Icons.fact_check_outlined,
          title: l.codesNeverTitle,
          body: l.codesNeverBody,
          primaryLabel: conn.isReady ? l.scanNow : l.connect,
          onPrimary: conn.isReady
              ? () => ref.read(dtcControllerProvider.notifier).scan(ScanReason.manual)
              : () => context.push('/connect'),
        ),
      );
    } else {
      final stored = [...last.stored]..sort((a, b) => _cmp(db, a, b));
      final pending = [...last.pending]..sort((a, b) => _cmp(db, a, b));
      body = RefreshIndicator(
        onRefresh: () async {
          if (conn.isReady) await ref.read(dtcControllerProvider.notifier).scan(ScanReason.manual);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
          children: [
            _StatusCard(scan: last, scanning: dtc.scanning, connected: conn.isReady, error: dtc.error),
            if (last.codes.isEmpty && !last.milOn)
              Padding(
                padding: const EdgeInsets.only(top: Space.l),
                child: EmptyState(
                  icon: Icons.verified_rounded,
                  tone: StatusTone.good,
                  title: l.noProblemsTitle,
                  body: l.noProblemsBody(DateFormat.Hm().format(last.at)),
                ),
              ),
            if (last.codes.isEmpty && last.milOn)
              Padding(
                padding: const EdgeInsets.only(top: Space.l),
                child: AppCard(tint: context.colors.warn, child: Text(l.milNoCodes, style: context.text.bodyLarge)),
              ),
            if (stored.isNotEmpty) ...[
              SectionHeader(l.confirmedProblems(stored.length)),
              for (final d in stored) ...[_CodeCard(dtc: d, info: db.lookup(d.code)), const SizedBox(height: Space.s)],
            ],
            if (pending.isNotEmpty) ...[
              SectionHeader(
                l.developingProblems(pending.length),
                trailing: IconButton(
                  tooltip: l.pendingExplainTitle,
                  icon: const Icon(Icons.info_outline_rounded, size: 18),
                  onPressed: () => showAppSheet<void>(
                    context,
                    builder: (ctx) => Padding(
                      padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.pendingExplainTitle, style: ctx.text.titleLarge),
                          const SizedBox(height: Space.s),
                          Text(l.pendingExplainBody, style: ctx.text.bodyLarge),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              for (final d in pending) ...[_CodeCard(dtc: d, info: db.lookup(d.code)), const SizedBox(height: Space.s)],
            ],
            const SizedBox(height: Space.l),
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: Text(l.scanHistory),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/codes/history'),
            ),
            if (last.codes.isNotEmpty && conn.isReady) const _ClearButton(),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tabCodes),
        actions: [
          const StatusPill(),
          IconButton(tooltip: l.settings, icon: const Icon(Icons.settings_outlined), onPressed: () => context.push('/settings')),
          const SizedBox(width: 4),
        ],
      ),
      body: body,
    );
  }

  static int _cmp(DtcDatabase db, Dtc a, Dtc b) {
    final s = db.lookup(a.code).severity.index.compareTo(db.lookup(b.code).severity.index);
    return s != 0 ? s : a.code.compareTo(b.code);
  }
}

class _StatusCard extends ConsumerWidget {
  const _StatusCard({required this.scan, required this.scanning, required this.connected, this.error});
  final DtcScan scan;
  final bool scanning;
  final bool connected;
  final DtcError? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final n = scan.codes.length;
    final (color, icon, title) = scan.milOn
        ? (c.danger, Icons.warning_rounded, l.milOn)
        : n > 0
            ? (c.warn, Icons.error_outline_rounded, l.problemsFound(n))
            : (c.good, Icons.check_circle_rounded, l.noProblemsTitle);
    final when = DateFormat.MMMd().add_Hm().format(scan.at);
    return AppCard(
      tint: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: Space.s),
            Expanded(child: Text(title, style: context.text.titleMedium?.copyWith(color: color))),
          ]),
          const SizedBox(height: 4),
          Text(
            scan.milOn ? '${l.problemsCount(n)} · ${l.checkedAt(when)}' : l.checkedAt(when),
            style: context.text.bodySmall,
          ),
          if (error != null) ...[
            const SizedBox(height: Space.s),
            Text(_errorText(l, error!), style: context.text.bodySmall?.copyWith(color: c.warn)),
          ],
          if (connected) ...[
            const SizedBox(height: Space.m),
            OutlinedButton.icon(
              onPressed: scanning ? null : () => ref.read(dtcControllerProvider.notifier).scan(ScanReason.manual),
              icon: scanning
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded),
              label: Text(scanning ? l.askingYourCar : l.scanAgain),
            ),
          ],
        ],
      ),
    );
  }

  String _errorText(AppLocalizations l, DtcError e) => switch (e) {
        DtcError.notConnected => l.readFailedNotConnected,
        DtcError.carNotResponding => l.readFailedCar,
        DtcError.adapterBusy => l.readFailedBusy,
        DtcError.failed => l.readFailed,
      };
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.dtc, required this.info});
  final Dtc dtc;
  final DtcInfo info;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final (label, color, icon) = severityStyle(context, info.severity);
    return AppCard(
      onTap: () => context.push('/codes/${dtc.code}?kind=${dtc.kind.name}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ToneChip(label: label, color: color, icon: icon, dense: true),
                const SizedBox(height: Space.s),
                Text(info.title, style: context.text.titleMedium),
                const SizedBox(height: 4),
                Row(children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(dtc.code, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                  Text(' · ${severityAction(l, info.severity)}', style: context.text.bodySmall),
                ]),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c.textMuted),
        ],
      ),
    );
  }
}

class _ClearButton extends ConsumerWidget {
  const _ClearButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final live = ref.watch(liveDataProvider);
    return ListenableBuilder(
      listenable: live,
      builder: (context, _) {
        final moving = (live.value(Sensors.speed) ?? 0) > 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: c.danger),
              icon: const Icon(Icons.cleaning_services_outlined),
              label: Text(l.clearCodes),
              onPressed: moving ? null : () => _confirm(context, ref),
            ),
            if (moving)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: Space.l),
                child: Text(l.stopCarFirst, style: context.text.bodySmall),
              ),
          ],
        );
      },
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final c = context.colors;
    final n = ref.read(dtcControllerProvider).last?.codes.length ?? 0;
    final ok = await showAppSheet<bool>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.clearTitle(n), style: ctx.text.titleLarge),
            const SizedBox(height: Space.l),
            for (final t in [l.clearWarn1, l.clearWarn2, l.clearWarn3])
              Padding(
                padding: const EdgeInsets.only(bottom: Space.m),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.info_outline_rounded, size: 20, color: c.textSecondary),
                  const SizedBox(width: Space.m),
                  Expanded(child: Text(t, style: ctx.text.bodyLarge)),
                ]),
              ),
            Text(l.clearSnapshotNote, style: ctx.text.bodySmall),
            const SizedBox(height: Space.l),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: c.danger, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.clearCodes),
            ),
            const SizedBox(height: Space.s),
            OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final result = await ref.read(dtcControllerProvider.notifier).clear();
    if (!context.mounted) return;
    final msg = switch (result) {
      ClearResult.cleared => l.clearDone,
      ClearResult.cameBack => l.clearCameBack(ref.read(dtcControllerProvider).last?.stored.length ?? 1),
      ClearResult.blockedMoving => l.stopCarFirst,
      ClearResult.failed => l.clearFailed,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
