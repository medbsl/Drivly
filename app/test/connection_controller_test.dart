import 'package:drivly/data/settings.dart';
import 'package:drivly/features/connection/connection_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obd_core/obd_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/env.dart';

/// A Bluetooth device that is out of range.
class _Unreachable extends FakeTransport {
  _Unreachable() : super((_) => null);

  @override
  Future<void> connect({Duration timeout = const Duration(seconds: 10)}) async =>
      throw const TransportException('device not found');
}

/// The car side of every test: one simulated car, a fresh simulator per
/// connection attempt (as a new Bluetooth link would be).
class _Bench {
  final car = SimulatedCar();
  final sims = <Elm327Simulator>[];
  final devices = <AdapterRef>[];
  bool unreachable = false;
  bool silentAdapter = false;

  ObdTransport call(AdapterRef device) {
    devices.add(device);
    if (unreachable) return _Unreachable();
    final sim = Elm327Simulator(realtime: false, car: car);
    sim.faults.adapterSilent = silentAdapter;
    sims.add(sim);
    return sim;
  }
}

void main() {
  setUpAll(sqfliteFfiInit);

  Future<(ProviderContainer, _Bench, List<ConnPhase>)> setup({Map<String, Object> prefs = const {}}) async {
    final bench = _Bench();
    final (c, _) = await testContainer(prefs: prefs, transports: bench.call);
    final phases = <ConnPhase>[];
    final sub = c.listen(connectionProvider, (_, next) => phases.add(next.phase));
    addTearDown(sub.close);
    return (c, bench, phases);
  }

  group('ConnState', () {
    test('flags follow the phase', () {
      const busy = [ConnPhase.connectingTransport, ConnPhase.initializingAdapter, ConnPhase.searchingCar];
      const errors = [ConnPhase.transportFailed, ConnPhase.adapterNotResponding, ConnPhase.carNotResponding];
      for (final p in ConnPhase.values) {
        final s = ConnState(phase: p);
        expect(s.isBusy, busy.contains(p), reason: p.name);
        expect(s.isError, errors.contains(p), reason: p.name);
        expect(s.isReady, p == ConnPhase.ready, reason: p.name);
      }
    });

    test('demo flag and copyWith keep the device', () {
      const s = ConnState(device: AdapterRef.demo(), attempt: 3);
      expect(s.isDemo, isTrue);
      final next = s.copyWith(phase: ConnPhase.ready);
      expect(next.device?.id, AdapterRef.demoId);
      expect(next.attempt, 3);
      expect(const ConnState(device: AdapterRef(id: 'a', name: 'b')).isDemo, isFalse);
    });
  });

  test('connects step by step, then remembers the adapter', () async {
    final (c, bench, phases) = await setup();
    await c.read(connectionProvider.notifier).connectBle('AA:BB', 'OBDII');
    final s = c.read(connectionProvider);
    expect(s.isReady, isTrue);
    expect(phases, [ConnPhase.connectingTransport, ConnPhase.initializingAdapter, ConnPhase.searchingCar, ConnPhase.ready]);
    expect(s.device?.name, 'OBDII');
    expect(s.info?.supportedPids, contains(0x0C));
    expect(s.reconnectedAt, isNull);
    expect(bench.devices.single.id, 'AA:BB');
    final settings = c.read(settingsProvider);
    expect((settings.savedAdapterId, settings.savedAdapterName), ('AA:BB', 'OBDII'));
    expect(c.read(connectionProvider.notifier).session, isNotNull);
  });

  test('adapter out of range → transportFailed, nothing remembered', () async {
    final (c, bench, _) = await setup();
    bench.unreachable = true;
    await c.read(connectionProvider.notifier).connectBle('AA:BB', 'OBDII');
    final s = c.read(connectionProvider);
    expect(s.phase, ConnPhase.transportFailed);
    expect(s.detail, contains('device not found'));
    expect(c.read(settingsProvider).savedAdapterId, isNull);
  });

  test('adapter powered but silent → adapterNotResponding', () async {
    final (c, bench, _) = await setup();
    bench.silentAdapter = true;
    await c.read(connectionProvider.notifier).connectBle('AA:BB', 'OBDII');
    expect(c.read(connectionProvider).phase, ConnPhase.adapterNotResponding);
    expect(bench.sims.single.currentStatus, TransportStatus.disconnected, reason: 'link closed after failing');
  });

  test('ignition off → carNotResponding; "Try again" connects once it is on', () async {
    final (c, bench, _) = await setup();
    bench.car.ignitionOn = false;
    final ctrl = c.read(connectionProvider.notifier);
    await ctrl.connectBle('AA:BB', 'OBDII');
    expect(c.read(connectionProvider).phase, ConnPhase.carNotResponding);
    expect(c.read(connectionProvider).detail, 'UNABLE TO CONNECT', reason: 'what the car said, for the error screen');
    expect(c.read(settingsProvider).savedAdapterId, isNull);

    bench.car.ignitionOn = true;
    await ctrl.retry();
    expect(c.read(connectionProvider).isReady, isTrue);
    expect(bench.devices.map((d) => d.id), ['AA:BB', 'AA:BB']);
  });

  test('a dropped link reconnects on its own and says so', () async {
    final (c, bench, phases) = await setup();
    await c.read(connectionProvider.notifier).connectBle('AA:BB', 'OBDII');
    phases.clear();
    bench.sims.last.simulateLinkDrop();
    await until(() => c.read(connectionProvider).phase == ConnPhase.reconnecting, reason: 'reconnecting');
    expect(c.read(connectionProvider).attempt, 1);
    await until(() => c.read(connectionProvider).isReady, reason: 'back after ~1 s');
    expect(c.read(connectionProvider).reconnectedAt, isNotNull);
    expect(phases.first, ConnPhase.reconnecting);
    expect(phases, isNot(contains(ConnPhase.connectingTransport)), reason: 'the UI keeps showing "reconnecting"');
    expect(bench.sims, hasLength(2));
  });

  test('while the car stays off, retries back off and never give up', () async {
    final (c, bench, _) = await setup();
    await c.read(connectionProvider.notifier).connectBle('AA:BB', 'OBDII');
    bench.car.ignitionOn = false; // poller notices the silence → lost
    await until(() => c.read(connectionProvider).attempt >= 2, reason: 'first retry failed', timeout: const Duration(seconds: 8));
    expect(c.read(connectionProvider).phase, ConnPhase.reconnecting, reason: 'not an error screen');
    bench.car.ignitionOn = true;
    await until(() => c.read(connectionProvider).isReady, reason: 'second retry after 2 s', timeout: const Duration(seconds: 8));
    expect(c.read(connectionProvider).reconnectedAt, isNotNull);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('disconnect closes the link and goes idle', () async {
    final (c, bench, _) = await setup();
    final ctrl = c.read(connectionProvider.notifier);
    await ctrl.connectBle('AA:BB', 'OBDII');
    await ctrl.disconnect();
    expect(c.read(connectionProvider).phase, ConnPhase.idle);
    expect(bench.sims.single.currentStatus, TransportStatus.disconnected);
    expect(ctrl.adapter, isNull);
    expect(ctrl.session, isNull);
  });

  test('disconnecting while connecting wins: no late "ready"', () async {
    final (c, _, _) = await setup();
    final ctrl = c.read(connectionProvider.notifier);
    final connecting = ctrl.connectBle('AA:BB', 'OBDII');
    await ctrl.disconnect();
    await connecting;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(c.read(connectionProvider).phase, ConnPhase.idle);
  });

  group('auto-connect on launch', () {
    test('connects straight to the saved adapter', () async {
      final (c, bench, _) = await setup(prefs: {'savedAdapterId': 'AA:BB', 'savedAdapterName': 'OBDII'});
      await c.read(connectionProvider.notifier).autoConnect();
      expect(c.read(connectionProvider).isReady, isTrue);
      expect(bench.devices.single.name, 'OBDII');
    });

    test('does nothing without a saved adapter', () async {
      final (c, bench, _) = await setup();
      await c.read(connectionProvider.notifier).autoConnect();
      await c.read(connectionProvider.notifier).autoConnectNow();
      expect(c.read(connectionProvider).phase, ConnPhase.idle);
      expect(bench.devices, isEmpty);
    });

    test('respects the setting, but the Connect button still works', () async {
      final (c, bench, _) = await setup(prefs: {'savedAdapterId': 'AA:BB', 'savedAdapterName': 'OBDII', 'autoConnect': false});
      final ctrl = c.read(connectionProvider.notifier);
      await ctrl.autoConnect();
      expect(bench.devices, isEmpty);
      await ctrl.autoConnectNow();
      expect(c.read(connectionProvider).isReady, isTrue);
    });

    test('is ignored when a connection is already under way', () async {
      final (c, bench, _) = await setup(prefs: {'savedAdapterId': 'AA:BB', 'savedAdapterName': 'OBDII'});
      final ctrl = c.read(connectionProvider.notifier);
      await ctrl.connectBle('CC:DD', 'Other');
      await ctrl.autoConnect();
      expect(bench.devices.map((d) => d.id), ['CC:DD']);
    });

    test('a saved demo adapter starts the demo', () async {
      final (c, bench, _) = await setup(prefs: {'savedAdapterId': AdapterRef.demoId});
      bench.unreachable = true; // routing only: no demo session needed
      await c.read(connectionProvider.notifier).autoConnect();
      expect(bench.devices.single.demo, isTrue);
      expect(c.read(connectionProvider).isDemo, isTrue);
    });
  });
}
