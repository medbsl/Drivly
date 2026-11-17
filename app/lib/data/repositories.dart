import 'dart:math';

import 'package:obd_core/obd_core.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';
import 'models.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

int _ms(DateTime t) => t.millisecondsSinceEpoch;
DateTime _dt(Object? ms) => DateTime.fromMillisecondsSinceEpoch(ms! as int);

/// Every reading ever taken, plus connection sessions. The single source for
/// history charts.
class HistoryRepository {
  HistoryRepository(this._db);
  final AppDatabase _db;
  Database get _d => _db.db;

  Future<String> startSession({required String vehicleId, String? adapterName, bool demo = false, DateTime? at}) async {
    final id = newId();
    await _d.insert('sessions', {
      'id': id,
      'vehicle_id': vehicleId,
      'adapter_name': adapterName,
      'demo': demo ? 1 : 0,
      'started_at': _ms(at ?? DateTime.now()),
    });
    return id;
  }

  Future<void> endSession(String id, int readingCount, {DateTime? at}) => _d.update(
        'sessions',
        {'ended_at': _ms(at ?? DateTime.now()), 'reading_count': readingCount},
        where: 'id = ?',
        whereArgs: [id],
      );

  /// Batched insert; one transaction per flush (~1 s of data).
  Future<void> insertReadings(String sessionId, List<SensorReading> readings) async {
    if (readings.isEmpty) return;
    final b = _d.batch();
    for (final r in readings) {
      b.rawInsert(
        'INSERT INTO readings(session_id, sensor, t, value) VALUES (?, ?, ?, ?)',
        [sessionId, r.sensor.id, _ms(r.at), r.value],
      );
    }
    await b.commit(noResult: true);
  }

  String _vehicleFilter(String? vehicleId, List<Object?> args) {
    if (vehicleId == null) return '';
    args.add(vehicleId);
    return ' AND session_id IN (SELECT id FROM sessions WHERE vehicle_id = ?)';
  }

  /// Aggregated series: [buckets] points with avg/min/max per bucket.
  Future<List<SeriesPoint>> series(
    Sensor sensor, {
    required DateTime from,
    required DateTime to,
    int buckets = 180,
    String? vehicleId,
  }) async {
    final span = max(1, _ms(to) - _ms(from));
    final bucketMs = max(1000, (span / buckets).ceil());
    final args = <Object?>[bucketMs, bucketMs, sensor.id, _ms(from), _ms(to)];
    final filter = _vehicleFilter(vehicleId, args);
    final rows = await _d.rawQuery(
      'SELECT (t / ?) * ? AS b, AVG(value) AS a, MIN(value) AS mn, MAX(value) AS mx '
      'FROM readings WHERE sensor = ? AND t >= ? AND t < ?$filter GROUP BY b ORDER BY b',
      args,
    );
    return [
      for (final r in rows)
        SeriesPoint(_dt(r['b']), (r['a']! as num).toDouble(), (r['mn']! as num).toDouble(), (r['mx']! as num).toDouble()),
    ];
  }

  /// Per-sensor stats over a range (which sensors have data, min/avg/max).
  Future<List<SensorSummary>> summaries({required DateTime from, required DateTime to, String? vehicleId}) async {
    final args = <Object?>[_ms(from), _ms(to)];
    final filter = _vehicleFilter(vehicleId, args);
    final rows = await _d.rawQuery(
      'SELECT sensor, COUNT(*) AS n, MIN(value) AS mn, MAX(value) AS mx, AVG(value) AS a '
      'FROM readings WHERE t >= ? AND t < ?$filter GROUP BY sensor',
      args,
    );
    final out = <SensorSummary>[];
    for (final r in rows) {
      final s = Sensors.byId[r['sensor']! as int];
      if (s == null) continue;
      out.add(SensorSummary(
        sensor: s,
        count: r['n']! as int,
        min: (r['mn']! as num).toDouble(),
        max: (r['mx']! as num).toDouble(),
        avg: (r['a']! as num).toDouble(),
      ));
    }
    out.sort((a, b) => Sensors.all.indexOf(a.sensor).compareTo(Sensors.all.indexOf(b.sensor)));
    return out;
  }

