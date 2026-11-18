import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:obd_core/obd_core.dart';

import '../data/settings.dart';

/// SI in storage, user units on screen. The only place conversion happens.
class Units {
  const Units(this.speed, this.temp);
  final SpeedUnit speed;
  final TempUnit temp;

  bool get imperialDistance => speed == SpeedUnit.mph;

  double convert(SensorUnit unit, double v) => switch (unit) {
        SensorUnit.kmh when speed == SpeedUnit.mph => v * 0.621371,
        SensorUnit.km when speed == SpeedUnit.mph => v * 0.621371,
        SensorUnit.celsius when temp == TempUnit.fahrenheit => v * 9 / 5 + 32,
        _ => v,
      };

  String symbol(SensorUnit unit) => switch (unit) {
        SensorUnit.kmh => speed == SpeedUnit.mph ? 'mph' : 'km/h',
        SensorUnit.km => speed == SpeedUnit.mph ? 'mi' : 'km',
        SensorUnit.celsius => temp == TempUnit.fahrenheit ? '°F' : '°C',
        _ => unit.symbol,
      };

  double value(Sensor s, double v) => convert(s.unit, v);
  String unitOf(Sensor s) => symbol(s.unit);

  /// "92" / "14.1" / "84,215.3", without unit.
  String format(Sensor s, double v, {int? decimals}) {
    final d = decimals ?? s.decimals;
    return number(convert(s.unit, v), d);
  }

  String formatWithUnit(Sensor s, double v) {
    final u = unitOf(s);
    return u.isEmpty ? format(s, v) : '${format(s, v)} $u';
  }

  String distance(double km, {int decimals = 1}) =>
      '${number(convert(SensorUnit.km, km), decimals)} ${symbol(SensorUnit.km)}';

  String speedText(double kmh) => '${number(convert(SensorUnit.kmh, kmh), 0)} ${symbol(SensorUnit.kmh)}';

  String tempText(double c) => '${number(convert(SensorUnit.celsius, c), 0)} ${symbol(SensorUnit.celsius)}';

  static String number(double v, int decimals) {
    final f = NumberFormat.decimalPatternDigits(decimalDigits: decimals);
    final out = f.format(v);
    // A small negative that rounds to zero would read "-0" or "-0.0".
    return out.startsWith('-') && !out.contains(RegExp('[1-9]')) ? out.substring(1) : out;
  }
}

final unitsProvider = Provider<Units>((ref) {
  final s = ref.watch(settingsProvider);
  return Units(s.speedUnit, s.tempUnit);
});

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
  if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
  return '${s}s';
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
}

String formatCount(int n) => NumberFormat.decimalPattern().format(n);
