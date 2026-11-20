import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tokens.dart';
import '../../core/sensor_meta.dart';
import '../../shared/widgets/states.dart';
import 'connection_controller.dart';

/// Stage-specific error: says whether to check the adapter or the car (§4.10).
class ConnectionErrorView extends ConsumerWidget {
  const ConnectionErrorView({super.key, required this.state, this.onChooseAnother});
  final ConnState state;
  final VoidCallback? onChooseAnother;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ctrl = ref.read(connectionProvider.notifier);
    final name = state.device?.name ?? 'OBDII';
    final (icon, title, body) = switch (state.phase) {
      ConnPhase.transportFailed => (Icons.bluetooth_disabled_rounded, l.errTransportTitle(name), l.errTransportBody),
      ConnPhase.adapterNotResponding => (Icons.power_off_rounded, l.errAdapterTitle, l.errAdapterBody),
      ConnPhase.carNotResponding => (Icons.no_crash_outlined, l.errCarTitle, l.errCarBody),
      _ => (Icons.error_outline_rounded, l.errGenericTitle, l.errGenericBody),
    };
    final detail = state.detail?.trim() ?? '';
    return EmptyState(
      icon: icon,
      tone: StatusTone.warn,
      title: title,
      body: body,
      primaryLabel: l.tryAgain,
      onPrimary: ctrl.retry,
      secondaryLabel: l.chooseAnother,
      onSecondary: onChooseAnother ??
          () {
            ctrl.disconnect();
            context.push('/connect');
          },
      // What the adapter or car actually said: one screenshot is enough for
      // a bug report, and the full log is a tap away.
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (detail.isNotEmpty)
            SelectableText(
              l.errDetails(detail),
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(color: context.colors.textMuted),
            ),
          TextButton.icon(
            onPressed: () => context.push('/settings/log'),
            icon: const Icon(Icons.receipt_long_rounded, size: 18),
            label: Text(l.adapterLog),
          ),
        ],
      ),
    );
  }
}
