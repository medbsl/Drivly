import '../adapter/adapter_log.dart';
import '../adapter/diagnostic_adapter.dart';
import '../adapter/obd_result.dart';
import '../dtc/dtc.dart';
import '../pids/sensor.dart';
import '../pids/sensors.dart';
import '../pids/supported_pids.dart';
import '../protocol/frame_parser.dart';
import '../protocol/obd_protocol.dart';
import '../transport/obd_transport.dart';
import '../vin/vin.dart';
import 'elm_error.dart';
import 'elm_session.dart';

String _hex2(int v) => v.toRadixString(16).padLeft(2, '0').toUpperCase();

/// [DiagnosticAdapter] over the ELM327 command set.
class Elm327Adapter implements DiagnosticAdapter {
  Elm327Adapter(ObdTransport transport, {AdapterLog? log, DateTime Function()? clock, this.timeoutScale = 1.0})
      : _session = ElmSession(transport, log: log, timeoutScale: timeoutScale),
        _clock = clock ?? DateTime.now;

  /// Multiplies every timeout. Tests use a small value to run failure paths fast.
  final double timeoutScale;

  Duration _t(int ms) => Duration(microseconds: (ms * 1000 * timeoutScale).round());

  final ElmSession _session;
  final DateTime Function() _clock;
  AdapterInfo? _info;
  ObdProtocol? _protocol;
  bool _multiPid = false;

  /// Maximum PIDs per multi-PID request (ELM327 / ISO 15765 limit).
  static const maxPidsPerRequest = 6;

  @override
  AdapterLog get log => _session.log;

  @override
  AdapterInfo? get info => _info;

  @override
  int get consecutiveTimeouts => _session.consecutiveTimeouts;

  @override
  Future<ObdResult<AdapterInfo>> initialize({void Function(InitStage stage)? onStage}) async {
    _session.start();
    onStage?.call(InitStage.adapter);

    // 1. Reset, with warm-start and defaults as fallbacks for picky clones.
    var reset = await _session.send('ATZ', timeout: _t(2500));
    if (reset.timedOut) reset = await _session.send('ATWS', timeout: _t(2500));
    if (reset.timedOut) reset = await _session.send('ATD', timeout: _t(1500));
    final version = reset.lines.firstWhere(
      (l) => l.contains('ELM') || l.contains('V1') || l.contains('V2'),
      orElse: () => 'ELM327',
    );

    // 2. Configure. Failures are tolerated; the parser copes with defaults.
    var answered = !reset.timedOut;
    for (final cmd in const ['ATE0', 'ATL0', 'ATS0', 'ATH1', 'ATAT1', 'ATSP0']) {
      final r = await _session.send(cmd, timeout: _t(1 * 1000));
      if (!r.timedOut) answered = true;
    }
    if (!answered) {
      return const InitFailed(InitFailure.adapterNotResponding, 'no reply to ATZ / ATE0');
    }

    // 3. First OBD request triggers the protocol search.
    onStage?.call(InitStage.car);
    final first = await _session.send('0100', timeout: _t(15 * 1000));
    if (first.timedOut || (first.error != null)) {
      return InitFailed(
        InitFailure.carNotResponding,
        first.timedOut ? 'timeout on 0100' : first.lines.join(' '),
      );
    }

    onStage?.call(InitStage.discovery);
    final dpn = await _session.send('ATDPN', timeout: _t(1 * 1000));
    _protocol = dpn.lines.isEmpty ? null : ObdProtocol.fromDpn(dpn.lines.last);

    final supported = <int>{..._masks(parseReply(first.lines, protocol: _protocol), 0x00)};
    if (supported.isEmpty) {
      return InitFailed(InitFailure.carNotResponding, 'no supported PIDs in ${first.lines.join(' ')}');
    }

    // 4. Remaining bitmasks: ask base+0x20 while the previous LSB is set.
    for (var base = 0x20; base <= 0xC0 && supported.contains(base); base += 0x20) {
      final r = await _session.send('01${_hex2(base)}', timeout: _t(3 * 1000));
      if (!r.ok) break;
      supported.addAll(_masks(parseReply(r.lines, protocol: _protocol), base));
    }

    final battery = (await readBatteryVoltage()).valueOrNull;

    // 5. Multi-PID probe (CAN only): one request, several PIDs.
    _multiPid = false;
    if (_protocol?.isCan ?? false) {
      final probe = [0x0C, 0x0D, 0x05, 0x04, 0x11].where(supported.contains).take(2).toList();
      if (probe.length == 2) {
        final r = await _session.send('01${probe.map(_hex2).join()}', timeout: _t(2 * 1000));
        if (r.ok) {
          final got = _decodeMode01(parseReply(r.lines, protocol: _protocol), probe.toSet());
          _multiPid = got.length == 2;
        }
      }
    }
    log.add(LogDirection.info,
        'init ok · ${_protocol?.technicalName ?? 'unknown protocol'} · ${supported.length} PIDs · multi-PID ${_multiPid ? 'on' : 'off'}');

    final info = AdapterInfo(
      elmVersion: version,
      protocol: _protocol,
      supportedPids: Set.unmodifiable(supported),
      multiPid: _multiPid,
      batteryVoltage: battery,
    );
    _info = info;
    return Ok(info);
  }

