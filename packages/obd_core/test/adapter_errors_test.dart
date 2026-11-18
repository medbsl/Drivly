import 'package:obd_core/obd_core.dart';
import 'package:test/test.dart';

/// A scripted adapter. [replies] maps a command to the replies it gives on
/// successive calls (the last one repeats); null means silence.
Future<(Elm327Adapter, FakeTransport)> _scripted(Map<String, List<String?>> replies, {String? Function(String)? fallback}) async {
  final calls = <String, int>{};
  final t = FakeTransport((cmd) {
    final list = replies[cmd];
    if (list == null) return fallback != null ? fallback(cmd) : (cmd.startsWith('AT') ? 'OK' : 'NO DATA');
    final i = calls.update(cmd, (n) => n + 1, ifAbsent: () => 0);
    return list[i < list.length ? i : list.length - 1];
  });
  await t.connect();
  return (Elm327Adapter(t, timeoutScale: 0.02), t);
}

/// A CAN 11/500 car with headers on. Supports 0C 0D 05 and 42.
String? _canCar(String cmd) => switch (cmd) {
      'ATZ' => 'ELM327 v1.5',
      'ATDPN' => 'A6',
      '0100' => '7E8 06 41 00 08 18 00 01',
      '0120' => '7E8 06 41 20 00 00 00 01',
      '0140' => '7E8 06 41 40 40 00 00 00',
      _ when cmd.startsWith('AT') => 'OK',
      _ => 'NO DATA',
    };

