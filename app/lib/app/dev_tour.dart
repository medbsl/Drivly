import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obd_core/obd_core.dart';

import '../features/history/history_controller.dart';
import 'router.dart';

/// Dev only (`--dart-define=DRIVLY_TOUR=true`): cycles through the screens
/// so screenshots can be taken without touching the device.
const devTour = bool.fromEnvironment('DRIVLY_TOUR');

Timer startDevTour(WidgetRef ref) {
  final steps = <void Function()>[
    () => ref.read(routerProvider).go('/dashboard'),
    () {
      ref.read(historySelectionProvider.notifier).setRange(HistoryRange.live);
      ref.read(historySelectionProvider.notifier).select(Sensors.rpm);
      ref.read(routerProvider).go('/history');
    },
    () {
      ref.read(historySelectionProvider.notifier).setRange(HistoryRange.week);
      ref.read(historySelectionProvider.notifier).select(Sensors.speed);
    },
    () => ref.read(historySelectionProvider.notifier).select(Sensors.coolant),
    () => ref.read(routerProvider).go('/codes'),
    () => ref.read(routerProvider).go('/car'),
    () => ref.read(routerProvider).push('/settings'),
  ];
  var i = 0;
  return Timer.periodic(const Duration(seconds: 7), (_) {
    steps[i % steps.length]();
    i++;
  });
}
