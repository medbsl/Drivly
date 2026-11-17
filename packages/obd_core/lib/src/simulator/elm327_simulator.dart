import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../pids/supported_pids.dart';
import '../transport/obd_transport.dart';
import 'simulated_car.dart';

/// Faults the simulator can inject for resilience tests.
class SimulatorFaults {
  /// Ignition off: OBD requests fail.
  bool carOff = false;

  /// Adapter never answers (hung clone).
  bool adapterSilent = false;

  /// Probability of corrupting a reply.
  double garbageRate = 0;

  Duration extraLatency = Duration.zero;
}

/// An [ObdTransport] that speaks real ELM327 (v1.5 clone flavour, CAN 11-bit
/// 500 kbit/s). Demo mode, widget tests and screenshots all run through it,
/// so the whole real stack is exercised.
class Elm327Simulator implements ObdTransport {
  Elm327Simulator({
    SimulatedCar? car,
    this.realtime = true,
    this.baseLatency = const Duration(milliseconds: 28),
    this.perPidLatency = const Duration(milliseconds: 7),
    this.chunkSize = 20,
    int seed = 1,
    this.deviceName = 'Drivly Demo',
  })  : car = car ?? SimulatedCar(),
        _rng = Random(seed);

  final SimulatedCar car;
  final SimulatorFaults faults = SimulatorFaults();

  /// When true the car advances with wall-clock time and replies are delayed
  /// like a real adapter. When false (unit tests) replies are immediate and
  /// the test drives [SimulatedCar.advance].
  final bool realtime;
  final Duration baseLatency;
  final Duration perPidLatency;

  /// BLE notifications are ~20 bytes: replies are split like a real link.
  final int chunkSize;
  final String deviceName;
  final Random _rng;

  final _incoming = StreamController<List<int>>.broadcast();
  final _status = StreamController<TransportStatus>.broadcast();
  TransportStatus _current = TransportStatus.disconnected;
  final StringBuffer _line = StringBuffer();
  final Stopwatch _clock = Stopwatch();
  Duration _lastAdvance = Duration.zero;
  Future<void> _replyChain = Future<void>.value();

  // ELM settings.
  bool _echo = true;
  bool _headers = false;
  bool _spaces = true;
  bool _linefeeds = true;
  bool _protocolFound = false;

  static const _supported = <int>{
    0x01, 0x04, 0x05, 0x06, 0x07, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x11,
    0x14, 0x15, 0x1F, 0x21, 0x2F, 0x30, 0x31, 0x33, 0x3C, 0x42, 0x43, 0x44,
    0x46, 0x49, 0x4C, 0x5C, 0x5E, 0xA6,
  };

  /// Supported PIDs plus the "next bitmask" links.
  static final Set<int> supportedWithLinks = {
    ..._supported,
    for (var base = 0x20; base <= 0xC0; base += 0x20)
      if (_supported.any((p) => p > base)) base,
  };

  @override
  TransportKind get kind => TransportKind.simulated;

  @override
  String get name => deviceName;

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Stream<TransportStatus> get status => _status.stream;

  @override
  TransportStatus get currentStatus => _current;

  @override
  Future<void> connect({Duration timeout = const Duration(seconds: 10)}) async {
    _set(TransportStatus.connecting);
    if (realtime) await Future<void>.delayed(const Duration(milliseconds: 450));
    _clock.start();
    _set(TransportStatus.connected);
  }

  @override
  Future<void> disconnect() async {
    _clock.stop();
    _set(TransportStatus.disconnected);
  }

  /// Simulates the BLE link dropping (adapter unplugged).
  void simulateLinkDrop() => _set(TransportStatus.disconnected);

  void _set(TransportStatus s) {
    _current = s;
    if (!_status.isClosed) _status.add(s);
  }

  @override
  Future<void> write(List<int> bytes) async {
    if (_current != TransportStatus.connected) {
      throw const TransportException('not connected');
    }
    for (final b in bytes) {
      if (b == 0x0D) {
        final cmd = _line.toString().replaceAll(' ', '').toUpperCase();
        _line.clear();
        _handle(cmd);
      } else {
        _line.writeCharCode(b);
      }
    }
  }

