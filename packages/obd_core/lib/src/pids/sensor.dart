/// Physical unit a sensor value is stored in. Storage is always SI-ish;
/// conversion to mph / °F happens only when displayed.
enum SensorUnit {
  rpm('rpm'),
  kmh('km/h'),
  celsius('°C'),
  percent('%'),
  volts('V'),
  kpa('kPa'),
  gramsPerSecond('g/s'),
  degrees('°'),
  seconds('s'),
  minutes('min'),
  km('km'),
  litersPerHour('L/h'),
  newtonMeters('Nm'),
  ratio('λ'),
  count(''),
  flag('');

  const SensorUnit(this.symbol);
  final String symbol;
}

/// How often a value is worth refreshing.
enum PollTier {
  fast(Duration(milliseconds: 250)),
  medium(Duration(milliseconds: 1000)),
  slow(Duration(seconds: 4)),
  rare(Duration(seconds: 30));

  const PollTier(this.interval);
  final Duration interval;
}

enum SensorGroup { motion, engine, temperature, fuel, air, electrical, emissions, distance }

typedef PidDecoder = double Function(List<int> d);

/// A value the app can show, chart and store. Most are mode 01 PIDs; a few
/// are "virtual" (battery via ATRV, engine light from PID 01).
class Sensor {
  const Sensor({
    required this.id,
    required this.key,
    required this.name,
    required this.unit,
    required this.min,
    required this.max,
    required this.tier,
    required this.group,
    this.pid,
    this.bytes = 0,
    this.decode,
    this.decimals = 0,
  });

  /// Stable id used in storage. Equals the PID for mode 01 sensors,
  /// ≥ 0x100 for virtual sensors.
  final int id;
  final String key;

  /// Technical English name (logs, "for your mechanic").
  final String name;
  final SensorUnit unit;
  final double min;
  final double max;
  final PollTier tier;
  final SensorGroup group;
  final int? pid;
  final int bytes;
  final PidDecoder? decode;
  final int decimals;

  bool get isPid => pid != null;

  /// Decodes and range-checks. Returns null for garbage.
  double? decodeChecked(List<int> data) {
    final d = decode;
    if (d == null || data.length < bytes) return null;
    final v = d(data);
    if (v.isNaN || v.isInfinite || v < min - 1e-6 || v > max + 1e-6) return null;
    return v;
  }

  @override
  bool operator ==(Object other) => other is Sensor && other.id == id;

  @override
  int get hashCode => id;

  @override
  String toString() => 'Sensor($key)';
}

class SensorReading {
  const SensorReading(this.sensor, this.value, this.at);
  final Sensor sensor;
  final double value;
  final DateTime at;

  @override
  String toString() => '${sensor.key}=$value';
}
