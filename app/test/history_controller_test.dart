import 'package:drivly/app/providers.dart';
import 'package:drivly/data/models.dart';
import 'package:drivly/data/repositories.dart';
import 'package:drivly/data/settings.dart';
import 'package:drivly/features/history/history_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obd_core/obd_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/env.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('defaults to the last day of speed', () async {
    final (c, _) = await testContainer();
    final sel = c.read(historySelectionProvider);
    expect(sel.range, HistoryRange.day);
    expect(sel.sensor, Sensors.speed);
    final w = c.read(historyWindowProvider);
    expect(w.to.difference(w.from), const Duration(hours: 24));
  });

  test('changing range moves the window, picking a sensor does not', () async {
    final (c, _) = await testContainer();
    final ctrl = c.read(historySelectionProvider.notifier);
    ctrl.setRange(HistoryRange.week);
    final w = c.read(historyWindowProvider);
    expect(w.to.difference(w.from), const Duration(days: 7));
    final anchor = c.read(historySelectionProvider).anchor;
    ctrl.select(Sensors.coolant);
    expect(c.read(historySelectionProvider).sensor, Sensors.coolant);
    expect(c.read(historySelectionProvider).anchor, anchor);
  });

  test('the anchor is whole seconds, so provider keys stay stable', () async {
    final (c, _) = await testContainer();
    final a = c.read(historySelectionProvider).anchor;
    expect(a.millisecond, 0);
    expect(a.microsecond, 0);
    expect(a.isAfter(DateTime.now()), isTrue);
  });

  test('"All" starts at the first saved session, or 30 days back when empty', () async {
    final (c, db) = await testContainer(prefs: {'lastVehicleId': 'v'});
    c.read(historySelectionProvider.notifier).setRange(HistoryRange.all);
    final sub = c.listen(firstReadingProvider, (_, _) {});
    addTearDown(sub.close);
    await c.read(firstReadingProvider.future);
    var w = c.read(historyWindowProvider);
    expect(w.to.difference(w.from), const Duration(days: 30));
    expect(w.vehicleId, 'v');

    final first = DateTime(2026, 3, 1);
    await HistoryRepository(db).startSession(vehicleId: 'v', at: first);
    c.read(dataVersionProvider.notifier).bump();
    await c.read(firstReadingProvider.future);
    w = c.read(historyWindowProvider);
    expect(w.from, first);
  });

  test('lists re-read after a write bumps the data version', () async {
    final (c, db) = await testContainer(prefs: {'lastVehicleId': 'v'});
    final sub = c.listen(recentTripsProvider, (_, _) {});
    addTearDown(sub.close);
    expect(await c.read(recentTripsProvider.future), isEmpty);
    final t = DateTime(2026, 11, 16, 8);
    await TripRepository(db).insert(Trip(
      id: 't',
      vehicleId: 'v',
      startedAt: t,
      endedAt: t.add(const Duration(minutes: 10)),
      distanceKm: 5,
      maxSpeed: 50,
      avgSpeed: 30,
    ));
    c.read(dataVersionProvider.notifier).bump();
    expect((await c.read(recentTripsProvider.future)).single.id, 't');
  });

  test('the current car is the last one connected, else the most recent', () async {
    final (c, db) = await testContainer();
    expect(await c.read(currentVehicleProvider.future), isNull);
    final repo = VehicleRepository(db);
    const info = AdapterInfo(elmVersion: 'ELM327 v1.5', protocol: null, supportedPids: {0x0C}, multiPid: false);
    await repo.upsertFromConnection(fallbackKey: 'adapter:A', info: info);
    await Future<void>.delayed(const Duration(milliseconds: 3));
    await repo.upsertFromConnection(fallbackKey: 'adapter:B', info: info);
    c.read(dataVersionProvider.notifier).bump();
    expect((await c.read(currentVehicleProvider.future))!.id, 'adapter:B', reason: 'most recent');

    c.read(settingsProvider.notifier).setLastVehicle('adapter:A');
    expect((await c.read(currentVehicleProvider.future))!.id, 'adapter:A', reason: 'last connected');

    c.read(settingsProvider.notifier).setLastVehicle('deleted');
    expect((await c.read(currentVehicleProvider.future))!.id, 'adapter:B', reason: 'unknown id falls back');
  });
}