  Future<DateTime?> firstReadingAt({String? vehicleId}) async {
    final args = <Object?>[];
    final filter = vehicleId == null ? '' : ' WHERE vehicle_id = ?';
    if (vehicleId != null) args.add(vehicleId);
    final r = await _d.rawQuery('SELECT MIN(started_at) AS t FROM sessions$filter', args);
    final t = r.first['t'];
    return t == null ? null : _dt(t);
  }

  Future<List<SessionRow>> sessions({String? vehicleId, int limit = 50}) async {
    final rows = await _d.query(
      'sessions',
      where: vehicleId == null ? null : 'vehicle_id = ?',
      whereArgs: vehicleId == null ? null : [vehicleId],
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return rows.map(SessionRow.fromRow).toList();
  }

  Future<StorageStats> stats() async {
    final n = Sqflite.firstIntValue(await _d.rawQuery('SELECT COUNT(*) FROM readings')) ?? 0;
    final s = Sqflite.firstIntValue(await _d.rawQuery('SELECT COUNT(*) FROM sessions')) ?? 0;
    final tr = Sqflite.firstIntValue(await _d.rawQuery('SELECT COUNT(*) FROM trips')) ?? 0;
    final since = await firstReadingAt();
    final pages = Sqflite.firstIntValue(await _d.rawQuery('PRAGMA page_count')) ?? 0;
    final pageSize = Sqflite.firstIntValue(await _d.rawQuery('PRAGMA page_size')) ?? 0;
    final bytes = pages * pageSize;
    return StorageStats(readings: n, sessions: s, trips: tr, bytes: bytes, since: since);
  }

  Future<void> deleteOlderThan(DateTime cutoff) async {
    await _d.delete('readings', where: 't < ?', whereArgs: [_ms(cutoff)]);
    await _d.delete('sessions', where: 'started_at < ? AND ended_at IS NOT NULL', whereArgs: [_ms(cutoff)]);
  }

  Future<void> deleteAll() async {
    await _d.transaction((tx) async {
      await tx.delete('readings');
      await tx.delete('sessions');
      await tx.delete('trips');
      await tx.delete('dtc_entries');
      await tx.delete('dtc_scans');
    });
    await _d.execute('VACUUM');
  }
}

class VehicleRepository {
  VehicleRepository(this._db);
  final AppDatabase _db;
  Database get _d => _db.db;

  Future<Vehicle?> byId(String id) async {
    final rows = await _d.query('vehicles', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Vehicle.fromRow(rows.first);
  }

  Future<List<Vehicle>> all() async {
    final rows = await _d.query('vehicles', orderBy: 'updated_at DESC');
    return rows.map(Vehicle.fromRow).toList();
  }

  /// Finds or creates the vehicle for this connection. Keyed by VIN when the
  /// car shares it, otherwise by adapter (one car per adapter is the norm).
  Future<Vehicle> upsertFromConnection({
    String? vin,
    required String fallbackKey,
    required AdapterInfo info,
    bool demo = false,
  }) async {
    final now = DateTime.now();
    final existing = vin != null
        ? await _d.query('vehicles', where: 'vin = ?', whereArgs: [vin])
        : await _d.query('vehicles', where: 'id = ?', whereArgs: [fallbackKey]);
    final pids = info.supportedPids.map((p) => p.toRadixString(16)).join(',');
    if (existing.isNotEmpty) {
      final id = existing.first['id']! as String;
      await _d.update(
        'vehicles',
        {'protocol': info.protocol?.name, 'supported_pids': pids, 'updated_at': _ms(now)},
        where: 'id = ?',
        whereArgs: [id],
      );
      return (await byId(id))!;
    }
    final decoded = vin == null ? null : decodeVin(vin);
    final id = vin == null ? fallbackKey : newId();
    await _d.insert('vehicles', {
      'id': id,
      'vin': vin,
      'make': decoded?.make,
      'country': decoded?.country,
      'model_year': decoded?.modelYear?.year,
      'model_year_certain': (decoded?.modelYear?.certain ?? false) ? 1 : 0,
      'protocol': info.protocol?.name,
      'supported_pids': pids,
      'demo': demo ? 1 : 0,
      'created_at': _ms(now),
      'updated_at': _ms(now),
    });
    return (await byId(id))!;
  }

  Future<void> update(String id, {String? nickname, String? modelUser, int? modelYear, String? vin}) async {
    final values = <String, Object?>{'updated_at': _ms(DateTime.now())};
    if (nickname != null) values['nickname'] = nickname.isEmpty ? null : nickname;
    if (modelUser != null) values['model_user'] = modelUser.isEmpty ? null : modelUser;
    if (modelYear != null) {
      values['model_year'] = modelYear;
      values['model_year_certain'] = 1;
    }
    if (vin != null) {
      final d = decodeVin(vin);
      values
        ..['vin'] = vin
        ..['make'] = d.make
        ..['country'] = d.country
        ..['model_year'] = d.modelYear?.year
        ..['model_year_certain'] = (d.modelYear?.certain ?? false) ? 1 : 0;
    }
    await _d.update('vehicles', values, where: 'id = ?', whereArgs: [id]);
  }
}

class DtcRepository {
  DtcRepository(this._db);
  final AppDatabase _db;
  Database get _d => _db.db;

