import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_ble/universal_ble.dart';

final _likely = RegExp(r'OBD|ELM|V-?LINK|VGATE|VEEPEAK|OBDLINK|KONNWEI|ICAR|CAR', caseSensitive: false);

@immutable
class FoundDevice {
  const FoundDevice({required this.id, required this.name, required this.rssi});
  final String id;
  final String name;
  final int rssi;

  bool get likely => _likely.hasMatch(name);

  /// 0–3 bars from RSSI.
  int get bars => rssi >= -60 ? 3 : (rssi >= -75 ? 2 : (rssi >= -90 ? 1 : 0));
}

enum ScanProblem { bluetoothOff, permissionDenied, unsupported, failed }

@immutable
class ScanState {
  const ScanState({this.scanning = false, this.devices = const {}, this.problem, this.finished = false});
  final bool scanning;
  final Map<String, FoundDevice> devices;
  final ScanProblem? problem;

  /// The 15 s window ended.
  final bool finished;

  ScanState copyWith({bool? scanning, Map<String, FoundDevice>? devices, ScanProblem? problem, bool clearProblem = false, bool? finished}) =>
      ScanState(
        scanning: scanning ?? this.scanning,
        devices: devices ?? this.devices,
        problem: clearProblem ? null : problem ?? this.problem,
        finished: finished ?? this.finished,
      );
}

final bleScanProvider = NotifierProvider.autoDispose<BleScanController, ScanState>(BleScanController.new);

/// Scans all BLE devices (many clones don't advertise a service UUID) and
/// sorts likely OBD adapters to the top.
class BleScanController extends Notifier<ScanState> {
  StreamSubscription<BleDevice>? _sub;
  Timer? _timeout;

  @override
  ScanState build() {
    ref.onDispose(() {
      _timeout?.cancel();
      _sub?.cancel();
      UniversalBle.stopScan().catchError((_) {});
    });
    return const ScanState();
  }

  Future<void> start() async {
    state = state.copyWith(scanning: true, clearProblem: true, finished: false);
    try {
      var availability = await UniversalBle.getBluetoothAvailabilityState();
      if (availability == AvailabilityState.unknown || availability == AvailabilityState.resetting) {
        availability = await UniversalBle.availabilityStream
            .firstWhere((a) => a != AvailabilityState.unknown && a != AvailabilityState.resetting)
            .timeout(const Duration(seconds: 3), onTimeout: () => availability);
      }
      if (availability == AvailabilityState.poweredOff) return _fail(ScanProblem.bluetoothOff);
      if (availability == AvailabilityState.unauthorized) return _fail(ScanProblem.permissionDenied);
      if (availability == AvailabilityState.unsupported) return _fail(ScanProblem.unsupported);

      if (!await UniversalBle.hasPermissions()) {
        try {
          await UniversalBle.requestPermissions();
        } catch (_) {
          return _fail(ScanProblem.permissionDenied);
        }
      }

      await _sub?.cancel();
      _sub = UniversalBle.scanStream.listen(_onDevice);
      await UniversalBle.startScan();
      _timeout?.cancel();
      _timeout = Timer(const Duration(seconds: 15), stop);
    } catch (e) {
      debugPrint('scan failed: $e');
      _fail(ScanProblem.failed);
    }
  }

  void _onDevice(BleDevice d) {
    final name = (d.name ?? d.rawName ?? '').trim();
    if (name.isEmpty) return;
    final next = Map<String, FoundDevice>.of(state.devices)
      ..[d.deviceId] = FoundDevice(id: d.deviceId, name: name, rssi: d.rssi ?? -100);
    state = state.copyWith(devices: next);
  }

  void _fail(ScanProblem p) => state = state.copyWith(scanning: false, problem: p);

  Future<void> stop() async {
    _timeout?.cancel();
    try {
      await UniversalBle.stopScan();
    } catch (_) {}
    await _sub?.cancel();
    _sub = null;
    state = state.copyWith(scanning: false, finished: true);
  }

  Future<bool> enableBluetooth() async {
    try {
      return await UniversalBle.enableBluetooth();
    } catch (_) {
      return false;
    }
  }
}
