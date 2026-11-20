import 'dart:async';

import 'package:obd_core/obd_core.dart' show maskVins;

/// Where the debug log is kept: a file on the phone, memory on the web.
abstract class DebugLogStore {
  Future<void> append(String text);
  Future<String> readAll();
  Future<int> size();
}

class MemoryDebugLogStore implements DebugLogStore {
  final _text = StringBuffer();

  @override
  Future<void> append(String text) async => _text.write(text);

  @override
  Future<String> readAll() async => _text.toString();

  @override
  Future<int> size() async => _text.length;
}

String _two(int v) => v.toString().padLeft(2, '0');

/// Everything about a connection, for bug reports. Off until [enabled] is
/// set (Settings › Debug logging). Lines are buffered and written about every
/// [flushEvery]; errors are written at once. Never throws into the app.
class DebugLog {
  DebugLog(this._store, {this.flushEvery = const Duration(seconds: 1), DateTime Function()? clock, bool hasContent = false})
      : _clock = clock ?? DateTime.now,
        _hasContent = hasContent;

  /// Opens a log over [store], noting whether it already holds lines from an
  /// earlier run.
  static Future<DebugLog> open(DebugLogStore store) async {
    var size = 0;
    try {
      size = await store.size();
    } catch (_) {}
    return DebugLog(store, hasContent: size > 0);
  }

  final DebugLogStore _store;
  final Duration flushEvery;
  final DateTime Function() _clock;

  bool enabled = false;

  bool _hasContent;

  /// Whether there is anything to share (from this run or an earlier one).
  bool get hasContent => _hasContent;

  final _buffer = StringBuffer();
  Timer? _timer;
  Future<void> _writing = Future<void>.value();

  /// `HH:mm:ss.SSS [source] message`, VINs masked, continuation lines indented.
  void add(String source, String message, {DateTime? at}) {
    if (!enabled) return;
    final t = at ?? _clock();
    final ms = t.millisecond.toString().padLeft(3, '0');
    final text = maskVins(message).replaceAll('\n', '\n    ');
    _buffer.write('${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}.$ms [$source] $text\n');
    _timer ??= Timer(flushEvery, flush);
  }

  /// Logs and writes at once: the app may be about to die.
  Future<void> error(String source, String message) {
    if (!enabled) return _writing;
    add(source, message);
    return flush();
  }

  Future<void> flush() {
    _timer?.cancel();
    _timer = null;
    if (_buffer.isEmpty) return _writing;
    final text = _buffer.toString();
    _buffer.clear();
    return _writing = _writing.then((_) async {
      try {
        await _store.append(text);
        _hasContent = true;
      } catch (_) {
        // A full disk must not break the app; the lines are lost.
      }
    });
  }

  /// The whole log, oldest line first.
  Future<String> export() async {
    await flush();
    try {
      return await _store.readAll();
    } catch (_) {
      return '';
    }
  }

  Future<void> dispose() => flush();
}
