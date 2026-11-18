import 'package:drivly/app/providers.dart';
import 'package:drivly/data/models.dart';
import 'package:drivly/data/settings.dart';
import 'package:drivly/features/connection/connection_controller.dart';
import 'package:drivly/features/live/live_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obd_core/obd_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/env.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late ProviderContainer c;
  late SimulatedCar car;

  setUp(() async {
    car = SimulatedCar();
    (c, _) = await testContainer(transports: (_) => Elm327Simulator(realtime: false, car: car));
    await c.read(connectionProvider.notifier).connectBle('AA:BB', 'OBDII');
    expect(c.read(connectionProvider).isReady, isTrue);
    await until(() => c.read(connectionProvider.notifier).session?.vehicleOrNull != null, reason: 'session started');
  });

  test('identifies the car by its VIN, remembers it and opens a session', () async {
    final vehicle = c.read(connectionProvider.notifier).session!.vehicleOrNull!;
    expect(vehicle.vin, 'WVWZZZAUZGW123456');
    expect(vehicle.make, 'Volkswagen');
    expect(vehicle.supportedPids, c.read(connectionProvider).info!.supportedPids);
    expect(c.read(settingsProvider).lastVehicleId, vehicle.id);

    final session = (await c.read(historyRepoProvider).sessions()).single;
    expect(session.vehicleId, vehicle.id);
    expect(session.adapterName, 'OBDII');
    expect(session.endedAt, isNull);
  });

  test('polls every supported value into the live view', () async {
    final live = c.read(liveDataProvider);
    await until(() => live.value(Sensors.rpm) != null && live.value(Sensors.coolant) != null, reason: 'first readings');
    expect(live.value(Sensors.rpm), closeTo(car.rpm, 50));
    expect(live.polled, contains(Sensors.speed));
    expect(live.polled, isNot(contains(Sensors.dtcCount)), reason: 'comes with the engine-light reading');
    final unsupported = Sensors.all.where((s) => s.isPid && !c.read(connectionProvider).info!.supportedPids.contains(s.pid));
    expect(live.polled.intersection(unsupported.toSet()), isEmpty);
  });

  test('every reading is saved, and the session is closed with its count', () async {
    final live = c.read(liveDataProvider);
    await until(() => live.sessionReadings > 20, reason: 'some readings');
    final shown = live.sessionReadings;
    await c.read(connectionProvider.notifier).disconnect();

    final repo = c.read(historyRepoProvider);
    final stats = await repo.stats();
    expect(stats.readings, greaterThanOrEqualTo(shown));
    final session = (await repo.sessions()).single;
    expect(session.endedAt, isNotNull);
    expect(session.readingCount, stats.readings);
  });

  test('checks the fault codes automatically and saves the scan', () async {
    final repo = c.read(dtcRepoProvider);
    var scans = <DtcScan>[];
    final end = DateTime.now().add(const Duration(seconds: 5));
    while (scans.isEmpty && DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      scans = await repo.history();
    }
    final scan = scans.single;
    expect(scan.reason, ScanReason.auto);
    expect(scan.stored.map((d) => d.code), ['P0133']);
    expect(scan.pending.map((d) => d.code), ['P0442']);
    final session = c.read(connectionProvider.notifier).session!;
    final row = (await c.read(databaseProvider).db.query('dtc_scans')).single;
    expect(row['vehicle_id'], session.vehicleOrNull!.id);
    expect(row['session_id'], session.sessionIdOrNull);
  });

  test('read-only: every command the app sent to the car was a read', () async {
    await until(() => c.read(liveDataProvider).sessionReadings > 50, reason: 'a busy session');
    await until(() => c.read(adapterLogProvider).entries.any((e) => e.text == '07'), reason: 'code scan');
    await c.read(connectionProvider.notifier).disconnect();
    final log = c.read(adapterLogProvider).entries;
    final sent = log.where((e) => e.direction == LogDirection.tx).map((e) => e.text).toSet();
    expect(sent, containsAll(['ATZ', '0100', '0902', '03', '07']));
    for (final cmd in sent) {
      expect(isReadOnlyCommand(cmd), isTrue, reason: cmd);
    }
    expect(log.where((e) => e.text.startsWith('blocked')), isEmpty);
  });
}