  void _handle(String cmd) {
    if (faults.adapterSilent) return;
    if (realtime) {
      final now = _clock.elapsed;
      car.advance((now - _lastAdvance).inMicroseconds / 1e6);
      _lastAdvance = now;
    }
    final lines = _respond(cmd);
    final eol = _linefeeds ? '\r\n' : '\r';
    var text = '${_echo ? '$cmd\r' : ''}${lines.join(eol)}$eol$eol>';
    if (faults.garbageRate > 0 && _rng.nextDouble() < faults.garbageRate) {
      text = '\x00${String.fromCharCodes(List.generate(5, (_) => 0x21 + _rng.nextInt(90)))}$eol>';
    }
    final pidCount = cmd.startsWith('01') ? max(1, (cmd.length - 2) ~/ 2) : 1;
    final latency = realtime ? baseLatency + perPidLatency * pidCount + faults.extraLatency : Duration.zero;
    _replyChain = _replyChain.then((_) => _send(text, latency));
  }

  Future<void> _send(String text, Duration latency) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (_current != TransportStatus.connected || _incoming.isClosed) return;
    final bytes = latin1.encode(text);
    for (var i = 0; i < bytes.length; i += chunkSize) {
      _incoming.add(bytes.sublist(i, min(bytes.length, i + chunkSize)));
    }
  }

  List<String> _respond(String cmd) {
    if (cmd.startsWith('AT')) return _at(cmd.substring(2));
    if (!RegExp(r'^[0-9A-F]+$').hasMatch(cmd) || cmd.length.isOdd) return ['?'];
    if (faults.carOff || !car.ignitionOn) {
      return _protocolFound ? ['NO DATA'] : ['SEARCHING...', 'UNABLE TO CONNECT'];
    }
    final searching = !_protocolFound;
    _protocolFound = true;
    final bytes = [for (var i = 0; i < cmd.length; i += 2) int.parse(cmd.substring(i, i + 2), radix: 16)];
    final payload = _obd(bytes);
    final out = payload == null ? ['NO DATA'] : _format(payload);
    return searching ? ['SEARCHING...', ...out] : out;
  }

  List<String> _at(String c) {
    switch (c) {
      case 'Z':
        _echo = true;
        _headers = false;
        _spaces = true;
        _linefeeds = true;
        _protocolFound = false;
        return ['', 'ELM327 v1.5'];
      case 'WS':
        return ['ELM327 v1.5'];
      case 'I':
        return ['ELM327 v1.5'];
      case '@1':
        return ['OBDII to RS232 Interpreter'];
      case 'E0' || 'E1':
        _echo = c == 'E1';
        return ['OK'];
      case 'H0' || 'H1':
        _headers = c == 'H1';
        return ['OK'];
      case 'S0' || 'S1':
        _spaces = c == 'S1';
        return ['OK'];
      case 'L0' || 'L1':
        _linefeeds = c == 'L1';
        return ['OK'];
      case 'DPN':
        return [_protocolFound ? 'A6' : 'A0'];
      case 'DP':
        return ['AUTO, ISO 15765-4 (CAN 11/500)'];
      case 'RV':
        final v = car.ignitionOn ? car.voltage : 12.4;
        return ['${v.toStringAsFixed(1)}V'];
    }
    if (c.startsWith('SP') || c.startsWith('AT') || c.startsWith('ST') || c == 'D') {
      if (c.startsWith('SP')) _protocolFound = false;
      return ['OK'];
    }
    return ['?'];
  }

  int _pct(double v) => (v.clamp(0, 100) * 255 / 100).round();
  List<int> _u16(double v) {
    final n = v.round().clamp(0, 65535);
    return [n >> 8, n & 0xFF];
  }

  List<int>? _pidData(int pid) {
    final c = car;
    return switch (pid) {
      0x01 => [(c.milOn ? 0x80 : 0) | c.stored.length, 0x07, 0x65, 0x00],
      0x04 => [_pct(c.load)],
      0x05 => [(c.coolant + 40).round().clamp(0, 255)],
      0x06 => [(c.stft * 128 / 100 + 128).round().clamp(0, 255)],
      0x07 => [(c.ltft * 128 / 100 + 128).round().clamp(0, 255)],
      0x0B => [c.map.round().clamp(0, 255)],
      0x0C => _u16(c.rpm * 4),
      0x0D => [c.speed.round().clamp(0, 255)],
      0x0E => [((c.timing + 64) * 2).round().clamp(0, 255)],
      0x0F => [(c.iat + 40).round().clamp(0, 255)],
      0x10 => _u16(c.maf * 100),
      0x11 => [_pct(c.throttle)],
      0x14 => [(c.o2 * 200).round().clamp(0, 255), 0x80],
      0x15 => [((0.68 + sin(c.t / 7) * 0.04) * 200).round(), 0xFF],
      0x1F => _u16(c.runTime),
      0x21 => _u16(0),
      0x2F => [_pct(c.fuel)],
      0x30 => [c.warmups],
      0x31 => _u16(c.distanceSinceClear),
      0x33 => [c.baro.round()],
      0x3C => _u16((c.catTemp + 40) * 10),
      0x42 => _u16(c.voltage * 1000),
      0x43 => _u16(c.load * 255 / 100),
      0x44 => _u16((c.load > 85 ? 0.9 : 1.0) * 32768),
      0x46 => [(c.ambient + 40).round()],
      0x49 => [_pct(c.pedal)],
      0x4C => [_pct(c.throttle * 0.95)],
      0x5C => [(c.oil + 40).round().clamp(0, 255)],
      0x5E => _u16(c.fuelRate * 20),
      0xA6 => () {
          final n = (c.odometer * 10).round();
          return [(n >> 24) & 0xFF, (n >> 16) & 0xFF, (n >> 8) & 0xFF, n & 0xFF];
        }(),
      _ => null,
    };
  }

  List<int>? _obd(List<int> req) {
    final mode = req[0];
    switch (mode) {
      case 0x01:
        if (req.length < 2) return null;
        final out = <int>[0x41];
        for (final pid in req.skip(1).take(6)) {
          if (pid % 0x20 == 0) {
            out
              ..add(pid)
              ..addAll(encodeSupportedMask(pid, supportedWithLinks));
            continue;
          }
          if (!_supported.contains(pid)) continue;
          final d = _pidData(pid);
          if (d != null) {
            out
              ..add(pid)
              ..addAll(d);
          }
        }
        return out.length > 1 ? out : null;
      case 0x03:
        return [0x43, car.stored.length, ...car.stored.expand(_encodeDtc)];
      case 0x07:
        return [0x47, car.pending.length, ...car.pending.expand(_encodeDtc)];
      case 0x0A:
        return [0x4A, 0x00];
      case 0x04:
        car.clearCodes();
        return [0x44];
      case 0x09:
        if (req.length < 2) return null;
        if (req[1] == 0x00) return [0x49, 0x00, 0x55, 0x40, 0x00, 0x00];
        if (req[1] == 0x02) return [0x49, 0x02, 0x01, ...ascii.encode(car.vin)];
        return null;
    }
    return null;
  }

  List<int> _encodeDtc(String code) {
    final letter = 'PCBU'.indexOf(code[0]);
    final d1 = int.parse(code[1]);
    final d2 = int.parse(code[2], radix: 16);
    final b = int.parse(code.substring(3), radix: 16);
    return [(letter << 6) | (d1 << 4) | d2, b];
  }

  String _hex(int b) => b.toRadixString(16).padLeft(2, '0').toUpperCase();
  String _join(List<int> bytes) => bytes.map(_hex).join(_spaces ? ' ' : '');

  /// Lays the payload out as the ELM327 would print it on CAN 11-bit.
  List<String> _format(List<int> payload) {
    final sep = _spaces ? ' ' : '';
    if (_headers) {
      List<int> pad(List<int> f) => [...f, ...List.filled(8 - f.length, 0x00)];
      if (payload.length <= 7) {
        return ['7E8$sep${_join(pad([payload.length, ...payload]))}'];
      }
      final lines = <String>[];
      lines.add('7E8$sep${_join([0x10 | (payload.length >> 8), payload.length & 0xFF, ...payload.sublist(0, 6)])}');
      var seq = 1;
      for (var i = 6; i < payload.length; i += 7) {
        final chunk = payload.sublist(i, min(payload.length, i + 7));
        lines.add('7E8$sep${_join(pad([0x20 | (seq & 0x0F), ...chunk]))}');
        seq++;
      }
      return lines;
    }
    if (payload.length <= 7) return [_join(payload)];
    final lines = <String>[payload.length.toRadixString(16).padLeft(3, '0').toUpperCase()];
    lines.add('0:$sep${_join(payload.sublist(0, 6))}');
    var seq = 1;
    for (var i = 6; i < payload.length; i += 7) {
      lines.add('${(seq & 0x0F).toRadixString(16).toUpperCase()}:$sep${_join(payload.sublist(i, min(payload.length, i + 7)))}');
      seq++;
    }
    return lines;
  }
}
