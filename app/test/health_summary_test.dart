import 'package:drivly/features/dashboard/health_summary.dart';
import 'package:drivly/features/fault_codes/dtc_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeHealth', () {
    test('not checked until the first scan', () {
      expect(computeHealth(const HealthInput(checked: false)).status, HealthStatus.notChecked);
    });

    test('all good', () {
      final r = computeHealth(const HealthInput(checked: true, coolant: 90, battery: 14.1, engineRunning: true));
      expect(r.status, HealthStatus.good);
    });

    test('pending or medium codes → check soon', () {
      expect(computeHealth(const HealthInput(checked: true, pendingCount: 1)).status, HealthStatus.checkSoon);
      expect(
        computeHealth(const HealthInput(checked: true, storedSeverities: [Severity.medium])).status,
        HealthStatus.checkSoon,
      );
    });

    test('engine light, high severity, overheating or dead battery → needs attention', () {
      expect(computeHealth(const HealthInput(checked: true, milOn: true)).status, HealthStatus.needsAttention);
      expect(
        computeHealth(const HealthInput(checked: true, storedSeverities: [Severity.high])).status,
        HealthStatus.needsAttention,
      );
      expect(computeHealth(const HealthInput(checked: true, coolant: 118)).status, HealthStatus.needsAttention);
      expect(
        computeHealth(const HealthInput(checked: true, battery: 11.5, engineRunning: true)).status,
        HealthStatus.needsAttention,
      );
    });

    test('hot engine or weak charging → check soon', () {
      expect(computeHealth(const HealthInput(checked: true, coolant: 112)).status, HealthStatus.checkSoon);
      expect(
        computeHealth(const HealthInput(checked: true, battery: 12.8, engineRunning: true)).status,
        HealthStatus.checkSoon,
      );
      expect(
        computeHealth(const HealthInput(checked: true, battery: 12.2, engineRunning: false)).status,
        HealthStatus.checkSoon,
      );
    });
  });

  group('status words', () {
    test('coolant', () {
      expect(coolantStatus(40), ValueStatus.warmingUp);
      expect(coolantStatus(92), ValueStatus.normal);
      expect(coolantStatus(112), ValueStatus.hot);
      expect(coolantStatus(120), ValueStatus.tooHot);
    });

    test('battery', () {
      expect(batteryStatus(14.1, engineRunning: true), ValueStatus.charging);
      expect(batteryStatus(12.9, engineRunning: true), ValueStatus.lowCharging);
      expect(batteryStatus(15.4, engineRunning: true), ValueStatus.tooHigh);
      expect(batteryStatus(12.6, engineRunning: false), ValueStatus.good);
      expect(batteryStatus(12.1, engineRunning: false), ValueStatus.low);
      expect(batteryStatus(11.6, engineRunning: false), ValueStatus.veryLow);
    });
  });
}
