import 'package:flutter/foundation.dart';

import '../fault_codes/dtc_database.dart';

enum HealthStatus { notChecked, good, checkSoon, needsAttention }

enum ValueStatus { warmingUp, normal, hot, tooHot, charging, lowCharging, tooHigh, good, low, veryLow }

enum Tone { good, warn, danger, neutral }

extension ValueStatusTone on ValueStatus {
  Tone get tone => switch (this) {
        ValueStatus.normal || ValueStatus.charging || ValueStatus.good => Tone.good,
        ValueStatus.warmingUp => Tone.neutral,
        ValueStatus.hot || ValueStatus.lowCharging || ValueStatus.tooHigh || ValueStatus.low => Tone.warn,
        ValueStatus.tooHot || ValueStatus.veryLow => Tone.danger,
      };
}

/// Thresholds are general guidance, kept in one place (§4.3).
abstract final class Thresholds {
  static const coolantWarm = 70.0;
  static const coolantHot = 110.0;
  static const coolantTooHot = 115.0;
  static const chargingMin = 13.2;
  static const chargingMax = 14.8;
  static const chargingTooHigh = 15.0;
  static const runningLow = 12.0;
  static const restingGood = 12.4;
  static const restingLow = 12.0;
}

ValueStatus coolantStatus(double c) {
  if (c < Thresholds.coolantWarm) return ValueStatus.warmingUp;
  if (c < Thresholds.coolantHot) return ValueStatus.normal;
  if (c <= Thresholds.coolantTooHot) return ValueStatus.hot;
  return ValueStatus.tooHot;
}

ValueStatus batteryStatus(double v, {required bool engineRunning}) {
  if (engineRunning) {
    if (v > Thresholds.chargingTooHigh) return ValueStatus.tooHigh;
    if (v >= Thresholds.chargingMin) return ValueStatus.charging;
    if (v >= Thresholds.runningLow) return ValueStatus.lowCharging;
    return ValueStatus.veryLow;
  }
  if (v >= Thresholds.restingGood) return ValueStatus.good;
  if (v >= Thresholds.restingLow) return ValueStatus.low;
  return ValueStatus.veryLow;
}

@immutable
class HealthInput {
  const HealthInput({
    required this.checked,
    this.milOn = false,
    this.storedSeverities = const [],
    this.pendingCount = 0,
    this.coolant,
    this.battery,
    this.engineRunning = false,
  });

  final bool checked;
  final bool milOn;
  final List<Severity> storedSeverities;
  final int pendingCount;
  final double? coolant;
  final double? battery;
  final bool engineRunning;
}

@immutable
class HealthResult {
  const HealthResult(this.status, {this.problems = 0, this.milOn = false, this.hotEngine = false, this.lowBattery = false});
  final HealthStatus status;
  final int problems;
  final bool milOn;
  final bool hotEngine;
  final bool lowBattery;
}

/// Pure function, unit-tested. Free-tier health logic from §4.3.
HealthResult computeHealth(HealthInput i) {
  if (!i.checked) return const HealthResult(HealthStatus.notChecked);
  final problems = i.storedSeverities.length + i.pendingCount;
  final c = i.coolant;
  final b = i.battery;
  final tooHot = c != null && c > Thresholds.coolantTooHot;
  final hot = c != null && c >= Thresholds.coolantHot && !tooHot;
  final battCritical = b != null && i.engineRunning && b < Thresholds.runningLow;
  final battWarn = b != null &&
      ((i.engineRunning && b >= Thresholds.runningLow && b < Thresholds.chargingMin) ||
          (!i.engineRunning && b < Thresholds.restingGood));

  if (i.milOn || i.storedSeverities.contains(Severity.high) || tooHot || battCritical) {
    return HealthResult(HealthStatus.needsAttention,
        problems: problems, milOn: i.milOn, hotEngine: tooHot, lowBattery: battCritical);
  }
  if (problems > 0 || hot || battWarn) {
    return HealthResult(HealthStatus.checkSoon, problems: problems, hotEngine: hot, lowBattery: battWarn);
  }
  return const HealthResult(HealthStatus.good);
}
