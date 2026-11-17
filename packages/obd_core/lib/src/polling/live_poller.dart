import 'dart:async';

import '../adapter/diagnostic_adapter.dart';
import '../adapter/obd_result.dart';
import '../pids/sensor.dart';
import '../pids/sensors.dart';
import 'poll_scheduler.dart';

enum PollerEvent {
  /// Too many failures in a row: the link or the car is gone.
  lost,
}

/// Runs the poll loop: asks the scheduler what is due, reads it, publishes
/// timestamped readings. The UI, the history recorder and the trip recorder
/// all subscribe to [readings].
class LivePoller {
  LivePoller(
    this.adapter,
    Iterable<Sensor> sensors, {
    DateTime Function()? clock,
    this.maxConsecutiveFailures = 6,
    this.maxSilentReplies = 12,
  })  : _clock = clock ?? DateTime.now,
        scheduler = PollScheduler(
          sensors.where((s) => s != Sensors.dtcCount), // comes with mil
          batchSize: (adapter.info?.multiPid ?? false) ? 6 : 1,
        );

  final DiagnosticAdapter adapter;
  final PollScheduler scheduler;
  final int maxConsecutiveFailures;

  /// PID requests in a row without any data before the car counts as gone.
  final int maxSilentReplies;
  final DateTime Function() _clock;

  final _readings = StreamController<SensorReading>.broadcast();
  final _events = StreamController<PollerEvent>.broadcast();
  bool _running = false;
  Future<void>? _loop;
  double _requestsPerSecond = 0;
  int _total = 0;

  Stream<SensorReading> get readings => _readings.stream;
  Stream<PollerEvent> get events => _events.stream;
  bool get isRunning => _running;

  /// Smoothed request rate, for the "adapter speed" readout.
  double get requestsPerSecond => _requestsPerSecond;
  int get totalRequests => _total;

  void start() {
    if (_running) return;
    _running = true;
    _loop = _run();
  }

  Future<void> stop() async {
    _running = false;
    await _loop;
  }

  Future<void> dispose() async {
    await stop();
    await _readings.close();
    await _events.close();
  }

  Future<void> _run() async {
    var failures = 0;
    var silent = 0;
    while (_running) {
      final batch = scheduler.next(_clock().millisecondsSinceEpoch);
      if (batch.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        continue;
      }
      final started = _clock();
      final result = await _read(batch);
      if (!_running) break;
      _total++;

      final fromCar = batch.first != Sensors.battery; // ATRV answers even with the car off
      switch (result) {
        case Ok(:final value):
          failures = 0;
          if (fromCar) silent = value.isEmpty ? silent + 1 : 0;
          final got = value.map((r) => r.sensor.id).toSet();
          for (final r in value) {
            scheduler.gotData(r.sensor);
            _readings.add(r);
          }
          if (silent < 2) {
            for (final s in batch) {
              if (!got.contains(s.id) && s != Sensors.mil) scheduler.gotNoData(s);
            }
          }
        case NoData() || NotSupported():
          failures = 0; // the adapter is alive; the car may just lack this value
          if (fromCar) silent++;
          // Only blame the sensor while the car is otherwise answering;
          // otherwise an ignition-off would drop every sensor.
          if (silent < 2 || !fromCar) {
            for (final s in batch) {
              scheduler.gotNoData(s);
            }
          }
        default:
          failures++;
          await Future<void>.delayed(Duration(milliseconds: (150 * failures).clamp(150, 1500)));
      }
      // Ignition off mid-session shows up as endless NO DATA, not errors.
      if (failures >= maxConsecutiveFailures || silent >= maxSilentReplies) {
        _running = false;
        _events.add(PollerEvent.lost);
        break;
      }

      final ms = _clock().difference(started).inMicroseconds / 1000;
      if (ms > 0) {
        final inst = 1000 / ms;
        _requestsPerSecond = _requestsPerSecond == 0 ? inst : _requestsPerSecond * 0.9 + inst * 0.1;
      }
      await Future<void>.delayed(Duration.zero); // let the UI breathe
    }
  }

  Future<ObdResult<List<SensorReading>>> _read(List<Sensor> batch) async {
    final first = batch.first;
    if (first == Sensors.battery) {
      final r = await adapter.readBatteryVoltage();
      return switch (r) {
        Ok(:final value) => Ok([SensorReading(Sensors.battery, value, _clock())]),
        _ => _cast(r),
      };
    }
    if (first == Sensors.mil || first == Sensors.dtcCount) {
      final r = await adapter.readMonitorStatus();
      final at = _clock();
      return switch (r) {
        Ok(:final value) => Ok([
            SensorReading(Sensors.mil, value.milOn ? 1 : 0, at),
            SensorReading(Sensors.dtcCount, value.dtcCount.toDouble(), at),
          ]),
        _ => _cast(r),
      };
    }
    return adapter.readSensors(batch);
  }

  ObdResult<List<SensorReading>> _cast<T>(ObdResult<T> r) => switch (r) {
        NoData() => const NoData(),
        NotSupported() => const NotSupported(),
        CarNotResponding() => const CarNotResponding(),
        TimedOut() => const TimedOut(),
        AdapterError(:final kind, :final raw) => AdapterError(kind, raw),
        Malformed(:final raw) => Malformed(raw),
        InitFailed(:final reason, :final detail) => InitFailed(reason, detail),
        Ok() => const Malformed('unexpected'),
      };
}