  Set<int> _masks(List<EcuMessage> msgs, int base) {
    final out = <int>{};
    for (final m in msgs) {
      final p = m.payload;
      if (p.length >= 6 && p[0] == 0x41 && p[1] == base) {
        out.addAll(decodeSupportedMask(base, p.sublist(2, 6)));
      }
    }
    return out;
  }

  /// Sends with one retry for transient bus errors and a re-init after an
  /// adapter reset (voltage dip).
  Future<ElmResponse> _send(String cmd, Duration timeout) async {
    var r = await _session.send(cmd, timeout: timeout);
    final e = r.error;
    if (e == ElmError.adapterReset) {
      log.add(LogDirection.info, 'adapter reset detected, re-initialising');
      for (final c in const ['ATE0', 'ATL0', 'ATS0', 'ATH1', 'ATAT1']) {
        await _session.send(c, timeout: _t(1 * 1000));
      }
      r = await _session.send(cmd, timeout: timeout);
    } else if (e != null && e.isTransient) {
      r = await _session.send(cmd, timeout: timeout);
    }
    return r;
  }

  ObdResult<T> _failure<T>(ElmResponse r) {
    if (r.timedOut) return TimedOut<T>();
    final e = r.error;
    if (e == null) return Malformed<T>(r.lines.join(' '));
    if (e == ElmError.noData) return NoData<T>();
    if (e == ElmError.unknownCommand) return NotSupported<T>();
    if (e.meansCarSilent) return CarNotResponding<T>();
    return AdapterError<T>(e, r.lines.join(' '));
  }

  @override
  Future<ObdResult<List<SensorReading>>> readSensors(List<Sensor> sensors) async {
    final pids = sensors.where((s) => s.isPid).toList();
    if (pids.isEmpty) return const Ok([]);
    final batches = <List<Sensor>>[];
    if (_multiPid) {
      for (var i = 0; i < pids.length; i += maxPidsPerRequest) {
        batches.add(pids.sublist(i, i + maxPidsPerRequest > pids.length ? pids.length : i + maxPidsPerRequest));
      }
    } else {
      batches.addAll(pids.map((s) => [s]));
    }

    final out = <SensorReading>[];
    ObdResult<List<SensorReading>>? firstFailure;
    for (final batch in batches) {
      final cmd = '01${batch.map((s) => _hex2(s.pid!)).join()}';
      final r = await _send(cmd, _t(batch.length > 1 ? 1500 : 1000));
      if (!r.ok) {
        firstFailure ??= _failure(r);
        if (r.timedOut) break; // don't pile up timeouts on a dead link
        continue;
      }
      out.addAll(_decodeMode01(parseReply(r.lines, protocol: _protocol), batch.map((s) => s.pid!).toSet()));
    }
    if (out.isEmpty && firstFailure != null) return firstFailure;
    return Ok(out);
  }

