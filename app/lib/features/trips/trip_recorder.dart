import 'package:flutter/foundation.dart';
import 'package:obd_core/obd_core.dart';

@immutable
class TripSnapshot {
  const TripSnapshot({
    required this.startedAt,
    required this.endedAt,
    required this.distanceKm,
    required this.maxSpeed,
    required this.maxCoolant,
    required this.idleSeconds,
    required this.fuelUsedL,
    required this.hasGap,
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final double distanceKm;
  final double maxSpeed;
  final double? maxCoolant;
  final int idleSeconds;
  final double? fuelUsedL;
  final bool hasGap;

  Duration get duration => endedAt.difference(startedAt);

  double get avgSpeed {
    final h = duration.inMilliseconds / 3600000;
    return h <= 0 ? 0 : distanceKm / h;
  }
}

/// Automatic trip detection (DESIGN.md §4.8), pure and clock-free: time comes
/// from the readings themselves.
///
/// * Start: speed > 5 km/h for 5 s.
/// * Stop: speed 0 and RPM 0 for 60 s, or [finish] (disconnect).
/// * Distance: trapezoidal integral of speed; gaps > 10 s are not integrated.
/// * Discard trips under 0.2 km or 1 minute.
class TripRecorder {
  TripRecorder({required this.onFinished});

  final void Function(TripSnapshot trip) onFinished;

  static const startSpeed = 5.0;
  static const startHold = Duration(seconds: 5);
  static const stopHold = Duration(seconds: 60);
  static const maxGap = Duration(seconds: 10);
  static const minDistanceKm = 0.2;
  static const minDuration = Duration(minutes: 1);

  DateTime? _movingSince;
  DateTime? _stoppedSince;
  bool _active = false;
  DateTime? _start;
  DateTime? _lastAt;
  double? _lastSpeed;
  DateTime? _lastSpeedAt;
  double _rpm = -1;
  double _distance = 0;
  double _maxSpeed = 0;
  double? _maxCoolant;
  double _idle = 0;
  double? _fuelRate;
  DateTime? _fuelRateAt;
  double? _fuel;
  bool _gap = false;

  bool get isActive => _active;

  TripSnapshot? get current => _active ? _snapshot(_lastAt ?? _start!) : null;

  void feed(SensorReading r) {
    _lastAt = r.at;
    switch (r.sensor.key) {
      case 'speed':
        _onSpeed(r.value, r.at);
      case 'rpm':
        _rpm = r.value;
        _checkStop(r.at);
      case 'coolant':
        if (_active) _maxCoolant = _maxCoolant == null ? r.value : (r.value > _maxCoolant! ? r.value : _maxCoolant);
      case 'fuelRate':
        if (_active && _fuelRate != null && _fuelRateAt != null) {
          final dt = r.at.difference(_fuelRateAt!).inMilliseconds / 1000;
          if (dt > 0 && dt <= maxGap.inSeconds) {
            _fuel = (_fuel ?? 0) + (_fuelRate! + r.value) / 2 * dt / 3600;
          }
        }
        _fuelRate = r.value;
        _fuelRateAt = r.at;
    }
  }

  void _onSpeed(double v, DateTime at) {
    if (!_active) {
      if (v > startSpeed) {
        _movingSince ??= at;
        if (at.difference(_movingSince!) >= startHold) {
          _active = true;
          _start = _movingSince;
          _distance = 0;
          _maxSpeed = v;
          _idle = 0;
          _gap = false;
          _fuel = null;
          _stoppedSince = null;
        }
      } else {
        _movingSince = null;
      }
    } else {
      final lastAt = _lastSpeedAt;
      final last = _lastSpeed;
      if (lastAt != null && last != null) {
        final dt = at.difference(lastAt);
        if (dt <= maxGap) {
          final s = dt.inMilliseconds / 1000;
          _distance += (last + v) / 2 * s / 3600;
          if (v < 1 && last < 1 && _rpm > 0) _idle += s;
        } else {
          _gap = true;
        }
      }
      if (v > _maxSpeed) _maxSpeed = v;
      _stoppedSince = v < 1 ? (_stoppedSince ?? at) : null;
      _checkStop(at);
    }
    _lastSpeed = v;
    _lastSpeedAt = at;
  }

  void _checkStop(DateTime at) {
    if (!_active || _stoppedSince == null) return;
    if (_rpm <= 0 && at.difference(_stoppedSince!) >= stopHold) {
      finish(at: _stoppedSince);
    }
  }

  TripSnapshot _snapshot(DateTime end) => TripSnapshot(
        startedAt: _start!,
        endedAt: end,
        distanceKm: _distance,
        maxSpeed: _maxSpeed,
        maxCoolant: _maxCoolant,
        idleSeconds: _idle.round(),
        fuelUsedL: _fuel,
        hasGap: _gap,
      );

  /// Ends the current trip (auto-stop, manual stop or disconnect).
  void finish({DateTime? at}) {
    if (!_active) return;
    final trip = _snapshot(at ?? _lastAt ?? DateTime.now());
    _active = false;
    _movingSince = null;
    _stoppedSince = null;
    _maxCoolant = null;
    if (trip.distanceKm >= minDistanceKm && trip.duration >= minDuration) {
      onFinished(trip);
    }
  }
}
