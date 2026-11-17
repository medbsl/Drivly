import 'sensor.dart';

// Decoders. A, B, C, D are data bytes after the PID byte.
double _a(List<int> d) => d[0].toDouble();
double _aMinus40(List<int> d) => d[0] - 40.0;
double _percent(List<int> d) => d[0] * 100 / 255;
double _trim(List<int> d) => (d[0] - 128) * 100 / 128;
double _ab(List<int> d) => (256.0 * d[0] + d[1]);
double _rpm(List<int> d) => _ab(d) / 4;
double _maf(List<int> d) => _ab(d) / 100;
double _timing(List<int> d) => d[0] / 2 - 64;
double _o2(List<int> d) => d[0] / 200;
double _fuelPressure(List<int> d) => d[0] * 3.0;
double _railRel(List<int> d) => _ab(d) * 0.079;
double _railGauge(List<int> d) => _ab(d) * 10;
double _catTemp(List<int> d) => _ab(d) / 10 - 40;
double _moduleVolts(List<int> d) => _ab(d) / 1000;
double _absLoad(List<int> d) => _ab(d) * 100 / 255;
double _lambda(List<int> d) => _ab(d) * 2 / 65536;
double _injTiming(List<int> d) => _ab(d) / 128 - 210;
double _fuelRate(List<int> d) => _ab(d) / 20;
double _torquePct(List<int> d) => d[0] - 125.0;
double _odometer(List<int> d) => ((d[0] << 24) | (d[1] << 16) | (d[2] << 8) | d[3]) / 10;