  Future<DtcScan> save({
    required String? vehicleId,
    required String? sessionId,
    required bool milOn,
    required ScanReason reason,
    required List<Dtc> codes,
  }) async {
    final scan = DtcScan(id: newId(), at: DateTime.now(), milOn: milOn, reason: reason, codes: codes);
    await _d.transaction((tx) async {
      await tx.insert('dtc_scans', {
        'id': scan.id,
        'vehicle_id': vehicleId,
        'session_id': sessionId,
        'at': _ms(scan.at),
        'mil_on': milOn ? 1 : 0,
        'reason': reason.name,
      });
      for (final c in codes) {
        await tx.insert('dtc_entries', {'scan_id': scan.id, 'code': c.code, 'kind': c.kind.name, 'ecu': c.ecu});
      }
    });
    return scan;
  }

  Future<List<DtcScan>> history({String? vehicleId, int limit = 100}) async {
    final scans = await _d.query(
      'dtc_scans',
      where: vehicleId == null ? null : 'vehicle_id = ?',
      whereArgs: vehicleId == null ? null : [vehicleId],
      orderBy: 'at DESC',
      limit: limit,
    );
    final out = <DtcScan>[];
    for (final s in scans) {
      final id = s['id']! as String;
      final entries = await _d.query('dtc_entries', where: 'scan_id = ?', whereArgs: [id]);
      out.add(DtcScan(
        id: id,
        at: _dt(s['at']),
        milOn: (s['mil_on'] as int? ?? 0) == 1,
        reason: ScanReason.values.byName(s['reason']! as String),
        codes: [
          for (final e in entries)
            Dtc(e['code']! as String, DtcKind.values.byName(e['kind']! as String), ecu: e['ecu'] as String?),
        ],
      ));
    }
    return out;
  }
}

class TripRepository {
  TripRepository(this._db);
  final AppDatabase _db;
  Database get _d => _db.db;

  Future<void> insert(Trip t) => _d.insert('trips', t.toRow());

  Future<List<Trip>> list({String? vehicleId, DateTime? from, int limit = 200}) async {
    final where = <String>[];
    final args = <Object?>[];
    if (vehicleId != null) {
      where.add('vehicle_id = ?');
      args.add(vehicleId);
    }
    if (from != null) {
      where.add('started_at >= ?');
      args.add(_ms(from));
    }
    final rows = await _d.query(
      'trips',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return rows.map(Trip.fromRow).toList();
  }

  Future<Trip?> byId(String id) async {
    final rows = await _d.query('trips', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Trip.fromRow(rows.first);
  }

  Future<void> delete(String id) => _d.delete('trips', where: 'id = ?', whereArgs: [id]);

  Future<void> deleteAll() => _d.delete('trips');
}
