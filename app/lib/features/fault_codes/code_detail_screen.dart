import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/theme/tokens.dart';
import '../../core/sensor_meta.dart';
import 'codes_screen.dart';
import 'dtc_database.dart';

class CodeDetailScreen extends ConsumerWidget {
  const CodeDetailScreen({super.key, required this.code, this.pending = false});
  final String code;
  final bool pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final info = ref.watch(dtcDatabaseProvider).lookup(code);
    final (label, color, icon) = severityStyle(context, info.severity);
    final vehicle = ref.watch(currentVehicleProvider).valueOrNull;

    Widget section(String title, Widget child) => Padding(
          padding: const EdgeInsets.only(top: Space.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(title, style: context.text.titleSmall), const SizedBox(height: Space.s), child],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: l.share,
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () {
              final car = vehicle == null ? '' : '\n${[vehicle.make, vehicle.modelYear].whereType<Object>().join(' ')}';
              SharePlus.instance.share(ShareParams(text: '$code: ${info.title}\n${info.meaning ?? ''}$car\n— Drivly'));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xxl),
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(code, style: TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w700, color: c.textSecondary)),
          ),
          const SizedBox(height: 4),
          Text(info.title, style: context.text.headlineSmall),
          if (pending) ...[const SizedBox(height: Space.s), ToneLine(text: l.pendingBadge)],
          const SizedBox(height: Space.l),
          Container(
            padding: const EdgeInsets.all(Space.l),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Space.cardRadius),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: color),
              const SizedBox(width: Space.m),
              Expanded(
                child: Text(
                  '${label.toUpperCase()}: ${severityAction(l, info.severity)}. ${info.safeToDrive ?? ''}',
                  style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
          if (info.meaning != null) section(l.whatItMeans, Text(info.meaning!, style: context.text.bodyLarge)),
          if (info.symptoms.isNotEmpty)
            section(
              l.whatYouMightNotice,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final s in info.symptoms) Text('•  $s', style: context.text.bodyLarge)],
              ),
            ),
          if (info.safeToDrive != null) section(l.safeToDrive, Text(info.safeToDrive!, style: context.text.bodyLarge)),
          if (info.causes.isNotEmpty)
            section(
              l.commonCauses,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < info.causes.length; i++) Text('${i + 1}.  ${info.causes[i]}', style: context.text.bodyLarge),
                ],
              ),
            ),
          if (info.action != null) section(l.whatToDo, Text(info.action!, style: context.text.bodyLarge)),
          const SizedBox(height: Space.l),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(l.forYourMechanic, style: context.text.titleSmall),
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    [
                      info.technicalTitle ?? info.title,
                      pending ? l.kindPending : l.kindStored,
                      if (info.manufacturerSpecific) l.manufacturerSpecific,
                    ].join('\n'),
                    style: context.text.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.l),
          OutlinedButton.icon(
            icon: const Icon(Icons.travel_explore_rounded),
            label: Text(l.searchOnline),
            onPressed: () {
              final q = Uri.encodeQueryComponent('$code ${vehicle?.make ?? ''} OBD2');
              launchUrl(Uri.parse('https://duckduckgo.com/?q=$q'), mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
    );
  }
}

class ToneLine extends StatelessWidget {
  const ToneLine({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: context.text.bodySmall?.copyWith(color: context.colors.warn));
}
