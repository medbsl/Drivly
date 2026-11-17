import 'package:drivly/features/trips/trip_recorder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obd_core/obd_core.dart';

void main() {
  test('a simulated 20-minute drive is within 1% of the simulator truth', () {
    final car = SimulatedCar(seed: 3);
    final trips = <TripSnapshot>[];
    final rec = TripRecorder(onFinished: trips.add);
    var t = DateTime(2026, 1, 1, 8);
    final startOdo = car.odometer;
    double? odoAtStart;
    for (var i = 0; i < 20 * 60 * 4; i++) {
      car.advance(0.25);
      t = t.add(const Duration(milliseconds: 250));
      final wasActive = rec.isActive;
      rec.feed(SensorReading(Sensors.speed, car.speed, t));
      rec.feed(SensorReading(Sensors.rpm, car.rpm, t));
      if (i % 8 == 0) rec.feed(SensorReading(Sensors.coolant, car.coolant, t));
      if (!wasActive && rec.isActive) odoAtStart = car.odometer;
    }
    expect(odoAtStart, isNotNull);
    final truth = car.odometer - odoAtStart!;
    rec.finish(at: t);
    expect(trips, hasLength(1));
    final trip = trips.single;
    expect(trip.distanceKm, closeTo(truth, truth * 0.01 + 0.02));
    expect(car.odometer - startOdo, greaterThan(10));
    expect(trip.maxSpeed, greaterThan(100));
    expect(trip.maxCoolant, isNotNull);
  });

  test('does not start below 5 km/h or for under 5 s', () {
    final rec = TripRecorder(onFinished: (_) {});
    final t0 = DateTime(2026);
    for (var i = 0; i < 20; i++) {
      rec.feed(SensorReading(Sensors.speed, 4, t0.add(Duration(seconds: i))));
    }
    expect(rec.isActive, isFalse);
    for (var i = 0; i < 4; i++) {
      rec.feed(SensorReading(Sensors.speed, 20, t0.add(Duration(seconds: 30 + i))));
    }
    expect(rec.isActive, isFalse);
    rec.feed(SensorReading(Sensors.speed, 20, t0.add(const Duration(seconds: 36))));
    expect(rec.isActive, isTrue);
  });

  test('auto-stops after 60 s parked with the engine off, discards tiny trips', () {
    final trips = <TripSnapshot>[];
    final rec = TripRecorder(onFinished: trips.add);
    final t0 = DateTime(2026);
    // 3 minutes at 30 km/h = 1.5 km.
    for (var s = 0; s <= 180; s++) {
      rec.feed(SensorReading(Sensors.speed, 30, t0.add(Duration(seconds: s))));
      rec.feed(SensorReading(Sensors.rpm, 1500, t0.add(Duration(seconds: s))));
    }
    for (var s = 181; s <= 260; s++) {
      rec.feed(SensorReading(Sensors.speed, 0, t0.add(Duration(seconds: s))));
      rec.feed(SensorReading(Sensors.rpm, 0, t0.add(Duration(seconds: s))));
    }
    expect(rec.isActive, isFalse);
    expect(trips.single.distanceKm, closeTo(1.475, 0.03));

    // A 20-second hop is discarded.
    final rec2 = TripRecorder(onFinished: trips.add);
    for (var s = 0; s <= 20; s++) {
      rec2.feed(SensorReading(Sensors.speed, 15, t0.add(Duration(seconds: s))));
    }
    rec2.finish();
    expect(trips, hasLength(1));
  });

  test('gaps over 10 s are not integrated and are flagged', () {
    final trips = <TripSnapshot>[];
    final rec = TripRecorder(onFinished: trips.add);
    final t0 = DateTime(2026);
    for (var s = 0; s <= 120; s++) {
      rec.feed(SensorReading(Sensors.speed, 60, t0.add(Duration(seconds: s))));
    }
    for (var s = 180; s <= 240; s++) {
      rec.feed(SensorReading(Sensors.speed, 60, t0.add(Duration(seconds: s))));
    }
    rec.finish();
    expect(trips.single.hasGap, isTrue);
    // ~175 s of integrated driving at 60 km/h (the 55 s gap is skipped).
    expect(trips.single.distanceKm, lessThan(3.0));
  });
}
