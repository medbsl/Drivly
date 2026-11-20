import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obd_core/obd_core.dart';

import '../../core/debug_log.dart';
import '../../core/debug_log_platform.dart';
import '../../data/settings.dart';
import '../connection/connection_controller.dart';

/// The app's debug log. main() overrides it with the file on the phone.
final debugLogProvider = Provider<DebugLog>((ref) => DebugLog(MemoryDebugLogStore()));

/// While Settings › Debug logging is on: makes the adapter log verbose (raw
/// replies) and copies it, and every connection step, into the debug log.
/// Only observes: nothing here talks to the adapter.
final debugRecorderProvider = Provider<void>((ref) {
  if (!ref.watch(settingsProvider.select((s) => s.debugLogging))) return;
  final log = ref.read(debugLogProvider);
  final adapterLog = ref.read(adapterLogProvider);

  log.enabled = true;
  final build = kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug');
  log.add(
    'app',
    'debug logging on · ${DateTime.now().toIso8601String()} · ${platformDescription()} · $build build · '
        'adapter ${ref.read(settingsProvider).savedAdapterName ?? 'none'}',
  );

  adapterLog.verbose = true;
  final sub = adapterLog.stream.listen((e) => log.add('obd', '${_arrow(e.direction)} ${e.text}', at: e.at));

  ref.listen(connectionProvider, (prev, next) {
    if (prev != null && prev.phase == next.phase && prev.detail == next.detail && prev.attempt == next.attempt) return;
    final step = next.phase == ConnPhase.reconnecting ? 'reconnecting (attempt ${next.attempt})' : next.phase.name;
    final detail = next.detail;
    log.add('conn', detail == null || detail.isEmpty ? step : '$step · $detail');
  });

  ref.onDispose(() {
    unawaited(sub.cancel());
    adapterLog.verbose = false;
    unawaited(log.flush());
    log.enabled = false;
  });
});

String _arrow(LogDirection d) => switch (d) {
      LogDirection.tx => '>>',
      LogDirection.rx => '<<',
      LogDirection.info => '--',
    };
