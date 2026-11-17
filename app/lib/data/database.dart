import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Local SQLite database. Everything stays on the phone.
///
/// IDs are UUIDs and rows carry timestamps so sync stays possible later.
/// All values are stored in SI units; conversion happens only on display.
class AppDatabase {
  AppDatabase(this.db);

  final Database db;

  static const _version = 1;

  static Future<AppDatabase> open({String? path, DatabaseFactory? factory}) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), 'drivly.db');
    final db = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _version,
        onConfigure: (db) async {
          await db.rawQuery('PRAGMA journal_mode = WAL');
          await db.execute('PRAGMA synchronous = NORMAL');
        },
        onCreate: (db, version) async {
          final b = db.batch();
          for (final sql in _schema) {
            b.execute(sql);
          }
          await b.commit(noResult: true);
        },
      ),
    );
    return AppDatabase(db);
  }

  static const _schema = [
    '''CREATE TABLE vehicles(
      id TEXT PRIMARY KEY, vin TEXT, nickname TEXT, make TEXT, country TEXT,
      model_year INTEGER, model_year_certain INTEGER DEFAULT 0, model_user TEXT,
      protocol TEXT, supported_pids TEXT, demo INTEGER DEFAULT 0,
      created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)''',
    '''CREATE TABLE sessions(
      id TEXT PRIMARY KEY, vehicle_id TEXT NOT NULL, adapter_name TEXT,
      demo INTEGER DEFAULT 0, started_at INTEGER NOT NULL, ended_at INTEGER,
      reading_count INTEGER DEFAULT 0)''',
    'CREATE INDEX idx_sessions_vehicle ON sessions(vehicle_id, started_at)',
    '''CREATE TABLE readings(
      session_id TEXT NOT NULL, sensor INTEGER NOT NULL, t INTEGER NOT NULL, value REAL NOT NULL)''',
    'CREATE INDEX idx_readings_sensor_t ON readings(sensor, t)',
    'CREATE INDEX idx_readings_session ON readings(session_id)',
    '''CREATE TABLE dtc_scans(
      id TEXT PRIMARY KEY, vehicle_id TEXT, session_id TEXT, at INTEGER NOT NULL,
      mil_on INTEGER DEFAULT 0, reason TEXT NOT NULL)''',
    'CREATE INDEX idx_dtc_scans_vehicle ON dtc_scans(vehicle_id, at)',
    'CREATE TABLE dtc_entries(scan_id TEXT NOT NULL, code TEXT NOT NULL, kind TEXT NOT NULL, ecu TEXT)',
    'CREATE INDEX idx_dtc_entries_scan ON dtc_entries(scan_id)',
    '''CREATE TABLE trips(
      id TEXT PRIMARY KEY, vehicle_id TEXT NOT NULL, session_id TEXT,
      started_at INTEGER NOT NULL, ended_at INTEGER NOT NULL, distance_km REAL,
      max_speed REAL, avg_speed REAL, max_coolant REAL, idle_seconds INTEGER,
      fuel_used_l REAL, has_gap INTEGER DEFAULT 0)''',
    'CREATE INDEX idx_trips_vehicle ON trips(vehicle_id, started_at)',
  ];

  Future<void> close() => db.close();
}
