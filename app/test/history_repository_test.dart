import 'package:drivly/data/database.dart';
import 'package:drivly/data/repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obd_core/obd_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase db;
  late HistoryRepository repo;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfiNoIsolate);
    repo = HistoryRepository(db);
  });
  tearDown(() => db.close());

  test('saves every reading and aggregates into buckets with min/avg/max', () async {
    final session = await repo.startSession(vehicleId: 'v1');
    final t0 = DateTime(2026, 11, 16, 10);
    final readings = [
      for (var i = 0; i < 600; i++) SensorReading(Sensors.speed, (i % 60).toDouble(), t0.add(Duration(seconds: i))),
      for (var i = 0; i < 600; i++) SensorReading(Sensors.rpm, 1000 + i.toDouble(), t0.add(Duration(seconds: i))),
    ];
    await repo.insertReadings(session, readings);

    final series = await repo.series(Sensors.speed, from: t0, to: t0.add(const Duration(minutes: 10)), buckets: 10);
    expect(series, hasLength(10));
    expect(series.first.min, 0);
    expect(series.first.max, 59);
    expect(series.first.avg, closeTo(29.5, 0.001));

    final sums = await repo.summaries(from: t0, to: t0.add(const Duration(hours: 1)));
    expect(sums.map((s) => s.sensor), [Sensors.speed, Sensors.rpm]);
    expect(sums.first.count, 600);

    final stats = await repo.stats();
    expect(stats.readings, 1200);
    expect(stats.sessions, 1);
  });

  test('filters by vehicle', () async {
    final a = await repo.startSession(vehicleId: 'a');
    final b = await repo.startSession(vehicleId: 'b');
    final t = DateTime(2026, 11, 16, 10);
    await repo.insertReadings(a, [SensorReading(Sensors.speed, 10, t)]);
    await repo.insertReadings(b, [SensorReading(Sensors.speed, 90, t)]);
    final onlyA = await repo.series(Sensors.speed, from: t, to: t.add(const Duration(minutes: 1)), vehicleId: 'a');
    expect(onlyA.single.avg, 10);
  });

  test('delete all', () async {
    final s = await repo.startSession(vehicleId: 'v');
    await repo.insertReadings(s, [SensorReading(Sensors.speed, 10, DateTime.now())]);
    await repo.deleteAll();
    expect((await repo.stats()).readings, 0);
  });
}
