import 'package:obd_core/obd_core.dart';
import 'package:test/test.dart';

/// KWP2000 / ISO 9141 frame with headers on and spaces off: format/priority,
/// target, source, data, checksum.
String _kline(List<int> header, List<int> data) {
  final all = [...header, ...data];
  final sum = all.fold<int>(0, (a, b) => a + b) & 0xFF;
  return [...all, sum].map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join();
}

/// An early VW Golf 5 (2004–2005): generic OBD over the K-line.
String? _golf5(String cmd, {List<int> header = const [0x86, 0xF1, 0x10], String dpn = 'A4'}) => switch (cmd) {
      'ATZ' => 'ELM327 v1.5',
      'ATDPN' => dpn,
      'ATRV' => '12.3V',
      '0100' => 'SEARCHING...\r${_kline(header, [0x41, 0x00, 0xBE, 0x3E, 0xB8, 0x11])}',
      '0120' => _kline(header, [0x41, 0x20, 0x80, 0x00, 0x00, 0x00]),
      '010C' => _kline([0x84, 0xF1, 0x10], [0x41, 0x0C, 0x0C, 0x80]),
      _ when cmd.startsWith('AT') => 'OK',
      _ => 'NO DATA',
    };

void main() {
  for (final (name, header, dpn) in [
    ('KWP2000 slow init', [0x86, 0xF1, 0x10], 'A4'),
    ('KWP2000 fast init', [0x86, 0xF1, 0x10], 'A5'),
    ('ISO 9141-2', [0x48, 0x6B, 0x10], 'A3'),
  ]) {
    test('starts on a K-line car: $name', () async {
      final t = FakeTransport((cmd) => _golf5(cmd, header: header, dpn: dpn));
      await t.connect();
      final a = Elm327Adapter(t, timeoutScale: 0.05);
      final r = await a.initialize();
      expect(r, isA<Ok<AdapterInfo>>(), reason: '$r\n${a.log.export()}');
      final info = (r as Ok<AdapterInfo>).value;
      expect(info.protocol?.isCan, isFalse);
      expect(info.supportedPids, containsAll([0x01, 0x0C, 0x0D, 0x05]));
      final rpm = await a.readSensors([Sensors.rpm]);
      expect((rpm as Ok<List<SensorReading>>).value.single.value, 800);
    });
  }

  test('starts with the reply Mohamed\'s Golf 5 really gave (dots left over from the search)', () async {
    final t = FakeTransport((cmd) => cmd == '0100' ? 'SEARCHING...\r..86F1104100BE3EE811BD' : _golf5(cmd, dpn: 'A4'));
    await t.connect();
    final a = Elm327Adapter(t, timeoutScale: 0.05);
    final r = await a.initialize();
    expect(r, isA<Ok<AdapterInfo>>(), reason: '$r');
    expect((r as Ok<AdapterInfo>).value.supportedPids, containsAll([0x01, 0x04, 0x05, 0x0C, 0x0D]));
  });

  test('reads the VIN from the five K-line messages', () async {
    const vin = 'WVWZZZ1KZ5W123456';
    final chars = [0, 0, 0, ...vin.codeUnits];
    final reply = [
      for (var i = 0; i < 5; i++) _kline([0x87, 0xF1, 0x10], [0x49, 0x02, i + 1, ...chars.sublist(i * 4, i * 4 + 4)]),
    ].join('\r');
    final t = FakeTransport((cmd) => cmd == '0902' ? reply : _golf5(cmd));
    await t.connect();
    final a = Elm327Adapter(t, timeoutScale: 0.05);
    await a.initialize();
    expect((await a.readVin()).valueOrNull, vin);
  });
}