  List<SensorReading> _decodeMode01(List<EcuMessage> msgs, Set<int> requested) {
    final at = _clock();
    final seen = <int>{};
    final out = <SensorReading>[];
    // Engine ECU (7E8 / 18DAF110) first when several ECUs answer.
    final ordered = [...msgs]..sort((a, b) => _ecuRank(a.ecu).compareTo(_ecuRank(b.ecu)));
    for (final m in ordered) {
      final p = m.payload;
      if (p.isEmpty || p[0] != 0x41) continue; // stale or foreign reply
      var i = 1;
      while (i < p.length) {
        final pid = p[i];
        final len = Sensors.dataLength(pid);
        if (len == null || i + 1 + len > p.length) break;
        if (requested.contains(pid) && !seen.contains(pid)) {
          final sensor = Sensors.byPid[pid];
          final v = sensor?.decodeChecked(p.sublist(i + 1, i + 1 + len));
          if (sensor != null && v != null) {
            out.add(SensorReading(sensor, v, at));
            seen.add(pid);
          } else if (sensor != null) {
            log.add(LogDirection.info, 'out-of-range value for ${sensor.key}: ${hex(p.sublist(i + 1, i + 1 + len))}');
          }
        }
        i += 1 + len;
      }
    }
    return out;
  }

  int _ecuRank(String? ecu) {
    if (ecu == null) return 1;
    if (ecu == '7E8' || ecu.endsWith('10') && ecu.startsWith('18DAF1')) return 0;
    return 2;
  }

  @override
  Future<ObdResult<MonitorStatus>> readMonitorStatus() async {
    final r = await _send('0101', _t(1500));
    if (!r.ok) return _failure(r);
    var mil = false;
    var count = 0;
    List<int>? raw;
    for (final m in parseReply(r.lines, protocol: _protocol)) {
      final p = m.payload;
      if (p.length >= 6 && p[0] == 0x41 && p[1] == 0x01) {
        final s = MonitorStatus.fromBytes(p.sublist(2, 6));
        mil = mil || s.milOn;
        count += s.dtcCount;
        raw ??= s.raw;
      }
    }
    if (raw == null) return Malformed(r.lines.join(' '));
    return Ok(MonitorStatus(milOn: mil, dtcCount: count, raw: raw));
  }

  @override
  Future<ObdResult<List<Dtc>>> readDtcs(DtcKind kind) async {
    final r = await _send(_hex2(kind.mode), _t(4 * 1000));
    if (r.error == ElmError.noData) return const Ok([]);
    if (!r.ok) return _failure(r);
    final isCan = _protocol?.isCan ?? false;
    final out = <Dtc>[];
    final seen = <String>{};
    for (final m in parseReply(r.lines, protocol: _protocol)) {
      if (m.payload.isEmpty || m.payload[0] != 0x40 + kind.mode) continue;
      for (final code in parseDtcPayload(m.payload, isCan: isCan)) {
        if (seen.add(code)) out.add(Dtc(code, kind, ecu: m.ecu));
      }
    }
    return Ok(out);
  }

  @override
  Future<ObdResult<void>> clearDtcs() async {
    final r = await _send('04', _t(5 * 1000));
    if (!r.ok) return _failure(r);
    final acked = parseReply(r.lines, protocol: _protocol).any((m) => m.payload.isNotEmpty && m.payload[0] == 0x44);
    return acked ? const Ok(null) : Malformed(r.lines.join(' '));
  }

  @override
  Future<ObdResult<String>> readVin() async {
    final r = await _send('0902', _t(5 * 1000));
    if (r.error == ElmError.noData || r.error == ElmError.unknownCommand) return const NotSupported();
    if (!r.ok) return _failure(r);
    final vin = parseVinMessages(parseReply(r.lines, protocol: _protocol).map((m) => m.payload).toList());
    return vin == null ? Malformed(r.lines.join(' ')) : Ok(vin);
  }

  @override
  Future<ObdResult<double>> readBatteryVoltage() async {
    final r = await _send('ATRV', _t(1 * 1000));
    if (r.timedOut) return const TimedOut();
    final m = RegExp(r'(\d{1,2}(?:\.\d{1,2})?)\s*V?').firstMatch(r.lines.join(' '));
    final v = m == null ? null : double.tryParse(m.group(1)!);
    if (v != null && v > 0 && v <= 20) return Ok(v);
    // Fallback: control module voltage (PID 42).
    if (_info?.supportedPids.contains(0x42) ?? false) {
      final res = await readSensors(const [Sensors.moduleVoltage]);
      final reading = res.valueOrNull;
      if (reading != null && reading.isNotEmpty) return Ok(reading.first.value);
    }
    return const NotSupported();
  }

  @override
  Future<void> close() => _session.close();
}
