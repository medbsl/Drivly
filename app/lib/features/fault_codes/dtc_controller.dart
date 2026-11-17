import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obd_core/obd_core.dart';

import '../../app/providers.dart';
import '../../data/models.dart';
import '../../data/settings.dart';
import '../connection/connection_controller.dart';
import '../live/live_data.dart';

enum DtcError { notConnected, carNotResponding, adapterBusy, failed }

enum ClearResult { cleared, cameBack, failed, blockedMoving }

@immutable
class DtcState {
  const DtcState({this.last, this.scanning = false, this.clearing = false, this.error, this.clearResult, this.loaded = false});

  final DtcScan? last;
  final bool scanning;
  final bool clearing;
  final DtcError? error;
  final ClearResult? clearResult;

  /// Last scan was loaded from history (may be from an earlier session).
  final bool loaded;

  DtcState copyWith({DtcScan? last, bool? scanning, bool? clearing, DtcError? error, bool clearError = false, ClearResult? clearResult, bool clearClearResult = false}) =>
      DtcState(
        last: last ?? this.last,
        scanning: scanning ?? this.scanning,
        clearing: clearing ?? this.clearing,
        error: clearError ? null : error ?? this.error,
        clearResult: clearClearResult ? null : clearResult ?? this.clearResult,
        loaded: true,
      );
}

final dtcControllerProvider = NotifierProvider<DtcController, DtcState>(DtcController.new);

final scanHistoryProvider = FutureProvider<List<DtcScan>>((ref) {
  ref.watch(dataVersionProvider);
  final vehicleId = ref.watch(settingsProvider.select((s) => s.lastVehicleId));
  return ref.watch(dtcRepoProvider).history(vehicleId: vehicleId);
});

/// Reads (03, 07), explains and clears (04) fault codes. Every scan is saved.
class DtcController extends Notifier<DtcState> {
  @override
  DtcState build() {
    final vehicleId = ref.watch(settingsProvider.select((s) => s.lastVehicleId));
    Future.microtask(() => _loadLast(vehicleId));
    return const DtcState();
  }

  Future<void> _loadLast(String? vehicleId) async {
    final scans = await ref.read(dtcRepoProvider).history(vehicleId: vehicleId, limit: 1);
    if (scans.isNotEmpty && state.last == null) state = state.copyWith(last: scans.first);
  }

  ObdResult<Object?>? _check(ObdResult<Object?> r) => r.isOk ? null : r;

  DtcError _map(ObdResult<Object?> r) => switch (r) {
        CarNotResponding() || TimedOut() => DtcError.carNotResponding,
        AdapterError() => DtcError.adapterBusy,
        _ => DtcError.failed,
      };

  Future<DtcScan?> scan(ScanReason reason) async {
    final conn = ref.read(connectionProvider.notifier);
    final adapter = conn.adapter;
    if (adapter == null || !ref.read(connectionProvider).isReady) {
      state = state.copyWith(error: DtcError.notConnected);
      return null;
    }
    state = state.copyWith(scanning: true, clearError: true);
    final status = await adapter.readMonitorStatus();
    final stored = await adapter.readDtcs(DtcKind.stored);
    final pending = await adapter.readDtcs(DtcKind.pending);
    final failure = _check(stored) ?? _check(status);
    if (failure != null) {
      state = state.copyWith(scanning: false, error: _map(failure));
      return null;
    }
    final session = conn.session;
    final saved = await ref.read(dtcRepoProvider).save(
          vehicleId: session?.vehicleOrNull?.id ?? ref.read(settingsProvider).lastVehicleId,
          sessionId: session?.sessionIdOrNull,
          milOn: status.valueOrNull?.milOn ?? false,
          reason: reason,
          codes: [...stored.valueOrNull ?? const <Dtc>[], ...pending.valueOrNull ?? const <Dtc>[]],
        );
    state = state.copyWith(last: saved, scanning: false);
    ref.read(dataVersionProvider.notifier).bump();
    return saved;
  }

  /// Mode 04, guarded: blocked while moving, snapshot before, re-scan after.
  Future<ClearResult> clear() async {
    final speed = ref.read(liveDataProvider).value(Sensors.speed) ?? 0;
    if (speed > 0) return ClearResult.blockedMoving;
    final adapter = ref.read(connectionProvider.notifier).adapter;
    if (adapter == null) return ClearResult.failed;
    state = state.copyWith(clearing: true, clearClearResult: true);

    final before = state.last;
    if (before != null) {
      await ref.read(dtcRepoProvider).save(
            vehicleId: ref.read(settingsProvider).lastVehicleId,
            sessionId: ref.read(connectionProvider.notifier).session?.sessionIdOrNull,
            milOn: before.milOn,
            reason: ScanReason.beforeClear,
            codes: before.codes,
          );
    }
    final r = await adapter.clearDtcs();
    if (!r.isOk) {
      state = state.copyWith(clearing: false, clearResult: ClearResult.failed);
      return ClearResult.failed;
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final after = await scan(ScanReason.afterClear);
    final result = after == null
        ? ClearResult.failed
        : (after.stored.isEmpty ? ClearResult.cleared : ClearResult.cameBack);
    state = state.copyWith(clearing: false, clearResult: result);
    return result;
  }
}
