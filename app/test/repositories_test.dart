import 'package:drivly/data/database.dart';
import 'package:drivly/data/models.dart';
import 'package:drivly/data/repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obd_core/obd_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/env.dart';

const _info = AdapterInfo(
  elmVersion: 'ELM327 v1.5',
  protocol: ObdProtocol.can11x500,
  supportedPids: {0x0C, 0x0D, 0x05, 0xA6},
  multiPid: true,
);

Trip _trip(String id, String vehicle, DateTime start, {double km = 10}) => Trip(
      id: id,
      vehicleId: vehicle,
      startedAt: start,
      endedAt: start.add(const Duration(minutes: 20)),
      distanceKm: km,
      maxSpeed: 90,
      avgSpeed: 30,
    );

void main() {
  late AppDatabase db;

  setUpAll(sqfliteFfiInit);
  setUp(() async => db = await openTestDb());
  tearDown(() => db.close());

  group('VehicleRepository', () {
    test('a car that shares its VIN is identified and decoded offline', () async {
      final repo = VehicleRepository(db);
      final v = await repo.upsertFromConnection(vin: 'WVWZZZAUZGW123456', fallbackKey: 'adapter:x', info: _info);
      expect(v.vin, 'WVWZZZAUZGW123456');
      expect(v.make, 'Volkswagen');
      expect(v.country, 'Germany');
      expect(v.modelYear, 2016);
      expect(v.obdProtocol, ObdProtocol.can11x500);
      expect(v.supportedPids, _info.supportedPids);
      expect(v.id, isNot('adapter:x'));
    });

    test('the same VIN reconnecting updates the car instead of adding one', () async {
      final repo = VehicleRepository(db);
      final a = await repo.upsertFromConnection(vin: 'WVWZZZAUZGW123456', fallbackKey: 'adapter:x', info: _info);
      const later = AdapterInfo(elmVersion: 'ELM327 v2.1', protocol: ObdProtocol.can29x500, supportedPids: {0x0C}, multiPid: true);
      final b = await repo.upsertFromConnection(vin: 'WVWZZZAUZGW123456', fallbackKey: 'adapter:y', info: later);
      expect(b.id, a.id);
      expect(b.obdProtocol, ObdProtocol.can29x500);
      expect(b.supportedPids, {0x0C});
      expect(await repo.all(), hasLength(1));
    });

    test('without a VIN the car is keyed by adapter', () async {
      final repo = VehicleRepository(db);
      final a = await repo.upsertFromConnection(fallbackKey: 'adapter:AA', info: _info);
      final again = await repo.upsertFromConnection(fallbackKey: 'adapter:AA', info: _info);
      final other = await repo.upsertFromConnection(fallbackKey: 'adapter:BB', info: _info);
      expect(a.id, 'adapter:AA');
      expect(again.id, a.id);
      expect(other.id, 'adapter:BB');
      expect(a.vin, isNull);
      expect(a.make, isNull);
      expect(await repo.all(), hasLength(2));
    });

    test('the demo car is flagged', () async {
      final v = await VehicleRepository(db).upsertFromConnection(fallbackKey: 'demo', info: _info, demo: true);
      expect(v.demo, isTrue);
    });

    test('user edits: nickname, model, year, VIN; empty text clears', () async {
      final repo = VehicleRepository(db);
      final v = await repo.upsertFromConnection(fallbackKey: 'adapter:AA', info: _info);
      await repo.update(v.id, nickname: 'Daily', modelUser: 'Golf', modelYear: 2015);
      var got = (await repo.byId(v.id))!;
      expect(got.nickname, 'Daily');
      expect(got.modelUser, 'Golf');
      expect(got.modelYear, 2015);
      expect(got.modelYearCertain, isTrue);

      await repo.update(v.id, nickname: '', modelUser: '');
      got = (await repo.byId(v.id))!;
      expect(got.nickname, isNull);
      expect(got.modelUser, isNull);
      expect(got.modelYear, 2015, reason: 'untouched');

      await repo.update(v.id, vin: 'WVWZZZAUZGW123456');
      got = (await repo.byId(v.id))!;
      expect(got.vin, 'WVWZZZAUZGW123456');
      expect(got.make, 'Volkswagen');
    });

    test('unknown id → null', () async {
      expect(await VehicleRepository(db).byId('nope'), isNull);
    });
  });

  group('DtcRepository', () {
    test('saves a scan with its codes and reads it back', () async {
      final repo = DtcRepository(db);
      final saved = await repo.save(
        vehicleId: 'v1',
        sessionId: 's1',
        milOn: true,
        reason: ScanReason.auto,
        codes: const [Dtc('P0133', DtcKind.stored, ecu: '7E8'), Dtc('P0442', DtcKind.pending)],
      );
      final back = (await repo.history(vehicleId: 'v1')).single;
      expect(back.id, saved.id);
      expect(back.milOn, isTrue);
      expect(back.reason, ScanReason.auto);
      expect(back.stored.single.code, 'P0133');
      expect(back.stored.single.ecu, '7E8');
      expect(back.pending.single.code, 'P0442');
      expect(back.at.millisecondsSinceEpoch, saved.at.millisecondsSinceEpoch);
    });

    test('a scan with no codes is still saved: "all clear" is history too', () async {
      final repo = DtcRepository(db);
      await repo.save(vehicleId: 'v1', sessionId: null, milOn: false, reason: ScanReason.manual, codes: const []);
      final back = (await repo.history()).single;
      expect(back.codes, isEmpty);
      expect(back.reason, ScanReason.manual);
    });

    test('newest first, filtered by car, limited', () async {
      final repo = DtcRepository(db);
      for (var i = 0; i < 3; i++) {
        await repo.save(vehicleId: 'a', sessionId: null, milOn: false, reason: ScanReason.auto, codes: [Dtc('P010$i', DtcKind.stored)]);
        await Future<void>.delayed(const Duration(milliseconds: 3));
      }
      await repo.save(vehicleId: 'b', sessionId: null, milOn: false, reason: ScanReason.auto, codes: const []);
      final a = await repo.history(vehicleId: 'a');
      expect(a.map((s) => s.codes.single.code), ['P0102', 'P0101', 'P0100']);
      expect(await repo.history(vehicleId: 'a', limit: 1), hasLength(1));
      expect(await repo.history(), hasLength(4));
    });

    test('scans saved before the read-only change still load', () async {
      await db.db.insert('dtc_scans', {'id': 'old', 'vehicle_id': 'v', 'at': 1, 'mil_on': 0, 'reason': 'afterClear'});
      final back = (await DtcRepository(db).history()).single;
      expect(back.reason, ScanReason.afterClear);
    });
  });

  group('TripRepository', () {
    test('insert, list newest first, by id, delete', () async {
      final repo = TripRepository(db);
      final t0 = DateTime(2026, 11, 10, 8);
      await repo.insert(_trip('t1', 'v', t0));
      await repo.insert(_trip('t2', 'v', t0.add(const Duration(days: 1))));
      await repo.insert(_trip('t3', 'other', t0.add(const Duration(days: 2))));

      expect((await repo.list()).map((t) => t.id), ['t3', 't2', 't1']);
      expect((await repo.list(vehicleId: 'v')).map((t) => t.id), ['t2', 't1']);
      expect((await repo.list(from: t0.add(const Duration(hours: 1)))).map((t) => t.id), ['t3', 't2']);
      expect((await repo.list(limit: 1)).single.id, 't3');
      expect((await repo.byId('t2'))!.distanceKm, 10);
      expect(await repo.byId('missing'), isNull);

      await repo.delete('t2');
      expect((await repo.list()).map((t) => t.id), ['t3', 't1']);
      await repo.deleteAll();
      expect(await repo.list(), isEmpty);
    });
  });

  group('HistoryRepository', () {
    test('sessions: start, end with reading count, newest first', () async {
      final repo = HistoryRepository(db);
      final t0 = DateTime(2026, 11, 16, 9);
      final a = await repo.startSession(vehicleId: 'v', adapterName: 'OBDII', at: t0);
      await repo.endSession(a, 1234, at: t0.add(const Duration(minutes: 30)));
      final b = await repo.startSession(vehicleId: 'v', demo: true, at: t0.add(const Duration(hours: 1)));

      final list = await repo.sessions(vehicleId: 'v');
      expect(list.map((s) => s.id), [b, a]);
      expect(list.last.readingCount, 1234);
      expect(list.last.endedAt, t0.add(const Duration(minutes: 30)));
      expect(list.last.adapterName, 'OBDII');
      expect(list.first.endedAt, isNull, reason: 'still connected');
      expect(list.first.demo, isTrue);
      expect(await repo.firstReadingAt(vehicleId: 'v'), t0);
      expect(await repo.firstReadingAt(vehicleId: 'other'), isNull);
    });

    test('summaries: min / avg / max per sensor, in sensor order', () async {
      final repo = HistoryRepository(db);
      final s = await repo.startSession(vehicleId: 'v');
      final t = DateTime(2026, 11, 16, 10);
      await repo.insertReadings(s, [
        SensorReading(Sensors.coolant, 80, t),
        SensorReading(Sensors.coolant, 90, t.add(const Duration(seconds: 1))),
        SensorReading(Sensors.speed, 30, t),
        SensorReading(Sensors.speed, 50, t.add(const Duration(seconds: 1))),
        SensorReading(Sensors.speed, 999, t.add(const Duration(hours: 2))), // outside the window
      ]);
      final out = await repo.summaries(from: t, to: t.add(const Duration(hours: 1)));
      expect(out.map((e) => e.sensor), [Sensors.speed, Sensors.coolant]);
      final speed = out.first;
      expect((speed.count, speed.min, speed.avg, speed.max), (2, 30.0, 40.0, 50.0));
    });

    test('series never uses buckets shorter than a second', () async {
      final repo = HistoryRepository(db);
      final s = await repo.startSession(vehicleId: 'v');
      final t = DateTime(2026, 11, 16, 10);
      await repo.insertReadings(s, [
        for (var i = 0; i < 10; i++) SensorReading(Sensors.rpm, 1000.0 + i, t.add(Duration(milliseconds: 100 * i))),
      ]);
      final pts = await repo.series(Sensors.rpm, from: t, to: t.add(const Duration(seconds: 1)), buckets: 100);
      expect(pts, hasLength(1));
      expect(pts.single.min, 1000);
      expect(pts.single.max, 1009);
    });

    test('deleting old history keeps recent data and the open session', () async {
      final repo = HistoryRepository(db);
      final old = DateTime(2026, 1, 1);
      final recent = DateTime(2026, 11, 1);
      final closed = await repo.startSession(vehicleId: 'v', at: old);
      await repo.insertReadings(closed, [SensorReading(Sensors.speed, 1, old)]);
      await repo.endSession(closed, 1, at: old.add(const Duration(hours: 1)));
      final open = await repo.startSession(vehicleId: 'v', at: old); // never ended
      await repo.insertReadings(open, [SensorReading(Sensors.speed, 2, recent)]);

      await repo.deleteOlderThan(DateTime(2026, 6, 1));
      final stats = await repo.stats();
      expect(stats.readings, 1);
      expect((await repo.sessions()).map((s) => s.id), [open]);
    });

    test('delete all wipes readings, sessions, trips and scans', () async {
      final repo = HistoryRepository(db);
      final s = await repo.startSession(vehicleId: 'v');
      await repo.insertReadings(s, [SensorReading(Sensors.speed, 1, DateTime.now())]);
      await TripRepository(db).insert(_trip('t', 'v', DateTime.now()));
      await DtcRepository(db).save(vehicleId: 'v', sessionId: s, milOn: false, reason: ScanReason.auto, codes: const [Dtc('P0100', DtcKind.stored)]);

      expect((await repo.stats()).trips, 1);
      await repo.deleteAll();
      final stats = await repo.stats();
      expect((stats.readings, stats.sessions, stats.trips), (0, 0, 0));
      expect(stats.since, isNull);
      expect(await DtcRepository(db).history(), isEmpty);
      expect(await db.db.query('dtc_entries'), isEmpty);
    });

    test('stats report the database size', () async {
      final stats = await HistoryRepository(db).stats();
      expect(stats.bytes, greaterThan(0));
    });
  });
}
