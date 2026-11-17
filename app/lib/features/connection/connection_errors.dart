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
    return EmptyState(
      icon: icon,
      tone: StatusTone.warn,
      title: title,
      body: body,
      primaryLabel: l.tryAgain,
      onPrimary: ctrl.retry,
      secondaryLabel: state.phase == ConnPhase.adapterNotResponding ? l.adapterLog : l.chooseAnother,
      onSecondary: state.phase == ConnPhase.adapterNotResponding
          ? () => context.push('/settings/log')
          : (onChooseAnother ??
              () {
                ctrl.disconnect();
                context.push('/connect');
              }),
    );
  }
}