/// Every value Drivly knows how to read. Order = default display order.
abstract final class Sensors {
  static const speed = Sensor(id: 0x0D, pid: 0x0D, bytes: 1, decode: _a, key: 'speed', name: 'Vehicle speed', unit: SensorUnit.kmh, min: 0, max: 255, tier: PollTier.fast, group: SensorGroup.motion);
  static const rpm = Sensor(id: 0x0C, pid: 0x0C, bytes: 2, decode: _rpm, key: 'rpm', name: 'Engine RPM', unit: SensorUnit.rpm, min: 0, max: 16383.75, tier: PollTier.fast, group: SensorGroup.engine);
  static const coolant = Sensor(id: 0x05, pid: 0x05, bytes: 1, decode: _aMinus40, key: 'coolant', name: 'Engine coolant temperature', unit: SensorUnit.celsius, min: -40, max: 215, tier: PollTier.slow, group: SensorGroup.temperature);
  static const battery = Sensor(id: 0x100, key: 'battery', name: 'Battery voltage (ATRV)', unit: SensorUnit.volts, min: 0, max: 20, tier: PollTier.slow, group: SensorGroup.electrical, decimals: 1);
  static const load = Sensor(id: 0x04, pid: 0x04, bytes: 1, decode: _percent, key: 'load', name: 'Calculated engine load', unit: SensorUnit.percent, min: 0, max: 100, tier: PollTier.medium, group: SensorGroup.engine);
  static const throttle = Sensor(id: 0x11, pid: 0x11, bytes: 1, decode: _percent, key: 'throttle', name: 'Throttle position', unit: SensorUnit.percent, min: 0, max: 100, tier: PollTier.medium, group: SensorGroup.engine);
  static const intakeTemp = Sensor(id: 0x0F, pid: 0x0F, bytes: 1, decode: _aMinus40, key: 'intakeTemp', name: 'Intake air temperature', unit: SensorUnit.celsius, min: -40, max: 215, tier: PollTier.slow, group: SensorGroup.temperature);
  static const fuelLevel = Sensor(id: 0x2F, pid: 0x2F, bytes: 1, decode: _percent, key: 'fuelLevel', name: 'Fuel tank level input', unit: SensorUnit.percent, min: 0, max: 100, tier: PollTier.slow, group: SensorGroup.fuel);
  static const fuelRate = Sensor(id: 0x5E, pid: 0x5E, bytes: 2, decode: _fuelRate, key: 'fuelRate', name: 'Engine fuel rate', unit: SensorUnit.litersPerHour, min: 0, max: 3276.75, tier: PollTier.medium, group: SensorGroup.fuel, decimals: 1);
  static const maf = Sensor(id: 0x10, pid: 0x10, bytes: 2, decode: _maf, key: 'maf', name: 'Mass air flow rate', unit: SensorUnit.gramsPerSecond, min: 0, max: 655.35, tier: PollTier.medium, group: SensorGroup.air, decimals: 1);
  static const map = Sensor(id: 0x0B, pid: 0x0B, bytes: 1, decode: _a, key: 'map', name: 'Intake manifold absolute pressure', unit: SensorUnit.kpa, min: 0, max: 255, tier: PollTier.medium, group: SensorGroup.air);
  static const timing = Sensor(id: 0x0E, pid: 0x0E, bytes: 1, decode: _timing, key: 'timing', name: 'Timing advance', unit: SensorUnit.degrees, min: -64, max: 63.5, tier: PollTier.medium, group: SensorGroup.engine, decimals: 1);
  static const oilTemp = Sensor(id: 0x5C, pid: 0x5C, bytes: 1, decode: _aMinus40, key: 'oilTemp', name: 'Engine oil temperature', unit: SensorUnit.celsius, min: -40, max: 210, tier: PollTier.slow, group: SensorGroup.temperature);
  static const ambientTemp = Sensor(id: 0x46, pid: 0x46, bytes: 1, decode: _aMinus40, key: 'ambientTemp', name: 'Ambient air temperature', unit: SensorUnit.celsius, min: -40, max: 215, tier: PollTier.slow, group: SensorGroup.temperature);
  static const moduleVoltage = Sensor(id: 0x42, pid: 0x42, bytes: 2, decode: _moduleVolts, key: 'moduleVoltage', name: 'Control module voltage', unit: SensorUnit.volts, min: 0, max: 65.535, tier: PollTier.slow, group: SensorGroup.electrical, decimals: 2);
  static const absoluteLoad = Sensor(id: 0x43, pid: 0x43, bytes: 2, decode: _absLoad, key: 'absoluteLoad', name: 'Absolute load value', unit: SensorUnit.percent, min: 0, max: 25700, tier: PollTier.medium, group: SensorGroup.engine);
  static const relativeThrottle = Sensor(id: 0x45, pid: 0x45, bytes: 1, decode: _percent, key: 'relativeThrottle', name: 'Relative throttle position', unit: SensorUnit.percent, min: 0, max: 100, tier: PollTier.medium, group: SensorGroup.engine);
  static const pedalD = Sensor(id: 0x49, pid: 0x49, bytes: 1, decode: _percent, key: 'pedal', name: 'Accelerator pedal position D', unit: SensorUnit.percent, min: 0, max: 100, tier: PollTier.medium, group: SensorGroup.engine);
  static const relativePedal = Sensor(id: 0x5A, pid: 0x5A, bytes: 1, decode: _percent, key: 'relativePedal', name: 'Relative accelerator pedal position', unit: SensorUnit.percent, min: 0, max: 100, tier: PollTier.medium, group: SensorGroup.engine);
  static const commandedThrottle = Sensor(id: 0x4C, pid: 0x4C, bytes: 1, decode: _percent, key: 'commandedThrottle', name: 'Commanded throttle actuator', unit: SensorUnit.percent, min: 0, max: 100, tier: PollTier.medium, group: SensorGroup.engine);
  static const demandTorque = Sensor(id: 0x61, pid: 0x61, bytes: 1, decode: _torquePct, key: 'demandTorque', name: "Driver's demand engine torque", unit: SensorUnit.percent, min: -125, max: 130, tier: PollTier.medium, group: SensorGroup.engine);
  static const actualTorque = Sensor(id: 0x62, pid: 0x62, bytes: 1, decode: _torquePct, key: 'actualTorque', name: 'Actual engine torque', unit: SensorUnit.percent, min: -125, max: 130, tier: PollTier.medium, group: SensorGroup.engine);
  static const referenceTorque = Sensor(id: 0x63, pid: 0x63, bytes: 2, decode: _ab, key: 'referenceTorque', name: 'Engine reference torque', unit: SensorUnit.newtonMeters, min: 0, max: 65535, tier: PollTier.rare, group: SensorGroup.engine);
  static const stft1 = Sensor(id: 0x06, pid: 0x06, bytes: 1, decode: _trim, key: 'stft1', name: 'Short term fuel trim, bank 1', unit: SensorUnit.percent, min: -100, max: 99.3, tier: PollTier.medium, group: SensorGroup.fuel, decimals: 1);
  static const ltft1 = Sensor(id: 0x07, pid: 0x07, bytes: 1, decode: _trim, key: 'ltft1', name: 'Long term fuel trim, bank 1', unit: SensorUnit.percent, min: -100, max: 99.3, tier: PollTier.slow, group: SensorGroup.fuel, decimals: 1);
  static const stft2 = Sensor(id: 0x08, pid: 0x08, bytes: 1, decode: _trim, key: 'stft2', name: 'Short term fuel trim, bank 2', unit: SensorUnit.percent, min: -100, max: 99.3, tier: PollTier.medium, group: SensorGroup.fuel, decimals: 1);
  static const ltft2 = Sensor(id: 0x09, pid: 0x09, bytes: 1, decode: _trim, key: 'ltft2', name: 'Long term fuel trim, bank 2', unit: SensorUnit.percent, min: -100, max: 99.3, tier: PollTier.slow, group: SensorGroup.fuel, decimals: 1);
  static const fuelPressure = Sensor(id: 0x0A, pid: 0x0A, bytes: 1, decode: _fuelPressure, key: 'fuelPressure', name: 'Fuel pressure (gauge)', unit: SensorUnit.kpa, min: 0, max: 765, tier: PollTier.slow, group: SensorGroup.fuel);
  static const railPressure = Sensor(id: 0x22, pid: 0x22, bytes: 2, decode: _railRel, key: 'railPressure', name: 'Fuel rail pressure (relative to vacuum)', unit: SensorUnit.kpa, min: 0, max: 5177.3, tier: PollTier.slow, group: SensorGroup.fuel);
  static const railGaugePressure = Sensor(id: 0x23, pid: 0x23, bytes: 2, decode: _railGauge, key: 'railGaugePressure', name: 'Fuel rail gauge pressure', unit: SensorUnit.kpa, min: 0, max: 655350, tier: PollTier.slow, group: SensorGroup.fuel);
  static const injectionTiming = Sensor(id: 0x5D, pid: 0x5D, bytes: 2, decode: _injTiming, key: 'injectionTiming', name: 'Fuel injection timing', unit: SensorUnit.degrees, min: -210, max: 302, tier: PollTier.slow, group: SensorGroup.fuel, decimals: 1);
  static const ethanol = Sensor(id: 0x52, pid: 0x52, bytes: 1, decode: _percent, key: 'ethanol', name: 'Ethanol fuel %', unit: SensorUnit.percent, min: 0, max: 100, tier: PollTier.rare, group: SensorGroup.fuel);
  static const lambda = Sensor(id: 0x44, pid: 0x44, bytes: 2, decode: _lambda, key: 'lambda', name: 'Commanded air-fuel equivalence ratio', unit: SensorUnit.ratio, min: 0, max: 2, tier: PollTier.slow, group: SensorGroup.air, decimals: 2);
  static const baro = Sensor(id: 0x33, pid: 0x33, bytes: 1, decode: _a, key: 'baro', name: 'Absolute barometric pressure', unit: SensorUnit.kpa, min: 0, max: 255, tier: PollTier.rare, group: SensorGroup.air);
  static const o2b1s1 = Sensor(id: 0x14, pid: 0x14, bytes: 2, decode: _o2, key: 'o2b1s1', name: 'Oxygen sensor bank 1 sensor 1', unit: SensorUnit.volts, min: 0, max: 1.275, tier: PollTier.medium, group: SensorGroup.emissions, decimals: 2);
  static const o2b1s2 = Sensor(id: 0x15, pid: 0x15, bytes: 2, decode: _o2, key: 'o2b1s2', name: 'Oxygen sensor bank 1 sensor 2', unit: SensorUnit.volts, min: 0, max: 1.275, tier: PollTier.slow, group: SensorGroup.emissions, decimals: 2);
  static const catTemp = Sensor(id: 0x3C, pid: 0x3C, bytes: 2, decode: _catTemp, key: 'catTemp', name: 'Catalyst temperature bank 1 sensor 1', unit: SensorUnit.celsius, min: -40, max: 6513.5, tier: PollTier.slow, group: SensorGroup.emissions);
  static const egr = Sensor(id: 0x2C, pid: 0x2C, bytes: 1, decode: _percent, key: 'egr', name: 'Commanded EGR', unit: SensorUnit.percent, min: 0, max: 100, tier: PollTier.slow, group: SensorGroup.emissions);
  static const evapPurge = Sensor(id: 0x2E, pid: 0x2E, bytes: 1, decode: _percent, key: 'evapPurge', name: 'Commanded evaporative purge', unit: SensorUnit.percent, min: 0, max: 100, tier: PollTier.slow, group: SensorGroup.emissions);
  static const hybridBattery = Sensor(id: 0x5B, pid: 0x5B, bytes: 1, decode: _percent, key: 'hybridBattery', name: 'Hybrid battery pack remaining life', unit: SensorUnit.percent, min: 0, max: 100, tier: PollTier.slow, group: SensorGroup.electrical);
  static const runTime = Sensor(id: 0x1F, pid: 0x1F, bytes: 2, decode: _ab, key: 'runTime', name: 'Run time since engine start', unit: SensorUnit.seconds, min: 0, max: 65535, tier: PollTier.rare, group: SensorGroup.distance);
  static const distanceWithMil = Sensor(id: 0x21, pid: 0x21, bytes: 2, decode: _ab, key: 'distanceWithMil', name: 'Distance traveled with MIL on', unit: SensorUnit.km, min: 0, max: 65535, tier: PollTier.rare, group: SensorGroup.distance);
  static const distanceSinceClear = Sensor(id: 0x31, pid: 0x31, bytes: 2, decode: _ab, key: 'distanceSinceClear', name: 'Distance traveled since codes cleared', unit: SensorUnit.km, min: 0, max: 65535, tier: PollTier.rare, group: SensorGroup.distance);
  static const warmupsSinceClear = Sensor(id: 0x30, pid: 0x30, bytes: 1, decode: _a, key: 'warmupsSinceClear', name: 'Warm-ups since codes cleared', unit: SensorUnit.count, min: 0, max: 255, tier: PollTier.rare, group: SensorGroup.distance);
  static const timeWithMil = Sensor(id: 0x4D, pid: 0x4D, bytes: 2, decode: _ab, key: 'timeWithMil', name: 'Time run with MIL on', unit: SensorUnit.minutes, min: 0, max: 65535, tier: PollTier.rare, group: SensorGroup.distance);
  static const timeSinceClear = Sensor(id: 0x4E, pid: 0x4E, bytes: 2, decode: _ab, key: 'timeSinceClear', name: 'Time since trouble codes cleared', unit: SensorUnit.minutes, min: 0, max: 65535, tier: PollTier.rare, group: SensorGroup.distance);
  static const odometer = Sensor(id: 0xA6, pid: 0xA6, bytes: 4, decode: _odometer, key: 'odometer', name: 'Odometer', unit: SensorUnit.km, min: 0, max: 429496729.5, tier: PollTier.rare, group: SensorGroup.distance, decimals: 1);

