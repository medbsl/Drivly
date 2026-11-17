import 'package:obd_core/obd_core.dart';
import 'package:test/test.dart';

/// Drivly only ever reads from the car (docs/adr/0002-read-only.md).
void main() {
  group('isReadOnlyCommand', () {
    test('allows the OBD-II read modes', () {
      for (final c in [
        '0100', '010C', '0120', '010C0D05041142', // 01 live data, up to 6 PIDs
        '020C00', // 02 freeze frame
        '03', '07', '0A', // stored, pending, permanent codes
        '0601', // 06 test results
        '0900', '0902', // 09 vehicle info (VIN)
      ]) {
        expect(isReadOnlyCommand(c), isTrue, reason: c);
      }
    });

    test('allows the adapter setup and read AT commands Drivly uses', () {
      for (final c in ['ATZ', 'ATWS', 'ATD', 'ATE0', 'ATL0', 'ATS0', 'ATH1', 'ATAT1', 'ATSP0', 'ATDPN', 'ATRV']) {
        expect(isReadOnlyCommand(c), isTrue, reason: c);
      }
    });

    test('ignores case and spaces', () {
      expect(isReadOnlyCommand('at z'), isTrue);
      expect(isReadOnlyCommand('01 0c'), isTrue);
      expect(isReadOnlyCommand(' 0 4 '), isFalse);
    });

    test('refuses everything that could change the car', () {
      for (final c in [
        '04', '0400', // clear trouble codes
        '08', '0801', // control on-board systems
        '1001', '1003', // UDS session control
        '1101', // ECU reset
        '14FFFFFF', // UDS clear codes
        '2701', // security access
        '2EF19031', // write data by identifier
        '2F0101', // input/output control
        '3101FF00', // routine control
        '3E00', // tester present
        '3400', '36', '37', // download / transfer
        '85', // control DTC setting
      ]) {
        expect(isReadOnlyCommand(c), isFalse, reason: c);
      }
    });

    test('refuses AT commands that are not on the list', () {
      for (final c in [
        'ATPP0CSV23', 'ATPP0CON', // write the adapter's permanent memory
        'ATSH7E0', 'ATFCSH7E0', 'ATCRA7E8', // address one ECU directly
        'ATMA', 'ATBRD23', 'ATSP6', 'ATTP6', 'STP33',
      ]) {
        expect(isReadOnlyCommand(c), isFalse, reason: c);
      }
    });

    test('refuses empty, malformed and over-long commands', () {
      for (final c in ['', ' ', '0', '010', '01G0', '0300', '0902AB', '01010203040506070809']) {
        expect(isReadOnlyCommand(c), isFalse, reason: c);
      }
    });
  });

  group('ElmSession', () {
    test('a refused command throws and never reaches the adapter', () async {
      final transport = FakeTransport((_) => '44');
      await transport.connect();
      final session = ElmSession(transport);

      expect(() => session.send('04'), throwsA(isA<ReadOnlyViolation>()));
      await Future<void>.delayed(Duration.zero);

      expect(transport.written, isEmpty);
      expect(session.log.entries.map((e) => e.text), contains(contains('blocked')));
    });

    test('read commands still go through', () async {
      final transport = FakeTransport((c) => c == '0100' ? '41 00 BE 3E B8 13' : 'OK');
      await transport.connect();
      final session = ElmSession(transport);

      final r = await session.send('0100');

      expect(r.ok, isTrue);
      expect(transport.written, ['0100']);
    });
  });

  test('every command in a full session is a read', () async {
    final sim = Elm327Simulator(realtime: false);
    await sim.connect();
    final log = AdapterLog(capacity: 10000);
    final adapter = Elm327Adapter(sim, log: log, timeoutScale: 0.05);

    await adapter.initialize();
    await adapter.readSensors(Sensors.all);
    await adapter.readMonitorStatus();
    for (final kind in DtcKind.values) {
      await adapter.readDtcs(kind);
    }
    await adapter.readVin();
    await adapter.readBatteryVoltage();

    final sent = [for (final e in log.entries) if (e.direction == LogDirection.tx) e.text];
    expect(sent, isNotEmpty);
    expect(sent.where((c) => !isReadOnlyCommand(c)), isEmpty);
  });
}
