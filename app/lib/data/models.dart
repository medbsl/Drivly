import 'package:flutter/foundation.dart';
import 'package:obd_core/obd_core.dart';

@immutable
class Vehicle {
  const Vehicle({
    required this.id,
    this.vin,
    this.nickname,
    this.make,
    this.country,
    this.modelYear,
    this.modelYearCertain = false,
    this.modelUser,
    this.protocol,
    this.supportedPids = const {},
    this.demo = false,
    required this.updatedAt,
  });

  final String id;
  final String? vin;
  final String? nickname;
  final String? make;
  final String? country;
  final int? modelYear;
  final bool modelYearCertain;
  final String? modelUser;
  final String? protocol;
  final Set<int> supportedPids;
  final bool demo;
  final DateTime updatedAt;

  ObdProtocol? get obdProtocol =>
      protocol == null ? null : ObdProtocol.values.where((p) => p.name == protocol).firstOrNull;

  factory Vehicle.fromRow(Map<String, Object?> r) => Vehicle(
        id: r['id']! as String,
        vin: r['vin'] as String?,
        nickname: r['nickname'] as String?,
        make: r['make'] as String?,
        country: r['country'] as String?,
        modelYear: r['model_year'] as int?,
        modelYearCertain: (r['model_year_certain'] as int? ?? 0) == 1,
        modelUser: r['model_user'] as String?,
        protocol: r['protocol'] as String?,
        supportedPids: ((r['supported_pids'] as String?) ?? '')
            .split(',')
            .where((s) => s.isNotEmpty)
            .map((s) => int.parse(s, radix: 16))
            .toSet(),
        demo: (r['demo'] as int? ?? 0) == 1,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at']! as int),
      );
}

@immutable
class SessionRow {
  const SessionRow({
    required this.id,
    required this.vehicleId,
    required this.startedAt,
    this.endedAt,
    this.adapterName,
    this.demo = false,
    this.readingCount = 0,
  });

  final String id;
  final String vehicleId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? adapterName;
  final bool demo;
  final int readingCount;

  factory SessionRow.fromRow(Map<String, Object?> r) => SessionRow(
        id: r['id']! as String,
        vehicleId: r['vehicle_id']! as String,
        startedAt: DateTime.fromMillisecondsSinceEpoch(r['started_at']! as int),
        endedAt: r['ended_at'] == null ? null : DateTime.fromMillisecondsSinceEpoch(r['ended_at']! as int),
        adapterName: r['adapter_name'] as String?,
        demo: (r['demo'] as int? ?? 0) == 1,
        readingCount: r['reading_count'] as int? ?? 0,
      );
}

@immutable
class Trip {
  const Trip({
    required this.id,
    required this.vehicleId,
    required this.startedAt,
    required this.endedAt,
    required this.distanceKm,
    required this.maxSpeed,
    required this.avgSpeed,
    this.sessionId,
    this.maxCoolant,
    this.idleSeconds = 0,
    this.fuelUsedL,
    this.hasGap = false,
  });

  final String id;
  final String vehicleId;
  final String? sessionId;
  final DateTime startedAt;
  final DateTime endedAt;
  final double distanceKm;
  final double maxSpeed;
  final double avgSpeed;
  final double? maxCoolant;
  final int idleSeconds;
  final double? fuelUsedL;
  final bool hasGap;

  Duration get duration => endedAt.difference(startedAt);

  /// L/100 km, when fuel rate was available.
  double? get consumption => fuelUsedL == null || distanceKm < 0.5 ? null : fuelUsedL! / distanceKm * 100;

  Map<String, Object?> toRow() => {
        'id': id,
        'vehicle_id': vehicleId,
        'session_id': sessionId,
        'started_at': startedAt.millisecondsSinceEpoch,
        'ended_at': endedAt.millisecondsSinceEpoch,
        'distance_km': distanceKm,
        'max_speed': maxSpeed,
        'avg_speed': avgSpeed,
        'max_coolant': maxCoolant,
        'idle_seconds': idleSeconds,
        'fuel_used_l': fuelUsedL,
        'has_gap': hasGap ? 1 : 0,
      };

  factory Trip.fromRow(Map<String, Object?> r) => Trip(
        id: r['id']! as String,
        vehicleId: r['vehicle_id']! as String,
        sessionId: r['session_id'] as String?,
        startedAt: DateTime.fromMillisecondsSinceEpoch(r['started_at']! as int),
        endedAt: DateTime.fromMillisecondsSinceEpoch(r['ended_at']! as int),
        distanceKm: (r['distance_km'] as num?)?.toDouble() ?? 0,
        maxSpeed: (r['max_speed'] as num?)?.toDouble() ?? 0,
        avgSpeed: (r['avg_speed'] as num?)?.toDouble() ?? 0,
        maxCoolant: (r['max_coolant'] as num?)?.toDouble(),
        idleSeconds: r['idle_seconds'] as int? ?? 0,
        fuelUsedL: (r['fuel_used_l'] as num?)?.toDouble(),
        hasGap: (r['has_gap'] as int? ?? 0) == 1,
      );
}

/// [beforeClear] and [afterClear] only appear in scans saved before clearing
/// codes was removed (Drivly is read-only). Kept so that history still loads.
enum ScanReason { auto, manual, beforeClear, afterClear }

@immutable
class DtcScan {
  const DtcScan({
    required this.id,
    required this.at,
    required this.milOn,
    required this.reason,
    required this.codes,
  });

  final String id;
  final DateTime at;
  final bool milOn;
  final ScanReason reason;
  final List<Dtc> codes;

  List<Dtc> get stored => codes.where((c) => c.kind == DtcKind.stored).toList();
  List<Dtc> get pending => codes.where((c) => c.kind == DtcKind.pending).toList();
}

/// One aggregated chart bucket.
@immutable
class SeriesPoint {
  const SeriesPoint(this.t, this.avg, this.min, this.max);
  final DateTime t;
  final double avg;
  final double min;
  final double max;
}

@immutable
class SensorSummary {
  const SensorSummary({
    required this.sensor,
    required this.count,
    required this.min,
    required this.max,
    required this.avg,
  });

  final Sensor sensor;
  final int count;
  final double min;
  final double max;
  final double avg;
}

@immutable
class StorageStats {
  const StorageStats({required this.readings, required this.sessions, required this.trips, required this.bytes, this.since});
  final int readings;
  final int sessions;
  final int trips;
  final int bytes;
  final DateTime? since;
}
