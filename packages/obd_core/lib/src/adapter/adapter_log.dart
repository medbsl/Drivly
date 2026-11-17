import 'dart:async';

enum LogDirection { tx, rx, info }

class LogEntry {
  const LogEntry(this.at, this.direction, this.text);
  final DateTime at;
  final LogDirection direction;
  final String text;

  @override
  String toString() {
    final t = at.toIso8601String().substring(11, 23);
    final d = switch (direction) {
      LogDirection.tx => '>>',
      LogDirection.rx => '<<',
      LogDirection.info => '--',
    };
    return '$t $d $text';
  }
}

/// In-memory ring buffer of raw TX/RX lines. Main tool for bug reports from
/// users with odd clones.
class AdapterLog {
  AdapterLog({this.capacity = 500});

  final int capacity;
  final List<LogEntry> _entries = [];
  final _controller = StreamController<LogEntry>.broadcast();

  List<LogEntry> get entries => List.unmodifiable(_entries);
  Stream<LogEntry> get stream => _controller.stream;

  void add(LogDirection direction, String text) {
    final e = LogEntry(DateTime.now(), direction, text);
    _entries.add(e);
    if (_entries.length > capacity) _entries.removeAt(0);
    _controller.add(e);
  }

  void clear() => _entries.clear();

  /// Text export. VINs (17 chars, no I/O/Q) are masked unless [includeVin].
  String export({bool includeVin = false}) {
    final vin = RegExp(r'\b[A-HJ-NPR-Z0-9]{17}\b');
    return _entries.map((e) {
      final s = e.toString();
      return includeVin ? s : s.replaceAllMapped(vin, (m) => '${m[0]!.substring(0, 3)}••••••••••••••');
    }).join('\n');
  }
}
