import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obd_core/obd_core.dart';

import '../../data/settings.dart';
import '../live/live_session.dart';
import 'ble_transport.dart';

/// Single source of truth for every connection-related UI state (§2.4).
enum ConnPhase {
  idle,
  connectingTransport,
  initializingAdapter,
  searchingCar,
  ready,
  transportFailed,
  adapterNotResponding,
  carNotResponding,
  reconnecting,
}

@immutable
class AdapterRef {
  const AdapterRef({required this.id, required this.name, this.demo = false});
  const AdapterRef.demo()
      : id = demoId,
        name = 'Drivly Demo',
        demo = true;

  static const demoId = 'demo';
  final String id;
  final String name;
  final bool demo;
}

@immutable
class ConnState {
  const ConnState({
    this.phase = ConnPhase.idle,
    this.device,
    this.info,
    this.attempt = 0,
    this.detail,
    this.reconnectedAt,
  });

  final ConnPhase phase;
  final AdapterRef? device;
  final AdapterInfo? info;
  final int attempt;
  final String? detail;

  /// Set when a lost link came back; the UI shows "Reconnected" briefly.
  final DateTime? reconnectedAt;

  bool get isReady => phase == ConnPhase.ready;
  bool get isDemo => device?.demo ?? false;
  bool get isBusy =>
      phase == ConnPhase.connectingTransport ||
      phase == ConnPhase.initializingAdapter ||
      phase == ConnPhase.searchingCar;
  bool get isError =>
      phase == ConnPhase.transportFailed || phase == ConnPhase.adapterNotResponding || phase == ConnPhase.carNotResponding;

  ConnState copyWith({ConnPhase? phase, AdapterInfo? info, int? attempt, String? detail, DateTime? reconnectedAt}) => ConnState(
        phase: phase ?? this.phase,
        device: device,
        info: info ?? this.info,
        attempt: attempt ?? this.attempt,
        detail: detail ?? this.detail,
        reconnectedAt: reconnectedAt ?? this.reconnectedAt,
      );
}

final connectionProvider = NotifierProvider<ConnectionController, ConnState>(ConnectionController.new);

/// Shared raw TX/RX log (Settings → Adapter log).
final adapterLogProvider = Provider<AdapterLog>((ref) => AdapterLog());

/// Makes the transport for a connection: the simulator for the demo (one
/// simulated car per app run, so the demo drive carries on after a
/// reconnect), Bluetooth LE otherwise. Tests override it.
final transportFactoryProvider = Provider<ObdTransport Function(AdapterRef device)>((ref) {
  SimulatedCar? demoCar;
  return (device) => device.demo
      ? Elm327Simulator(car: demoCar ??= SimulatedCar(seed: Random().nextInt(1 << 20)))
      : BleTransport(deviceId: device.id, deviceName: device.name);
});

/// Scales every adapter timeout: 1.0 in the app. Tests shrink it so a silent
/// adapter fails in milliseconds instead of seconds.
final adapterTimeoutScaleProvider = Provider<double>((ref) => 1.0);

class ConnectionController extends Notifier<ConnState> {
  ObdTransport? _transport;
  Elm327Adapter? _adapter;
  LiveSession? _session;
  StreamSubscription<TransportStatus>? _statusSub;
  Timer? _retryTimer;
  int _generation = 0;

  static const _backoff = [1, 2, 5, 10, 15];

  @override
  ConnState build() {
    ref.onDispose(() {
      _generation++;
      _retryTimer?.cancel();
      unawaited(_teardown());
    });
    return const ConnState();
  }

  DiagnosticAdapter? get adapter => _adapter;
  LiveSession? get session => _session;

  Future<void> connectDemo() => _connect(const AdapterRef.demo());

  Future<void> connectBle(String id, String name) => _connect(AdapterRef(id: id, name: name));

  /// On launch: connect straight to the saved adapter, no scan.
  Future<void> autoConnect() async {
    final s = ref.read(settingsProvider);
    if (!s.autoConnect || state.phase != ConnPhase.idle) return;
    final id = s.savedAdapterId;
    if (id == null) return;
    if (id == AdapterRef.demoId) return connectDemo();
    return connectBle(id, s.savedAdapterName ?? 'OBDII');
  }