void main() {
  group('retries', () {
    test('a transient bus error gets exactly one retry', () async {
      final (a, t) = await _scripted({
        '010C': ['BUS BUSY', '41 0C 0F A0'],
      });
      final r = await a.readSensors([Sensors.rpm]);
      expect((r as Ok<List<SensorReading>>).value.single.value, 1000);
      expect(t.written.where((c) => c == '010C'), hasLength(2));
    });

    test('a second transient error is reported, not retried forever', () async {
      final (a, t) = await _scripted({
        '010C': ['BUS BUSY'],
      });
      final r = await a.readSensors([Sensors.rpm]);
      expect(r, isA<AdapterError<List<SensorReading>>>());
      expect((r as AdapterError).kind, ElmError.busBusy);
      expect(t.written.where((c) => c == '010C'), hasLength(2));
    });

    test('an adapter reset (voltage dip) re-applies the settings, then repeats the request', () async {
      final (a, t) = await _scripted({
        '010C': ['LV RESET\rELM327 v1.5', '41 0C 0F A0'],
      });
      final r = await a.readSensors([Sensors.rpm]);
      expect((r as Ok<List<SensorReading>>).value.single.value, 1000);
      expect(t.written, ['010C', 'ATE0', 'ATL0', 'ATS0', 'ATH1', 'ATAT1', '010C']);
      expect(t.written.every(isReadOnlyCommand), isTrue, reason: 'recovery only sends reads and setup');
    });
  });

  group('error replies become results', () {
    Future<ObdResult<List<SensorReading>>> rpmWith(String? reply) async {
      final (a, _) = await _scripted({
        '010C': [reply],
      });
      return a.readSensors([Sensors.rpm]);
    }

    test('NO DATA → NoData', () async => expect(await rpmWith('NO DATA'), isA<NoData<List<SensorReading>>>()));
    test('? → NotSupported', () async => expect(await rpmWith('?'), isA<NotSupported<List<SensorReading>>>()));
    test('UNABLE TO CONNECT → CarNotResponding',
        () async => expect(await rpmWith('UNABLE TO CONNECT'), isA<CarNotResponding<List<SensorReading>>>()));
    test('CAN ERROR → CarNotResponding', () async => expect(await rpmWith('CAN ERROR'), isA<CarNotResponding<List<SensorReading>>>()));
    test('BUS INIT: ...ERROR → CarNotResponding',
        () async => expect(await rpmWith('BUS INIT: ...ERROR'), isA<CarNotResponding<List<SensorReading>>>()));
    test('silence → TimedOut', () async => expect(await rpmWith(null), isA<TimedOut<List<SensorReading>>>()));

    test('a timeout stops the batch instead of piling up more timeouts', () async {
      final (a, t) = await _scripted({
        '010C': [null],
      });
      await a.readSensors([Sensors.rpm, Sensors.speed, Sensors.coolant]);
      // '' is the bare CR that interrupts the hung request.
      expect(t.written.where((c) => c.isNotEmpty), ['010C'], reason: 'speed and coolant are not asked');
    });

    test('one unanswered PID does not hide the others', () async {
      final (a, _) = await _scripted({
        '010C': ['NO DATA'],
        '010D': ['41 0D 32'],
      });
      final r = await a.readSensors([Sensors.rpm, Sensors.speed]);
      expect((r as Ok<List<SensorReading>>).value.map((e) => (e.sensor, e.value)), [(Sensors.speed, 50.0)]);
    });

    test('no codes stored is an empty list, not an error', () async {
      final (a, _) = await _scripted({
        '03': ['NO DATA'],
      });
      expect((await a.readDtcs(DtcKind.stored)).valueOrNull, isEmpty);
    });

    test('a car that does not share its VIN → NotSupported', () async {
      for (final reply in ['NO DATA', '?']) {
        final (a, _) = await _scripted({
          '0902': [reply],
        });
        expect(await a.readVin(), isA<NotSupported<String>>(), reason: reply);
      }
    });
  });

  group('battery voltage', () {
    test('read from the adapter (ATRV)', () async {
      final (a, _) = await _scripted({
        'ATRV': ['12.6V'],
      });
      expect((await a.readBatteryVoltage()).valueOrNull, 12.6);
    });

    test('an implausible ATRV falls back to the car\'s module voltage (PID 42)', () async {
      final (a, t) = await _scripted({
        'ATRV': ['25.0V'],
        '0142': ['7E8 04 41 42 37 6E'],
      }, fallback: _canCar);
      await a.initialize();
      final v = (await a.readBatteryVoltage()).valueOrNull;
      expect(v, closeTo(14.19, 0.01));
      expect(t.written, contains('0142'));
    });

    test('no ATRV and no PID 42 → NotSupported', () async {
      final (a, _) = await _scripted({
        'ATRV': ['?'],
      });
      expect(await a.readBatteryVoltage(), isA<NotSupported<double>>());
    });
  });

  test('when several ECUs answer, the engine ECU (7E8) wins', () async {
    final (a, _) = await _scripted({
      '010C': ['7E9 04 41 0C 00 00\r7E8 04 41 0C 0F A0'],
    }, fallback: _canCar);
    await a.initialize();
    final r = await a.readSensors([Sensors.rpm]);
    expect((r as Ok<List<SensorReading>>).value.single.value, 1000);
  });

  test('more than six PIDs are split into several requests', () async {
    final sim = Elm327Simulator(realtime: false);
    await sim.connect();
    final a = Elm327Adapter(sim, timeoutScale: 0.05);
    final info = (await a.initialize() as Ok<AdapterInfo>).value;
    expect(info.multiPid, isTrue);
    final sensors = Sensors.all.where((s) => s.isPid && info.supportedPids.contains(s.pid)).take(8).toList();
    expect(sensors, hasLength(8));
    a.log.clear();
    final r = await a.readSensors(sensors);
    expect((r as Ok<List<SensorReading>>).value, hasLength(sensors.length));
    final requests = a.log.entries.where((e) => e.direction == LogDirection.tx).map((e) => e.text).toList();
    expect(requests, hasLength((sensors.length / 6).ceil()));
    expect(requests.first.length, 2 + 6 * 2);
  });

  test('ElmError groups', () {
    expect(ElmError.values.where((e) => e.meansCarSilent), {ElmError.unableToConnect, ElmError.busInitError, ElmError.canError});
    expect(ElmError.values.where((e) => e.isTransient), {
      ElmError.stopped,
      ElmError.busBusy,
      ElmError.feedbackError,
      ElmError.dataError,
      ElmError.rxError,
      ElmError.bufferFull,
    });
    expect(ElmError.noData.isTransient || ElmError.noData.meansCarSilent, isFalse);
  });
}