  /// Engine light state (0/1) and stored-code count, both from PID 01.
  static const mil = Sensor(id: 0x101, key: 'mil', name: 'Malfunction indicator lamp', unit: SensorUnit.flag, min: 0, max: 1, tier: PollTier.rare, group: SensorGroup.emissions);
  static const dtcCount = Sensor(id: 0x102, key: 'dtcCount', name: 'Stored DTC count', unit: SensorUnit.count, min: 0, max: 127, tier: PollTier.rare, group: SensorGroup.emissions);

  static const List<Sensor> all = [
    speed, rpm, coolant, battery, load, throttle, intakeTemp, fuelLevel,
    fuelRate, maf, map, timing, oilTemp, ambientTemp, moduleVoltage,
    absoluteLoad, relativeThrottle, pedalD, relativePedal, commandedThrottle,
    demandTorque, actualTorque, referenceTorque, stft1, ltft1, stft2, ltft2,
    fuelPressure, railPressure, railGaugePressure, injectionTiming, ethanol,
    lambda, baro, o2b1s1, o2b1s2, catTemp, egr, evapPurge, hybridBattery,
    runTime, distanceWithMil, distanceSinceClear, warmupsSinceClear,
    timeWithMil, timeSinceClear, odometer, mil, dtcCount,
  ];

  static final Map<int, Sensor> byId = {for (final s in all) s.id: s};
  static final Map<int, Sensor> byPid = {for (final s in all) if (s.pid != null) s.pid!: s};
  static final Map<String, Sensor> byKey = {for (final s in all) s.key: s};

  /// Data byte length of a mode 01 PID, including bitmask/status PIDs that
  /// are not sensors. Needed to walk multi-PID replies.
  static int? dataLength(int pid) {
    if (pid % 0x20 == 0) return 4; // supported-PID bitmasks
    if (pid == 0x01 || pid == 0x41) return 4; // monitor status
    return byPid[pid]?.bytes;
  }
}
