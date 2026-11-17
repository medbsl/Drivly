import 'dart:async';

import 'package:obd_core/obd_core.dart';
import 'package:test/test.dart';

Future<(Elm327Adapter, Elm327Simulator)> _connected({SimulatedCar? car}) async {
  final sim = Elm327Simulator(realtime: false, car: car);
  await sim.connect();
  final adapter = Elm327Adapter(sim, timeoutScale: 0.05);
  return (adapter, sim);
}

void main() {
  group('Elm327Adapter against the simulator', () {
    test('initialises: protocol, all bitmasks, multi-PID, battery', () async {
      final (adapter, _) = await _connected();
      final stages = <InitStage>[];
      final r = await adapter.initialize(onStage: stages.add);
      final info = (r as Ok<AdapterInfo>).value;
      expect(info.protocol, ObdProtocol.can11x500);
      expect(info.supportedPids, containsAll([0x0C, 0x0D, 0x05, 0x5E, 0xA6]));
      expect(info.multiPid, isTrue);
      expect(info.batteryVoltage, closeTo(14.1, 0.3));
      expect(info.elmVersion, contains('ELM327'));
      expect(stages, [InitStage.adapter, InitStage.car, InitStage.discovery]);
    });

    test('reads six PIDs in one request', () async {
      final (adapter, sim) = await _connected();
      await adapter.initialize();
      sim.car.advance(30); // get moving
      final sensors = [Sensors.rpm, Sensors.speed, Sensors.load, Sensors.coolant, Sensors.maf, Sensors.odometer];
      final r = await adapter.readSensors(sensors);
      final readings = (r as Ok<List<SensorReading>>).value;
      expect(readings.map((e) => e.sensor).toSet(), sensors.toSet());
      final rpm = readings.firstWhere((e) => e.sensor == Sensors.rpm).value;
      expect(rpm, closeTo(sim.car.rpm, 1));
      expect(adapter.log.entries.where((e) => e.direction == LogDirection.tx && e.text == '010C0D040510A6'), hasLength(1));
    });

    test('unsupported PIDs are simply absent', () async {
      final (adapter, _) = await _connected();
      await adapter.initialize();
      final r = await adapter.readSensors([Sensors.rpm, Sensors.ethanol]);
      final readings = (r as Ok<List<SensorReading>>).value;
      expect(readings.map((e) => e.sensor), [Sensors.rpm]);
    });

    test('reads stored and pending codes', () async {
      final (adapter, _) = await _connected();
      await adapter.initialize();
      final stored = (await adapter.readDtcs(DtcKind.stored)).valueOrNull!;
      final pending = (await adapter.readDtcs(DtcKind.pending)).valueOrNull!;
      expect(stored.map((d) => d.code), ['P0133']);
      expect(pending.map((d) => d.code), ['P0442']);
      expect(stored.single.ecu, '7E8');
    });

    test('reads the VIN (multi-frame)', () async {
      final (adapter, _) = await _connected();
      await adapter.initialize();
      expect((await adapter.readVin()).valueOrNull, 'WVWZZZAUZGW123456');
    });

    test('monitor status', () async {
      final (adapter, sim) = await _connected();
      sim.car.milOn = true;
      await adapter.initialize();
      final s = (await adapter.readMonitorStatus()).valueOrNull!;
      expect(s.milOn, isTrue);
      expect(s.dtcCount, 1);
    });

    test('car off → InitFailed(carNotResponding)', () async {
      final (adapter, sim) = await _connected();
      sim.faults.carOff = true;
      final r = await adapter.initialize();
      expect(r, isA<InitFailed<AdapterInfo>>());
      expect((r as InitFailed).reason, InitFailure.carNotResponding);
    });

    test('silent adapter → InitFailed(adapterNotResponding)', () async {
      final (adapter, sim) = await _connected();
      sim.faults.adapterSilent = true;
      final r = await adapter.initialize();
      expect((r as InitFailed).reason, InitFailure.adapterNotResponding);
    });
  });

  group('Elm327Adapter against odd clones (FakeTransport)', () {
    String? clone(String cmd) => switch (cmd) {
          'ATZ' => 'ATZ\r\rELM327 v2.1',
          'ATH1' => '?', // ignores headers
          'ATS0' => '?', // ignores spaces off
          'ATDPN' => 'A6',
          '0100' => 'SEARCHING...\r41 00 BE 3E B8 11',
          '0120' => '41 20 80 02 80 01',
          '0140' => '41 40 44 00 00 00',
          '010C0D' => '?', // no multi-PID support
          '010C' => '41 0C 0F A0',
          'ATRV' => '12.3V',
          _ when cmd.startsWith('AT') => 'OK',
          _ => 'NO DATA',
        };

    test('copes with echo, spaces, no headers and no multi-PID', () async {
      final t = FakeTransport(clone, chunkSize: 3);
      await t.connect();
      final adapter = Elm327Adapter(t, timeoutScale: 0.05);
      final info = (await adapter.initialize() as Ok<AdapterInfo>).value;
      expect(info.multiPid, isFalse);
      expect(info.supportedPids, containsAll([0x0C, 0x0D, 0x21, 0x2F, 0x31, 0x42, 0x46]));
      final r = await adapter.readSensors([Sensors.rpm]);
      expect((r as Ok<List<SensorReading>>).value.single.value, 1000);
    });

    test('a stale late reply is not taken for the next answer', () async {
      var calls = 0;
      late FakeTransport t;
      t = FakeTransport((cmd) {
        if (cmd == '010D') {
          calls++;
          if (calls == 1) {
            // First request hangs, then the late reply lands during the flush.
            Timer(const Duration(milliseconds: 60), () => t.inject('41 0D 63\r\r>'));
            return null;
          }
          return '41 0D 32';
        }
        if (cmd == '010C') return '41 0C 0F A0';
        return 'OK';
      });
      await t.connect();
      final adapter = Elm327Adapter(t, timeoutScale: 0.03); // 30 ms timeout, 18 ms flush
      final first = await adapter.readSensors([Sensors.speed]);
      expect(first, isA<TimedOut<List<SensorReading>>>());
      await Future<void>.delayed(const Duration(milliseconds: 80)); // late reply arrives
      final rpm = await adapter.readSensors([Sensors.rpm]);
      expect((rpm as Ok<List<SensorReading>>).value.single.sensor, Sensors.rpm);
      final speed = await adapter.readSensors([Sensors.speed]);
      expect((speed as Ok<List<SensorReading>>).value.single.value, 50);
    });

    test('garbage never throws', () async {
      final t = FakeTransport((cmd) => cmd.startsWith('01') ? '\x00#\$%&7E8 ZZ' : 'OK');
      await t.connect();
      final adapter = Elm327Adapter(t, timeoutScale: 0.05);
      final r = await adapter.readSensors([Sensors.rpm, Sensors.speed]);
      expect(r.isOk, isFalse);
    });
  });
}
