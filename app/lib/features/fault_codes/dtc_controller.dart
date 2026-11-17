import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obd_core/obd_core.dart';

import '../../app/providers.dart';
import '../../data/models.dart';
import '../../data/settings.dart';
import '../connection/connection_controller.dart';

enum DtcError { notConnected, carNotResponding, adapterBusy, failed }

@immutable
class DtcState {
  const DtcState({this.last, this.scanning = false, this.error, this.loaded = false});

  final DtcScan? last;
  final bool scanning;
  final DtcError? error;

  /// Last scan was loaded from history (may be from an earlier session).
  final bool loaded;

  DtcState copyWith({DtcScan? last, bool? scanning, DtcError? error, bool clearError = false}) => DtcState(
        last: last ?? this.last,
        scanning: scanning ?? this.scanning,
        error: clearError ? null : error ?? this.error,
        loaded: true,
      );
}

final dtcControllerProvider = NotifierProvider<DtcController, DtcState>(DtcController.new);

final scanHistoryProvider = FutureProvider<List<DtcScan>>((ref) {
  ref.watch(dataVersionProvider);
  final vehicleId = ref.watch(settingsProvider.select((s) => s.lastVehicleId));
  return ref.watch(dtcRepoProvider).history(vehicleId: vehicleId);
});

/// Reads (03, 07) and explains fault codes. Every scan is saved.
///
/// Read-only: Drivly never clears codes or changes anything in the car
/// (docs/adr/0002-read-only.md).
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
}
