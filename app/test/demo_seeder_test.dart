import 'package:drivly/data/database.dart';
import 'package:drivly/data/repositories.dart';
import 'package:drivly/features/live/demo_seeder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obd_core/obd_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/env.dart';

void main() {
  late AppDatabase db;
  setUpAll(sqfliteFfiInit);
  setUp(() async => db = await openTestDb());
  tearDown(() => db.close());

  test('fills past days with ended sessions, readings and trips for the demo car only', () async {
    final history = HistoryRepository(db);
    final trips = TripRepository(db);
    final pids = {0x0C, 0x0D, 0x05, 0x04, 0x2F};
    await DemoSeeder(history: history, trips: trips).seed(vehicleId: 'demo', supportedPids: pids, drives: 2);

    final sessions = await history.sessions();
    expect(sessions, hasLength(2));
    final today = DateTime.now();
    for (final s in sessions) {
      expect(s.vehicleId, 'demo');
      expect(s.demo, isTrue);
      expect(s.endedAt, isNotNull);
      expect(s.startedAt.isBefore(DateTime(today.year, today.month, today.day)), isTrue, reason: 'past days only');
    }

    final seeded = await trips.list();
    expect(seeded, hasLength(2));
    for (final t in seeded) {
      expect(t.vehicleId, 'demo');
      expect(t.distanceKm, greaterThan(1));
      expect(t.maxSpeed, greaterThan(t.avgSpeed));
    }

    final summaries = await history.summaries(from: DateTime(2000), to: today);
    final seen = summaries.map((s) => s.sensor).toSet();
    expect(seen, containsAll([Sensors.speed, Sensors.rpm, Sensors.coolant, Sensors.battery, Sensors.load]));
    expect(seen.where((s) => s.isPid && !pids.contains(s.pid)), isEmpty, reason: 'only what the car supports');
  });
}
