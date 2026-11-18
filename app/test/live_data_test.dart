import 'package:drivly/features/live/live_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obd_core/obd_core.dart';

void main() {
  late LiveData live;
  setUp(() => live = LiveData(window: const Duration(minutes: 1)));
  tearDown(() => live.dispose());

  test('keeps the latest value and time per sensor', () {
    final t = DateTime.now();
    live.add(SensorReading(Sensors.speed, 40, t));
    live.add(SensorReading(Sensors.speed, 42, t.add(const Duration(milliseconds: 250))));
    live.add(SensorReading(Sensors.rpm, 1800, t));
    expect(live.value(Sensors.speed), 42);
    expect(live.at(Sensors.speed), t.add(const Duration(milliseconds: 250)));
    expect(live.value(Sensors.rpm), 1800);
    expect(live.value(Sensors.coolant), isNull);
    expect(live.hasData, isTrue);
    expect(live.sessionReadings, 3);
  });

  test('the rolling window drops values older than the window', () {
    final t = DateTime.now().subtract(const Duration(minutes: 3));
    for (var s = 0; s <= 180; s += 30) {
      live.add(SensorReading(Sensors.speed, s.toDouble(), t.add(Duration(seconds: s))));
    }
    final values = live.recent(Sensors.speed).map((e) => e.v);
    expect(values, [120, 150, 180], reason: 'only the last minute is kept');
    expect(live.recent(Sensors.rpm), isEmpty);
  });

  test('recent(span) narrows to the last part of the window', () {
    final now = DateTime.now();
    live.add(SensorReading(Sensors.speed, 1, now.subtract(const Duration(seconds: 50))));
    live.add(SensorReading(Sensors.speed, 2, now.subtract(const Duration(seconds: 5))));
    expect(live.recent(Sensors.speed, const Duration(seconds: 10)).map((e) => e.v), [2]);
  });

  test('begin starts a clean session with the polled sensors', () {
    live.add(SensorReading(Sensors.speed, 40, DateTime.now()));
    live.markUnsupported([Sensors.ethanol]);
    live.begin([Sensors.speed, Sensors.rpm]);
    expect(live.hasData, isFalse);
    expect(live.sessionReadings, 0);
    expect(live.polled, {Sensors.speed, Sensors.rpm});
    expect(live.unsupported, isEmpty);
    expect(live.sessionStart, isNotNull);
  });

  test('a sensor that never answers moves from polled to unsupported', () {
    live.begin([Sensors.speed, Sensors.ethanol]);
    live.markUnsupported([Sensors.ethanol]);
    expect(live.polled, {Sensors.speed});
    expect(live.unsupported, {Sensors.ethanol});
  });

  test('stale after 3 s for fast values, longer for slow and rare ones', () {
    final now = DateTime.now();
    expect(live.isStale(Sensors.speed), isTrue, reason: 'no value yet');
    live.add(SensorReading(Sensors.speed, 1, now.subtract(const Duration(seconds: 1))));
    expect(live.isStale(Sensors.speed), isFalse);
    live.add(SensorReading(Sensors.speed, 1, now.subtract(const Duration(seconds: 4))));
    expect(live.isStale(Sensors.speed), isTrue);

    live.add(SensorReading(Sensors.coolant, 90, now.subtract(const Duration(seconds: 8)))); // slow tier
    expect(live.isStale(Sensors.coolant), isFalse);
    live.add(SensorReading(Sensors.coolant, 90, now.subtract(const Duration(seconds: 13))));
    expect(live.isStale(Sensors.coolant), isTrue);

    live.add(SensorReading(Sensors.odometer, 1, now.subtract(const Duration(seconds: 60)))); // rare tier
    expect(live.isStale(Sensors.odometer), isFalse);
    live.add(SensorReading(Sensors.odometer, 1, now.subtract(const Duration(seconds: 80))));
    expect(live.isStale(Sensors.odometer), isTrue);
  });

  test('a burst of readings notifies listeners once, not per reading', () async {
    var notified = 0;
    live.addListener(() => notified++);
    final t = DateTime.now();
    for (var i = 0; i < 100; i++) {
      live.add(SensorReading(Sensors.rpm, i.toDouble(), t));
    }
    expect(notified, 0);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(notified, 1);
  });
}
