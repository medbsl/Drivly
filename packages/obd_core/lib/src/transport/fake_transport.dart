import 'dart:async';
import 'dart:convert';

import 'obd_transport.dart';

/// Scripted transport for tests. [respond] receives each command (without the
/// trailing `\r`) and returns the raw reply text WITHOUT the final `>` prompt,
/// or `null` to stay silent (simulates a hung adapter).
class FakeTransport implements ObdTransport {
  FakeTransport(this.respond, {this.chunkSize, this.delay = Duration.zero});

  final String? Function(String command) respond;

  /// When set, replies are split into chunks of this many bytes.
  final int? chunkSize;
  final Duration delay;

  final List<String> written = [];
  final _incoming = StreamController<List<int>>.broadcast();
  final _status = StreamController<TransportStatus>.broadcast();
  TransportStatus _current = TransportStatus.disconnected;
  final StringBuffer _line = StringBuffer();

  @override
  TransportKind get kind => TransportKind.simulated;

  @override
  String get name => 'Fake';

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Stream<TransportStatus> get status => _status.stream;

  @override
  TransportStatus get currentStatus => _current;

  @override
  Future<void> connect({Duration timeout = const Duration(seconds: 10)}) async {
    _set(TransportStatus.connected);
  }

  @override
  Future<void> disconnect() async => _set(TransportStatus.disconnected);

  /// Pushes unsolicited bytes (garbage, late replies) to the reader.
  void inject(String text) => _incoming.add(latin1.encode(text));

  @override
  Future<void> write(List<int> bytes) async {
    for (final b in bytes) {
      if (b == 0x0D) {
        final cmd = _line.toString();
        _line.clear();
        written.add(cmd);
        final reply = respond(cmd);
        if (reply != null) {
          unawaited(_emit('$reply\r\r>'));
        }
      } else {
        _line.writeCharCode(b);
      }
    }
  }

  Future<void> _emit(String text) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final bytes = latin1.encode(text);
    final size = chunkSize;
    if (size == null) {
      _incoming.add(bytes);
      return;
    }
    for (var i = 0; i < bytes.length; i += size) {
      _incoming.add(bytes.sublist(i, i + size > bytes.length ? bytes.length : i + size));
      await Future<void>.delayed(Duration.zero);
    }
  }

  void _set(TransportStatus s) {
    _current = s;
    _status.add(s);
  }
}
