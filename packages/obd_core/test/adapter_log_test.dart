import 'package:obd_core/obd_core.dart';
import 'package:test/test.dart';

void main() {
  Future<(ElmSession, AdapterLog)> session(String? Function(String) reply, {bool verbose = false}) async {
    final t = FakeTransport(reply);
    await t.connect();
    final log = AdapterLog()..verbose = verbose;
    return (ElmSession(t, log: log, timeoutScale: 0.05), log);
  }

  Iterable<String> texts(AdapterLog log) => log.entries.map((e) => e.text);

  test('verbose off: no raw entries', () async {
    final (s, log) = await session((_) => 'SEARCHING...\r41 00 BE 3E B8 11');
    await s.send('0100');
    expect(texts(log).where((t) => t.startsWith('raw:')), isEmpty);
    expect(texts(log), contains('41 00 BE 3E B8 11'), reason: 'the parsed reply is still logged');
  });

  test('verbose on: the raw reply is logged, control characters visible', () async {
    final (s, log) = await session((_) => 'SEARCHING...\r41 00 BE 3E B8 11', verbose: true);
    await s.send('0100');
    expect(texts(log), contains(r'raw: SEARCHING...\r41 00 BE 3E B8 11\r\r'));
  });

  test('partial reply on timeout: the bytes that came are logged', () async {
    late final FakeTransport t;
    t = FakeTransport((_) {
      Future(() => t.inject('41 00 BE'));
      return null; // never finishes with the ">" prompt
    });
    await t.connect();
    final log = AdapterLog()..verbose = true;
    final s = ElmSession(t, log: log, timeoutScale: 0.05);
    final r = await s.send('0100');
    expect(r.timedOut, isTrue);
    expect(texts(log), contains('partial: 41 00 BE'));
  });

  test('showControlChars', () {
    expect(showControlChars('A\rB\nC'), r'A\rB\nC');
    expect(showControlChars('\x00\x1b'), r'\x00\x1B');
    expect(showControlChars('41 0C'), '41 0C');
  });
}
