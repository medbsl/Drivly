import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../app/theme/tokens.dart';
import '../../core/sensor_meta.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/states.dart';
import '../history/history_controller.dart';
import 'dtc_controller.dart';

String scanReasonLabel(AppLocalizations l, ScanReason r) => switch (r) {
      ScanReason.auto => l.reasonAuto,
      ScanReason.manual => l.reasonManual,
      ScanReason.beforeClear => l.reasonBeforeClear,
      ScanReason.afterClear => l.reasonAfterClear,
    };

class ScanHistoryScreen extends ConsumerWidget {
  const ScanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final scans = ref.watch(scanHistoryProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(l.scanHistory)),
      body: scans == null
          ? const SizedBox.shrink()
          : scans.isEmpty
              ? Center(child: EmptyState(icon: Icons.history_rounded, title: l.scanHistoryEmpty, body: l.codesNeverBody))
              : ListView.separated(
                  padding: const EdgeInsets.all(Space.l),
                  itemCount: scans.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Space.s),
                  itemBuilder: (context, i) {
                    final s = scans[i];
                    final color = s.milOn ? c.danger : (s.codes.isEmpty ? c.good : c.warn);
                    return AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(s.codes.isEmpty ? Icons.check_circle_rounded : Icons.error_outline_rounded, color: color),
                          const SizedBox(width: Space.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(DateFormat.yMMMd().add_Hm().format(s.at), style: context.text.titleSmall),
                                const SizedBox(height: 2),
                                Text(
                                  '${scanReasonLabel(l, s.reason)}${s.milOn ? ' · ${l.milOn}' : ''}',
                                  style: context.text.bodySmall,
                                ),
                                const SizedBox(height: Space.s),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    s.codes.isEmpty ? l.noCodes : s.codes.map((d) => d.code).join('  '),
                                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
