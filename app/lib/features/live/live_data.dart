import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obd_core/obd_core.dart';

@immutable
class TimedValue {
  const TimedValue(this.t, this.v);
  final DateTime t;
  final double v;
}

/// In-memory view of the current connection: latest value per sensor plus a
/// rolling window for real-time charts. Listeners are notified at most ~8×/s
/// no matter how fast readings arrive.
class LiveData extends ChangeNotifier {
  LiveData({this.window = const Duration(minutes: 15)});

  final Duration window;
  final Map<int, TimedValue> _latest = {};
  final Map<int, ListQueue<TimedValue>> _recent = {};
  final Set<Sensor> _polled = {};
  final Set<Sensor> _unsupported = {};
  Timer? _notifyTimer;
  bool _dirty = false;
  int sessionReadings = 0;
  double requestsPerSecond = 0;
  DateTime? sessionStart;

  Set<Sensor> get polled => Set.unmodifiable(_polled);

  /// Sensors the car reported but never answered for.
  Set<Sensor> get unsupported => Set.unmodifiable(_unsupported);

  bool get hasData => _latest.isNotEmpty;

  void begin(Iterable<Sensor> sensors) {
    _latest.clear();
    _recent.clear();
    _polled
      ..clear()
      ..addAll(sensors);
    _unsupported.clear();
    sessionReadings = 0;
    sessionStart = DateTime.now();
    _notifyNow();
  }

  void add(SensorReading r) {
    final tv = TimedValue(r.at, r.value);
    _latest[r.sensor.id] = tv;
    final q = _recent.putIfAbsent(r.sensor.id, ListQueue.new)..addLast(tv);
    final cutoff = r.at.subtract(window);
    while (q.isNotEmpty && q.first.t.isBefore(cutoff)) {
      q.removeFirst();
    }
    sessionReadings++;
    _schedule();
  }

  void markUnsupported(Iterable<Sensor> sensors) {
    _unsupported.addAll(sensors);
    _polled.removeAll(sensors);
    _schedule();
  }

  double? value(Sensor s) => _latest[s.id]?.v;
  DateTime? at(Sensor s) => _latest[s.id]?.t;

  /// Not updated for more than 3 s: shown dimmed, never silently frozen.
  bool isStale(Sensor s, {Duration threshold = const Duration(seconds: 3)}) {
    final t = _latest[s.id]?.t;
    if (t == null) return true;
    final limit = s.tier == PollTier.rare ? const Duration(seconds: 75) : (s.tier == PollTier.slow ? const Duration(seconds: 12) : threshold);
    return DateTime.now().difference(t) > limit;
  }

  List<TimedValue> recent(Sensor s, [Duration? span]) {
    final q = _recent[s.id];
    if (q == null || q.isEmpty) return const [];
    if (span == null) return q.toList(growable: false);
    final cutoff = DateTime.now().subtract(span);
    return q.where((e) => !e.t.isBefore(cutoff)).toList(growable: false);
  }

  void _schedule() {
    _dirty = true;
    _notifyTimer ??= Timer(const Duration(milliseconds: 125), () {
      _notifyTimer = null;
      if (_dirty) _notifyNow();
    });
  }

  void _notifyNow() {
    _dirty = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _notifyTimer?.cancel();
    super.dispose();
  }
}

final liveDataProvider = Provider<LiveData>((ref) {
  final d = LiveData();
  ref.onDispose(d.dispose);
  return d;
});
