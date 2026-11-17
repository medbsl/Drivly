import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:obd_core/obd_core.dart';

import '../../data/repositories.dart';

/// Saves every reading. Buffers in memory and writes one transaction per
/// second so SQLite stays cheap even at 20+ readings/s.
class HistoryRecorder {
  HistoryRecorder(this._repo, this.sessionId, {this.flushEvery = const Duration(seconds: 1)});

  final HistoryRepository _repo;
  final String sessionId;
  final Duration flushEvery;
  final List<SensorReading> _buffer = [];
  Timer? _timer;
  Future<void> _writing = Future<void>.value();
  int saved = 0;

  void start() {
    _timer ??= Timer.periodic(flushEvery, (_) => flush());
  }

  void add(SensorReading r) => _buffer.add(r);

  Future<void> flush() {
    if (_buffer.isEmpty) return _writing;
    final batch = List<SensorReading>.of(_buffer);
    _buffer.clear();
    _writing = _writing.then((_) async {
      try {
        await _repo.insertReadings(sessionId, batch);
        saved += batch.length;
      } catch (e) {
        debugPrint('history flush failed: $e');
      }
    });
    return _writing;
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    await flush();
  }
}
