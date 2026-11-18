import 'package:drivly/data/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obd_core/obd_core.dart';

void main() {
  group('Vehicle.fromRow', () {
    test('reads every column, PIDs are stored as hex', () {
      final v = Vehicle.fromRow({
        'id': 'v1',
        'vin': 'WVWZZZAUZGW123456',
        'nickname': 'Golf',
        'make': 'Volkswagen',
        'country': 'Germany',
        'model_year': 2016,
        'model_year_certain': 1,
        'model_user': 'Golf VII',
        'protocol': ObdProtocol.can11x500.name,
        'supported_pids': 'c,d,5,a6',
        'demo': 0,
        'updated_at': 1700000000000,
      });
      expect(v.supportedPids, {0x0C, 0x0D, 0x05, 0xA6});
      expect(v.obdProtocol, ObdProtocol.can11x500);
      expect(v.modelYearCertain, isTrue);
      expect(v.demo, isFalse);
      expect(v.updatedAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(v.nickname, 'Golf');
      expect(v.modelUser, 'Golf VII');
    });

    test('missing optional columns give safe defaults', () {
      final v = Vehicle.fromRow({'id': 'v2', 'updated_at': 0});
      expect(v.vin, isNull);
      expect(v.supportedPids, isEmpty);
      expect(v.obdProtocol, isNull);
      expect(v.modelYearCertain, isFalse);
      expect(v.demo, isFalse);
    });

    test('an unknown protocol name is ignored, not a crash', () {
      final v = Vehicle.fromRow({'id': 'v3', 'protocol': 'warpDrive', 'updated_at': 0});
      expect(v.obdProtocol, isNull);
    });
  });

  group('Trip', () {
    final trip = Trip(
      id: 't1',
      vehicleId: 'v1',
      sessionId: 's1',
      startedAt: DateTime(2026, 11, 16, 8),
      endedAt: DateTime(2026, 11, 16, 8, 25, 30),
      distanceKm: 18.4,
      maxSpeed: 112,
      avgSpeed: 43.3,
      maxCoolant: 94,
      idleSeconds: 120,
      fuelUsedL: 1.38,
      hasGap: true,
    );

    test('round-trips through a database row', () {
      final back = Trip.fromRow(trip.toRow());
      expect(back.id, trip.id);
      expect(back.vehicleId, trip.vehicleId);
      expect(back.sessionId, trip.sessionId);
      expect(back.startedAt, trip.startedAt);
      expect(back.endedAt, trip.endedAt);
      expect(back.distanceKm, trip.distanceKm);
      expect(back.maxSpeed, trip.maxSpeed);
      expect(back.avgSpeed, trip.avgSpeed);
      expect(back.maxCoolant, trip.maxCoolant);
      expect(back.idleSeconds, trip.idleSeconds);
      expect(back.fuelUsedL, trip.fuelUsedL);
      expect(back.hasGap, isTrue);
    });

    test('duration and consumption', () {
      expect(trip.duration, const Duration(minutes: 25, seconds: 30));
      expect(trip.consumption, closeTo(1.38 / 18.4 * 100, 1e-9));
    });

    test('no consumption without fuel data or for very short trips', () {
      Trip t({double? fuel, double km = 10}) => Trip(
            id: 'x',
            vehicleId: 'v',
            startedAt: DateTime(2026),
            endedAt: DateTime(2026),
            distanceKm: km,
            maxSpeed: 0,
            avgSpeed: 0,
            fuelUsedL: fuel,
          );
      expect(t().consumption, isNull);
      expect(t(fuel: 0.1, km: 0.4).consumption, isNull);
      expect(t(fuel: 0.6, km: 10).consumption, closeTo(6, 1e-9));
    });
  });

  test('DtcScan splits stored and pending codes', () {
    final scan = DtcScan(
      id: 's',
      at: DateTime(2026),
      milOn: true,
      reason: ScanReason.manual,
      codes: const [Dtc('P0133', DtcKind.stored), Dtc('P0442', DtcKind.pending), Dtc('P0300', DtcKind.stored)],
    );
    expect(scan.stored.map((d) => d.code), ['P0133', 'P0300']);
    expect(scan.pending.map((d) => d.code), ['P0442']);
  });

  test('old scan reasons from before the read-only change still parse', () {
    expect(ScanReason.values.byName('beforeClear'), ScanReason.beforeClear);
    expect(ScanReason.values.byName('afterClear'), ScanReason.afterClear);
  });
}