  /// "Connect" on Home: the saved adapter, whatever the auto-connect setting.
  Future<void> autoConnectNow() async {
    final s = ref.read(settingsProvider);
    final id = s.savedAdapterId;
    if (id == null) return;
    if (id == AdapterRef.demoId) return connectDemo();
    return connectBle(id, s.savedAdapterName ?? 'OBDII');
  }

  Future<void> retry() async {
    final d = state.device;
    if (d != null) await _connect(d);
  }

  Future<void> disconnect() async {
    _generation++;
    _retryTimer?.cancel();
    await _teardown();
    state = const ConnState();
  }

  Future<void> _connect(AdapterRef device, {bool reconnect = false}) async {
    final gen = ++_generation;
    _retryTimer?.cancel();
    await _teardown();
    if (gen != _generation) return;
    state = ConnState(
      phase: reconnect ? ConnPhase.reconnecting : ConnPhase.connectingTransport,
      device: device,
      attempt: reconnect ? state.attempt : 0,
    );

    final transport = ref.read(transportFactoryProvider)(device);
    _transport = transport;
    try {
      await transport.connect(timeout: const Duration(seconds: 10));
    } catch (e) {
      if (gen != _generation) return;
      _transport = null;
      if (reconnect) return _scheduleReconnect(gen);
      state = state.copyWith(phase: ConnPhase.transportFailed, detail: '$e');
      return;
    }
    if (gen != _generation) {
      unawaited(transport.disconnect());
      return;
    }

    _statusSub = transport.status.listen((s) {
      if (s == TransportStatus.disconnected && gen == _generation && state.isReady) _onLost(gen);
    });

    final adapter = Elm327Adapter(
      transport,
      log: ref.read(adapterLogProvider),
      timeoutScale: ref.read(adapterTimeoutScaleProvider),
    );
    _adapter = adapter;
    if (!reconnect) state = state.copyWith(phase: ConnPhase.initializingAdapter);
    final result = await adapter.initialize(onStage: (stage) {
      if (gen == _generation && stage == InitStage.car && !reconnect) {
        state = state.copyWith(phase: ConnPhase.searchingCar);
      }
    });
    if (gen != _generation) return;

    switch (result) {
      case Ok(:final value):
        ref.read(settingsProvider.notifier).saveAdapter(device.id, device.name);
        final session = LiveSession(ref: ref, adapter: adapter, info: value, device: device, onLost: () => _onLost(gen));
        _session = session;
        state = ConnState(
          phase: ConnPhase.ready,
          device: device,
          info: value,
          reconnectedAt: reconnect ? DateTime.now() : null,
        );
        await session.start();
      case InitFailed(:final reason, :final detail):
        await _teardown();
        if (reconnect) return _scheduleReconnect(gen);
        state = state.copyWith(
          phase: reason == InitFailure.adapterNotResponding ? ConnPhase.adapterNotResponding : ConnPhase.carNotResponding,
          detail: detail,
        );
      default:
        await _teardown();
        if (reconnect) return _scheduleReconnect(gen);
        state = state.copyWith(phase: ConnPhase.adapterNotResponding, detail: result.toString());
    }
  }

  void _onLost(int gen) {
    if (gen != _generation || !state.isReady) return;
    final s = _session;
    _session = null;
    unawaited(s?.stop());
    state = state.copyWith(phase: ConnPhase.reconnecting, attempt: 0);
    _scheduleReconnect(gen);
  }

  /// Retry at 1 s, 2 s, 5 s, 10 s, then every 15 s while in the foreground.
  void _scheduleReconnect(int gen) {
    if (gen != _generation) return;
    final attempt = state.attempt;
    final delay = Duration(seconds: _backoff[min(attempt, _backoff.length - 1)]);
    state = state.copyWith(phase: ConnPhase.reconnecting, attempt: attempt + 1);
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      final d = state.device;
      if (gen == _generation && d != null) unawaited(_connect(d, reconnect: true));
    });
  }

  Future<void> _teardown() async {
    await _statusSub?.cancel();
    _statusSub = null;
    final s = _session;
    _session = null;
    await s?.stop();
    final a = _adapter;
    _adapter = null;
    await a?.close();
    final t = _transport;
    _transport = null;
    try {
      await t?.disconnect();
    } catch (_) {}
  }

  /// Demo only: inject faults to show error and reconnect states.
  Elm327Simulator? get simulator => _transport is Elm327Simulator ? _transport as Elm327Simulator : null;
}
