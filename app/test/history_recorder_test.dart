import 'package:drivly/data/database.dart';
import 'package:drivly/data/repositories.dart';
import 'package:drivly/features/live/history_recorder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obd_core/obd_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/env.dart';

void main() {
  late AppDatabase db;
  late HistoryRepository repo;
  late String session;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    db = await openTestDb();
    repo = HistoryRepository(db);
    session = await repo.startSession(vehicleId: 'v');
  });
  tearDown(() => db.close());

  SensorReading r(double v) => SensorReading(Sensors.speed, v, DateTime.now());

  test('buffers readings and writes them on flush', () async {
    final rec = HistoryRecorder(repo, session);
    rec.add(r(1));
    rec.add(r(2));
    expect((await repo.stats()).readings, 0, reason: 'nothing written before the flush');
    await rec.flush();
    expect((await repo.stats()).readings, 2);
    expect(rec.saved, 2);
  });

  test('flushes on its own every interval', () async {
    final rec = HistoryRecorder(repo, session, flushEvery: const Duration(milliseconds: 20))..start();
    addTearDown(rec.stop);
    rec.add(r(1));
    await until(() => rec.saved == 1, reason: 'timed flush');
    expect((await repo.stats()).readings, 1);
  });

  test('stop writes whatever is left', () async {
    final rec = HistoryRecorder(repo, session, flushEvery: const Duration(hours: 1))..start();
    for (var i = 0; i < 50; i++) {
      rec.add(r(i.toDouble()));
    }
    await rec.stop();
    expect((await repo.stats()).readings, 50);
    expect(rec.saved, 50);
  });

  test('flushes are written in order, none lost when they overlap', () async {
    final rec = HistoryRecorder(repo, session);
    final writes = <Future<void>>[];
    for (var i = 0; i < 5; i++) {
      rec.add(r(i.toDouble()));
      writes.add(rec.flush());
    }
    await Future.wait(writes);
    expect(rec.saved, 5);
    expect((await repo.stats()).readings, 5);
  });

  test('a failed write does not throw or stop recording', () async {
    final rec = HistoryRecorder(repo, session);
    rec.add(r(1));
    await db.close();
    await rec.flush(); // database gone: logged, not thrown
    expect(rec.saved, 0);
    db = await openTestDb();
  });
}
