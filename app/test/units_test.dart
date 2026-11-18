import 'package:drivly/core/units.dart';
import 'package:drivly/data/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obd_core/obd_core.dart';

void main() {
  const metric = Units(SpeedUnit.kmh, TempUnit.celsius);
  const imperial = Units(SpeedUnit.mph, TempUnit.fahrenheit);

  group('Units', () {
    test('metric shows stored values unchanged', () {
      expect(metric.convert(SensorUnit.kmh, 100), 100);
      expect(metric.convert(SensorUnit.km, 12.5), 12.5);
      expect(metric.convert(SensorUnit.celsius, 90), 90);
      expect(metric.symbol(SensorUnit.kmh), 'km/h');
      expect(metric.symbol(SensorUnit.km), 'km');
      expect(metric.symbol(SensorUnit.celsius), '°C');
      expect(metric.imperialDistance, isFalse);
    });

    test('mph converts speed and distance, °F converts temperature', () {
      expect(imperial.convert(SensorUnit.kmh, 100), closeTo(62.1371, 1e-4));
      expect(imperial.convert(SensorUnit.km, 10), closeTo(6.21371, 1e-5));
      expect(imperial.convert(SensorUnit.celsius, 0), 32);
      expect(imperial.convert(SensorUnit.celsius, 100), 212);
      expect(imperial.convert(SensorUnit.celsius, -40), -40);
      expect(imperial.symbol(SensorUnit.kmh), 'mph');
      expect(imperial.symbol(SensorUnit.km), 'mi');
      expect(imperial.symbol(SensorUnit.celsius), '°F');
      expect(imperial.imperialDistance, isTrue);
    });

    test('speed and temperature settings are independent', () {
      const mixed = Units(SpeedUnit.mph, TempUnit.celsius);
      expect(mixed.symbol(SensorUnit.kmh), 'mph');
      expect(mixed.convert(SensorUnit.celsius, 90), 90);
    });

    test('other units are never converted', () {
      for (final u in [SensorUnit.rpm, SensorUnit.percent, SensorUnit.volts, SensorUnit.kpa, SensorUnit.litersPerHour]) {
        expect(imperial.convert(u, 42), 42, reason: u.name);
        expect(imperial.symbol(u), u.symbol, reason: u.name);
      }
    });

    test('format uses the sensor decimals and thousands separators', () {
      expect(metric.format(Sensors.rpm, 2512.6), '2,513');
      expect(metric.format(Sensors.battery, 14.06), '14.1');
      expect(metric.format(Sensors.odometer, 84215.34), '84,215.3');
      expect(metric.format(Sensors.battery, 14.06, decimals: 2), '14.06');
      expect(imperial.format(Sensors.speed, 100), '62');
    });

    test('formatWithUnit adds the unit, but not for unitless values', () {
      expect(metric.formatWithUnit(Sensors.speed, 50), '50 km/h');
      expect(imperial.formatWithUnit(Sensors.coolant, 90), '194 °F');
      expect(metric.formatWithUnit(Sensors.dtcCount, 2), '2');
    });

    test('distance, speed and temperature texts', () {
      expect(metric.distance(10), '10.0 km');
      expect(imperial.distance(10), '6.2 mi');
      expect(metric.distance(3.456, decimals: 2), '3.46 km');
      expect(metric.speedText(88.4), '88 km/h');
      expect(imperial.speedText(100), '62 mph');
      expect(metric.tempText(90.4), '90 °C');
      expect(imperial.tempText(90), '194 °F');
    });

    test('never shows minus zero', () {
      expect(Units.number(-0.2, 0), '0');
      expect(Units.number(-0.04, 1), '0.0');
      expect(Units.number(-0.004, 2), '0.00');
      expect(Units.number(-1.2, 0), '-1');
      expect(Units.number(-0.06, 1), '-0.1');
      expect(Units.number(-10.04, 1), '-10.0');
    });
  });

  test('formatDuration', () {
    expect(formatDuration(Duration.zero), '0s');
    expect(formatDuration(const Duration(seconds: 45)), '45s');
    expect(formatDuration(const Duration(minutes: 2, seconds: 5)), '2m 05s');
    expect(formatDuration(const Duration(hours: 3, minutes: 7, seconds: 59)), '3h 07m');
  });

  test('formatBytes', () {
    expect(formatBytes(512), '512 B');
    expect(formatBytes(2048), '2.0 KB');
    expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
    expect(formatBytes(3 * 1024 * 1024 * 1024), '3.00 GB');
  });

  test('formatCount', () {
    expect(formatCount(7), '7');
    expect(formatCount(1234567), '1,234,567');
  });
}
