import 'dart:math';

import 'package:obd_core/obd_core.dart';

import '../../data/models.dart';
import '../../data/repositories.dart';
import '../trips/trip_recorder.dart';

/// Demo mode only: fills the demo car's history with a week of simulated
/// drives so the History charts have something to show on first launch.
/// Never runs for a real car; everything is tied to the demo vehicle.
class DemoSeeder {
  DemoSeeder({required this.history, required this.trips});

  final HistoryRepository history;
  final TripRepository trips;

  Future<void> seed({required String vehicleId, required Set<int> supportedPids, int drives = 6}) async {
    final rng = Random(42);
    final now = DateTime.now();
    final sensors = Sensors.all.where((s) => s.isPid && supportedPids.contains(s.pid)).toList();
    for (var d = drives; d >= 1; d--) {
      final day = now.subtract(Duration(days: d + 0));
      final start = DateTime(day.year, day.month, day.day, rng.nextBool() ? 8 : 17, rng.nextInt(50));
      final minutes = 14 + rng.nextInt(18);
      final car = SimulatedCar(seed: d * 7, coolant: 18 + rng.nextInt(10).toDouble());
      final sessionId = await history.startSession(vehicleId: vehicleId, adapterName: 'Drivly Demo', demo: true, at: start);
      final out = <SensorReading>[];
      TripSnapshot? trip;
      final recorder = TripRecorder(onFinished: (t) => trip = t);
      for (var s = 0; s < minutes * 60; s++) {
        car.advance(1);
        final at = start.add(Duration(seconds: s));
        final fast = [
          SensorReading(Sensors.speed, car.speed, at),
          SensorReading(Sensors.rpm, car.rpm, at),
        ];
        out.addAll(fast);
        fast.forEach(recorder.feed);
        if (s % 5 == 0) {
          for (final sensor in sensors) {
            if (sensor == Sensors.speed || sensor == Sensors.rpm) continue;
            final v = _value(car, sensor);
            if (v != null) out.add(SensorReading(sensor, v, at));
          }
          out.add(SensorReading(Sensors.battery, car.voltage, at));
          final c = SensorReading(Sensors.coolant, car.coolant, at);
          recorder.feed(c);
          recorder.feed(SensorReading(Sensors.fuelRate, car.fuelRate, at));
        }
        if (out.length > 4000) {
          await history.insertReadings(sessionId, List.of(out));
          out.clear();
        }
      }
      await history.insertReadings(sessionId, out);
      recorder.finish();
      await history.endSession(sessionId, minutes * 60, at: start.add(Duration(minutes: minutes)));
      final t = trip;
      if (t != null) {
        await trips.insert(Trip(
          id: newId(),
          vehicleId: vehicleId,
          sessionId: sessionId,
          startedAt: t.startedAt,
          endedAt: t.endedAt,
          distanceKm: t.distanceKm,
          maxSpeed: t.maxSpeed,
          avgSpeed: t.avgSpeed,
          maxCoolant: t.maxCoolant,
          idleSeconds: t.idleSeconds,
          fuelUsedL: t.fuelUsedL,
          hasGap: t.hasGap,
        ));
      }
    }
  }

  double? _value(SimulatedCar c, Sensor s) => switch (s.key) {
        'coolant' => c.coolant,
        'load' => c.load,
        'throttle' => c.throttle,
        'intakeTemp' => c.iat,
        'fuelLevel' => c.fuel,
        'fuelRate' => c.fuelRate,
        'maf' => c.maf,
        'map' => c.map,
        'timing' => c.timing,
        'oilTemp' => c.oil,
        'ambientTemp' => c.ambient,
        'moduleVoltage' => c.voltage,
        'absoluteLoad' => c.load,
        'pedal' => c.pedal,
        'commandedThrottle' => c.throttle * 0.95,
        'stft1' => c.stft,
        'ltft1' => c.ltft,
        'o2b1s1' => c.o2,
        'catTemp' => c.catTemp,
        'baro' => c.baro,
        'odometer' => c.odometer,
        'distanceSinceClear' => c.distanceSinceClear,
        'runTime' => c.runTime,
        _ => null,
      };
}
