import 'dart:async';

import 'package:obd_core/obd_core.dart';
import 'package:test/test.dart';

void main() {
  group('PollScheduler', () {
    test('first pass covers everything, fast tier first', () {
      final s = PollScheduler([Sensors.coolant, Sensors.rpm, Sensors.speed, Sensors.battery]);
      final order = [for (var i = 0; i < 4; i++) s.next(0).single];
      expect(order.take(2), containsAll([Sensors.rpm, Sensors.speed]));
      expect(order.toSet().length, 4);
    });

    test('refresh rates follow tiers under load', () {
      final sensors = [Sensors.rpm, Sensors.speed, Sensors.load, Sensors.coolant, Sensors.fuelLevel, Sensors.runTime];
      final s = PollScheduler(sensors);
      final counts = <Sensor, int>{};
      // 8 requests per second for 60 seconds.
      for (var ms = 0; ms < 60000; ms += 125) {
        for (final x in s.next(ms)) {
          counts[x] = (counts[x] ?? 0) + 1;
        }
      }
      expect(counts[Sensors.rpm]!, greaterThan(counts[Sensors.load]! * 2));
      expect(counts[Sensors.load]!, greaterThan(counts[Sensors.coolant]! * 2));
      expect(counts[Sensors.coolant]!, greaterThan(counts[Sensors.runTime]!));
      expect(counts[Sensors.runTime]!, greaterThanOrEqualTo(2)); // never starved
    });

    test('batches up to six due PID sensors, virtual sensors go alone', () {
      final s = PollScheduler(Sensors.all.where((x) => x.isPid), batchSize: 6);
      final first = s.next(0);
      expect(first.length, 6);
      expect(first.every((x) => x.isPid), isTrue);

      final v = PollScheduler([Sensors.battery, Sensors.rpm], batchSize: 6);
      v.next(0); // rpm (fast tier first)
      expect(v.next(1), [Sensors.battery]);
    });

    test('drops a sensor after three NO DATA in a row', () {
      final s = PollScheduler([Sensors.rpm, Sensors.ethanol]);
      expect(s.gotNoData(Sensors.ethanol), isFalse);
      expect(s.gotNoData(Sensors.ethanol), isFalse);
      expect(s.gotNoData(Sensors.ethanol), isTrue);
      expect(s.active, [Sensors.rpm]);
      expect(s.dropped, {Sensors.ethanol});
    });
  });

  group('LivePoller', () {
    test('streams readings for every supported sensor', () async {
      final sim = Elm327Simulator(realtime: false);
      await sim.connect();
      final adapter = Elm327Adapter(sim, timeoutScale: 0.05);
      final info = (await adapter.initialize() as Ok<AdapterInfo>).value;
      final sensors = Sensors.all.where((s) => !s.isPid || info.supportedPids.contains(s.pid)).toList();
      final poller = LivePoller(adapter, sensors);
      final seen = <Sensor>{};
      final sub = poller.readings.listen((r) => seen.add(r.sensor));
      poller.start();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await poller.stop();
      await sub.cancel();
      expect(seen, containsAll(sensors));
      expect(poller.scheduler.dropped, isEmpty);
    });

    test('emits lost when the car goes silent (ignition off)', () async {
      final sim = Elm327Simulator(realtime: false);
      await sim.connect();
      final adapter = Elm327Adapter(sim, timeoutScale: 0.05);
      await adapter.initialize();
      final poller = LivePoller(adapter, [Sensors.rpm, Sensors.speed, Sensors.battery]);
      final lost = poller.events.firstWhere((e) => e == PollerEvent.lost);
      poller.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      sim.faults.carOff = true;
      await lost.timeout(const Duration(seconds: 5));
      expect(poller.isRunning, isFalse);
    });

    test('emits lost when the link drops', () async {
      final sim = Elm327Simulator(realtime: false);
      await sim.connect();
      final adapter = Elm327Adapter(sim, timeoutScale: 0.02);
      await adapter.initialize();
      final poller = LivePoller(adapter, [Sensors.rpm, Sensors.speed]);
      final lost = poller.events.firstWhere((e) => e == PollerEvent.lost);
      poller.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      sim.simulateLinkDrop();
      await lost.timeout(const Duration(seconds: 10));
    });
  });

  group('SimulatedCar', () {
    test('drives a full cycle with plausible values', () {
      final car = SimulatedCar();
      var maxSpeed = 0.0;
      for (var i = 0; i < 2450; i++) {
        car.advance(0.1);
        if (car.speed > maxSpeed) maxSpeed = car.speed;
        expect(car.rpm, inInclusiveRange(600, 6500));
      }
      expect(maxSpeed, greaterThan(100));
      expect(car.coolant, greaterThan(80));
      expect(car.odometer, greaterThan(84215.3 + 2));
    });
  });
}
