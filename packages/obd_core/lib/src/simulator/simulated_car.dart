import 'dart:math';

/// A small physics loop for a believable drive: idle → town → highway →
/// town → stop, with warm-up, fuel burn and a couple of fault codes.
class SimulatedCar {
  SimulatedCar({
    int seed = 7,
    this.vin = 'WVWZZZAUZGW123456',
    List<String>? stored,
    List<String>? pending,
    this.coolant = 64,
  })  : _rng = Random(seed),
        stored = stored ?? ['P0133'],
        pending = pending ?? ['P0442'];

  final Random _rng;
  final String vin;
  List<String> stored;
  List<String> pending;
  bool milOn = false;
  bool ignitionOn = true;

  double t = 0;
  double speed = 0;
  double rpm = 820;
  double coolant;
  double oil = 52;
  double iat = 26;
  double ambient = 17;
  double load = 21;
  double throttle = 14.5;
  double pedal = 0;
  double fuel = 63;
  double voltage = 14.1;
  double maf = 3.2;
  double map = 31;
  double timing = 11;
  double fuelRate = 0.9;
  double stft = 0;
  double ltft = 2.3;
  double o2 = 0.45;
  double catTemp = 380;
  double baro = 101;
  double runTime = 0;
  double distanceSinceClear = 1240;
  double odometer = 84215.3;
  int warmups = 12;
  int gear = 0;

  /// (start second, target km/h). Loops every [cycleLength] seconds.
  static const _cycle = [
    (0.0, 0.0), (10.0, 32.0), (22.0, 50.0), (60.0, 72.0), (80.0, 105.0),
    (140.0, 118.0), (165.0, 88.0), (185.0, 55.0), (210.0, 30.0), (224.0, 0.0),
  ];
  static const cycleLength = 245.0;

  double get _target {
    final c = t % cycleLength;
    var target = 0.0;
    for (final (start, v) in _cycle) {
      if (c >= start) target = v;
    }
    return target;
  }

  double _noise(double amp) => (_rng.nextDouble() * 2 - 1) * amp;

  double _approach(double v, double target, double rate, double dt) => v + (target - v) * min(1.0, rate * dt);

  /// Advances the simulation by [dt] seconds.
  void advance(double dt) {
    if (dt <= 0) return;
    if (dt > 1) {
      // Large gaps (app paused) are integrated in 1 s steps.
      var left = dt;
      while (left > 0) {
        advance(min(1.0, left));
        left -= 1;
      }
      return;
    }
    t += dt;
    if (!ignitionOn) return;
    runTime += dt;

    // Longitudinal: limited accel / braking toward the cycle target.
    final target = _target;
    final dv = (target - speed).clamp(-11.0 * dt, 7.5 * dt) + _noise(0.25) * dt;
    final accel = dt > 0 ? dv / dt : 0.0; // km/h per s
    speed = max(0, speed + dv);
    if (speed < 0.4 && target == 0) speed = 0;

    // Gearbox.
    const limits = [1.0, 18.0, 33.0, 52.0, 72.0, 96.0];
    const kmhPer1000 = [0.0, 7.6, 13.4, 20.5, 27.8, 35.2, 42.0];
    gear = 0;
    for (var g = 0; g < limits.length; g++) {
      if (speed >= limits[g]) gear = g + 1;
    }
    final rpmTarget = gear == 0
        ? 790 + _noise(25)
        : (speed / kmhPer1000[gear] * 1000).clamp(1150.0, 5800.0) + max(0, accel) * 55 + _noise(30);
    rpm = _approach(rpm, rpmTarget, 7, dt);

    final effort = (accel / 7.5).clamp(-1.0, 1.0);
    pedal = _approach(pedal, effort > 0 ? 18 + effort * 60 + speed * 0.12 : (target > 0 ? 6 + speed * 0.1 : 0), 4, dt).clamp(0, 100);
    throttle = _approach(throttle, 14.5 + pedal * 0.72, 5, dt).clamp(0, 100);
    load = _approach(load, (19 + max(0.0, effort) * 62 + speed * 0.22 - (effort < 0 ? 12 : 0)).clamp(8.0, 100.0), 4, dt);
    map = _approach(map, 28 + load * 0.72, 5, dt);
    maf = max(1.2, rpm / 1000 * load / 100 * 24 + 1.4 + _noise(0.2));
    fuelRate = effort < -0.2 && gear > 0 ? 0.0 : maf / 14.7 * 3600 / 745;
    timing = (8 + rpm / 1000 * 3.2 - load * 0.07 + _noise(0.6)).clamp(-10.0, 45.0);

    // Thermal.
    coolant = _approach(coolant, 90 + load * 0.04, 0.012, dt) + _noise(0.03);
    oil = _approach(oil, coolant + 4, 0.006, dt);
    iat = _approach(iat, ambient + (speed < 15 ? 15 : 6), 0.05, dt);
    catTemp = _approach(catTemp, 360 + load * 4.2, 0.08, dt);

    // Fuel, electrics, mixture.
    fuel = max(0, fuel - fuelRate / 3600 * dt / 55 * 100);
    voltage = 14.05 + _noise(0.06);
    stft = (stft * 0.6 + _noise(4)).clamp(-25.0, 25.0);
    o2 = coolant > 70 ? 0.45 + 0.4 * sin(t * 2 * pi * 1.1) + _noise(0.03) : 0.45;
    o2 = o2.clamp(0.05, 0.95);

    final km = speed / 3600 * dt;
    distanceSinceClear += km;
    odometer += km;
  }
}
