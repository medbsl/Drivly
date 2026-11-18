import 'package:drivly/app/providers.dart';
import 'package:drivly/data/models.dart';
import 'package:drivly/data/repositories.dart';
import 'package:drivly/data/settings.dart';
import 'package:drivly/features/connection/connection_controller.dart';
import 'package:drivly/features/fault_codes/dtc_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obd_core/obd_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/env.dart';

/// "Connected" to a scripted adapter, without a live session.
class _ScriptedConnection extends ConnectionController {
  _ScriptedConnection(this._adapter);
  final DiagnosticAdapter _adapter;

  @override
  ConnState build() => const ConnState(phase: ConnPhase.ready);

  @override
  DiagnosticAdapter? get adapter => _adapter;
}

void main() {
  setUpAll(sqfliteFfiInit);

  test('without a connection: tells the user, saves nothing', () async {
    final (c, _) = await testContainer();
    final scan = await c.read(dtcControllerProvider.notifier).scan(ScanReason.manual);
    expect(scan, isNull);
    expect(c.read(dtcControllerProvider).error, DtcError.notConnected);
    expect(await c.read(dtcRepoProvider).history(), isEmpty);
  });

  test('a manual scan reads stored and pending codes and saves them', () async {
    final (c, _) = await testContainer(transports: (_) => Elm327Simulator(realtime: false));
    await c.read(connectionProvider.notifier).connectBle('AA:BB', 'OBDII');
    final versionBefore = c.read(dataVersionProvider);
    final scan = (await c.read(dtcControllerProvider.notifier).scan(ScanReason.manual))!;
    expect(scan.reason, ScanReason.manual);
    expect(scan.stored.map((d) => d.code), ['P0133']);
    expect(scan.pending.map((d) => d.code), ['P0442']);
    final s = c.read(dtcControllerProvider);
    expect(s.last?.id, scan.id);
    expect(s.scanning, isFalse);
    expect(s.error, isNull);
    expect(c.read(dataVersionProvider), greaterThan(versionBefore), reason: 'lists refresh');
    final saved = await c.read(dtcRepoProvider).history();
    expect(saved.map((s) => s.reason), contains(ScanReason.manual));
  });

  test('the engine light is recorded', () async {
    final car = SimulatedCar()..milOn = true;
    final (c, _) = await testContainer(transports: (_) => Elm327Simulator(realtime: false, car: car));
    await c.read(connectionProvider.notifier).connectBle('AA:BB', 'OBDII');
    final scan = (await c.read(dtcControllerProvider.notifier).scan(ScanReason.manual))!;
    expect(scan.milOn, isTrue);
  });

  group('failures are explained, never saved as "no problems"', () {
    Future<DtcState> scanWith(String? Function(String cmd) reply) async {
      final t = FakeTransport(reply);
      await t.connect();
      final adapter = Elm327Adapter(t, timeoutScale: 0.02);
      final (c, _) = await testContainer(overrides: [connectionProvider.overrideWith(() => _ScriptedConnection(adapter))]);
      final scan = await c.read(dtcControllerProvider.notifier).scan(ScanReason.manual);
      expect(scan, isNull);
      expect(await c.read(dtcRepoProvider).history(), isEmpty);
      return c.read(dtcControllerProvider);
    }

    test('car not answering', () async {
      final s = await scanWith((cmd) => 'UNABLE TO CONNECT');
      expect(s.error, DtcError.carNotResponding);
      expect(s.scanning, isFalse);
    });

    test('adapter silent (timeout) counts as the car not answering', () async {
      final s = await scanWith((cmd) => null);
      expect(s.error, DtcError.carNotResponding);
    });

    test('bus busy twice → adapter busy', () async {
      final s = await scanWith((cmd) => 'BUS BUSY');
      expect(s.error, DtcError.adapterBusy);
    });

    test('a bad engine-light reply fails the scan', () async {
      final s = await scanWith((cmd) => cmd == '0101' ? '41 01' : 'NO DATA');
      expect(s.error, DtcError.failed);
    });
  });

  test('a scan still running when the app shuts down ends quietly', () async {
    final t = FakeTransport(
      (cmd) => cmd == '0101' ? '41 01 81 07 E5 00' : '43 01 33 00 00 00 00',
      delay: const Duration(milliseconds: 60),
    );
    await t.connect();
    final adapter = Elm327Adapter(t, timeoutScale: 0.5);
    final db = await openTestDb();
    addTearDown(db.close);
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(sp),
      databaseProvider.overrideWithValue(db),
      connectionProvider.overrideWith(() => _ScriptedConnection(adapter)),
    ]);
    final scanning = c.read(dtcControllerProvider.notifier).scan(ScanReason.manual);
    c.dispose(); // the car is still answering
    expect(await scanning, isNull, reason: 'no "used after dispose" error');
    expect(await DtcRepository(db).history(), isEmpty);
  });

  test('shows the last saved scan of the current car at startup', () async {
    final (c, db) = await testContainer(prefs: {'lastVehicleId': 'mine'});
    final repo = c.read(dtcRepoProvider);
    await repo.save(vehicleId: 'other', sessionId: null, milOn: false, reason: ScanReason.auto, codes: const []);
    final mine = await repo.save(
      vehicleId: 'mine',
      sessionId: null,
      milOn: true,
      reason: ScanReason.auto,
      codes: const [Dtc('P0300', DtcKind.stored)],
    );
    await repo.save(vehicleId: 'other', sessionId: null, milOn: false, reason: ScanReason.auto, codes: const []);
    final sub = c.listen(dtcControllerProvider, (_, _) {});
    addTearDown(sub.close);
    await until(() => c.read(dtcControllerProvider).last != null, reason: 'loaded from history');
    final s = c.read(dtcControllerProvider);
    expect(s.last!.id, mine.id);
    expect(s.loaded, isTrue);
  });
}
