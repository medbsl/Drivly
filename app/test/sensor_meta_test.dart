import 'package:drivly/core/sensor_meta.dart';
import 'package:drivly/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obd_core/obd_core.dart';

void main() {
  final l = lookupAppLocalizations(const Locale('en'));

  test('every sensor has a plain-language label and explanation', () {
    for (final s in Sensors.all) {
      final t = sensorText(l, s);
      expect(t.label, isNotEmpty, reason: s.key);
      expect(t.info, isNotEmpty, reason: s.key);
      expect(t.label == s.name && t.info == s.name, isFalse,
          reason: '${s.key} falls back to its technical name: add it to sensorText');
    }
  });

  test('every sensor has an icon and every group a label', () {
    for (final s in Sensors.all) {
      expect(sensorIcon(s), isNotNull, reason: s.key);
    }
    for (final g in SensorGroup.values) {
      expect(groupLabel(l, g), isNotEmpty, reason: g.name);
    }
  });

  test('flags and the reference torque constant are not charted', () {
    expect(isChartable(Sensors.speed), isTrue);
    expect(isChartable(Sensors.coolant), isTrue);
    expect(isChartable(Sensors.mil), isFalse);
    expect(isChartable(Sensors.referenceTorque), isFalse);
  });

  test('only 0–100 % values get a percentage bar', () {
    expect(isPercentLike(Sensors.load), isTrue);
    expect(isPercentLike(Sensors.speed), isFalse);
    final trims = Sensors.all.where((s) => s.unit == SensorUnit.percent && s.min < 0);
    expect(trims, isNotEmpty, reason: 'fuel trims are percent but can be negative');
    for (final s in trims) {
      expect(isPercentLike(s), isFalse, reason: s.key);
    }
  });
}
