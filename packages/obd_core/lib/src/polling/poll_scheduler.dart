import '../pids/sensor.dart';

/// Weighted fair scheduler. Each sensor has a target interval (its tier);
/// the next request carries the most overdue sensors. Under load, refresh
/// rates degrade proportionally instead of starving slow values.
class PollScheduler {
  PollScheduler(Iterable<Sensor> sensors, {this.batchSize = 1, this.dropAfterNoData = 3})
      : _sensors = [...sensors]..sort((a, b) => a.tier.index.compareTo(b.tier.index));

  /// PID sensors per request (1, or up to 6 with multi-PID on CAN).
  final int batchSize;
  final int dropAfterNoData;
  final List<Sensor> _sensors;
  final Map<int, int> _lastMs = {};
  final Map<int, int> _noData = {};
  final Set<Sensor> _dropped = {};

  List<Sensor> get active => List.unmodifiable(_sensors);
  Set<Sensor> get dropped => Set.unmodifiable(_dropped);

  double _score(Sensor s, int nowMs, int index) {
    final last = _lastMs[s.id];
    if (last == null) return 1e9 - index; // never polled: first pass, in tier order
    return (nowMs - last) / s.tier.interval.inMilliseconds;
  }

  /// Returns the next request: one virtual sensor, or up to [batchSize] PID
  /// sensors. Empty when there is nothing left to poll.
  List<Sensor> next(int nowMs) {
    if (_sensors.isEmpty) return const [];
    final scored = <(Sensor, double)>[
      for (var i = 0; i < _sensors.length; i++) (_sensors[i], _score(_sensors[i], nowMs, i)),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    final top = scored.first.$1;
    if (!top.isPid) {
      _lastMs[top.id] = nowMs;
      return [top];
    }
    final batch = <Sensor>[top];
    for (final (s, score) in scored.skip(1)) {
      if (batch.length >= batchSize) break;
      if (s.isPid && score >= 0.6) batch.add(s);
    }
    for (final s in batch) {
      _lastMs[s.id] = nowMs;
    }
    return batch;
  }

  /// The car answered for [s].
  void gotData(Sensor s) => _noData.remove(s.id);

  /// The car didn't answer for [s]. Returns true when it was dropped.
  bool gotNoData(Sensor s) {
    final n = (_noData[s.id] ?? 0) + 1;
    _noData[s.id] = n;
    if (n >= dropAfterNoData) {
      _sensors.remove(s);
      _dropped.add(s);
      return true;
    }
    return false;
  }
}
