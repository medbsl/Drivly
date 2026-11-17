/// Turns an arbitrary byte stream into complete ELM327 replies.
///
/// ELM327 ends every reply with the `>` prompt. BLE notifications can split a
/// reply anywhere, so bytes are buffered until the prompt arrives.
class ResponseFramer {
  ResponseFramer({this.maxBuffer = 4096});

  /// Guard against an adapter that streams garbage without ever sending `>`.
  final int maxBuffer;
  final StringBuffer _buf = StringBuffer();

  /// Adds [bytes] and returns every reply completed by them (prompt removed).
  List<String> add(List<int> bytes) {
    final out = <String>[];
    for (final b in bytes) {
      if (b == 0x3E) {
        out.add(_buf.toString());
        _buf.clear();
      } else if (b == 0x00) {
        continue; // some clones pad with NUL
      } else {
        _buf.writeCharCode(b & 0x7F);
        if (_buf.length > maxBuffer) _buf.clear();
      }
    }
    return out;
  }

  String get pending => _buf.toString();

  void reset() => _buf.clear();
}
