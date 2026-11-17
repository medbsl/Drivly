import 'obd_protocol.dart';

/// One complete message from one ECU. [payload] starts with the response
/// mode byte (e.g. 0x41) and has ISO-TP framing, headers and checksums removed.
class EcuMessage {
  const EcuMessage(this.ecu, this.payload);
  final String? ecu;
  final List<int> payload;

  @override
  String toString() => 'EcuMessage(${ecu ?? '-'}: ${hex(payload)})';
}

String hex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');

final _hexOnly = RegExp(r'^[0-9A-F]+$');
final _segment = RegExp(r'^([0-9A-F]):([0-9A-F]*)$');

List<int>? _bytes(String hexString) {
  if (hexString.length.isOdd || !_hexOnly.hasMatch(hexString)) return null;
  final out = <int>[];
  for (var i = 0; i < hexString.length; i += 2) {
    out.add(int.parse(hexString.substring(i, i + 2), radix: 16));
  }
  return out;
}

/// Reassembles ISO-TP (ISO 15765-2) frames per ECU. Interleaved replies from
/// several ECUs are kept apart by their header.
class IsoTpAssembler {
  final Map<String, List<int>> _buffers = {};
  final Map<String, int> _expected = {};
  final List<EcuMessage> _done = [];

  void addFrame(String ecu, List<int> frame) {
    if (frame.isEmpty) return;
    final type = frame[0] >> 4;
    switch (type) {
      case 0: // single frame
        final len = frame[0] & 0x0F;
        if (len == 0 || frame.length < 1 + len) return;
        _done.add(EcuMessage(ecu, frame.sublist(1, 1 + len)));
      case 1: // first frame
        if (frame.length < 2) return;
        final total = ((frame[0] & 0x0F) << 8) | frame[1];
        _expected[ecu] = total;
        _buffers[ecu] = frame.sublist(2);
        _completeIfDone(ecu);
      case 2: // consecutive frame
        final buf = _buffers[ecu];
        if (buf == null) return;
        buf.addAll(frame.sublist(1));
        _completeIfDone(ecu);
      default: // flow control (3) or junk
        return;
    }
  }

  void _completeIfDone(String ecu) {
    final total = _expected[ecu];
    final buf = _buffers[ecu];
    if (total == null || buf == null || buf.length < total) return;
    _done.add(EcuMessage(ecu, buf.sublist(0, total)));
    _buffers.remove(ecu);
    _expected.remove(ecu);
  }

  List<EcuMessage> get messages => List.unmodifiable(_done);
}

/// Parses sanitized reply lines into ECU messages.
///
/// Tolerant by design: it accepts spaced or unspaced hex, replies with or
/// without headers (clones sometimes ignore ATH1/ATS0) and the header-less
/// multi-frame layout (`014` / `0: …` / `1: …`).
List<EcuMessage> parseReply(List<String> lines, {ObdProtocol? protocol}) {
  final compact = [
    for (final l in lines)
      if (l.replaceAll(' ', '').isNotEmpty) l.replaceAll(' ', ''),
  ];
  if (compact.isEmpty) return const [];

  // Header-less CAN multi-frame: "014", "0:490201...", "1:...".
  if (compact.any(_segment.hasMatch)) {
    return _parseSegmented(compact);
  }

  final isCan = protocol?.isCan ?? _looksLikeCan(compact);
  if (isCan) {
    final headerChars = protocol?.headerChars ?? (compact.first.length >= 10 && compact.first.startsWith('18') ? 8 : 3);
    final tp = IsoTpAssembler();
    final headerless = <EcuMessage>[];
    for (final line in compact) {
      final withHeader = _canFrame(line, headerChars);
      if (withHeader != null) {
        tp.addFrame(withHeader.$1, withHeader.$2);
        continue;
      }
      final b = _bytes(line);
      if (b != null && b.isNotEmpty) headerless.add(EcuMessage(null, b));
    }
    return [...tp.messages, ...headerless];
  }

  // Legacy protocols: 3-byte header + data + checksum, one message per line.
  final out = <EcuMessage>[];
  for (final line in compact) {
    final b = _bytes(line);
    if (b == null || b.isEmpty) continue;
    // Header bytes such as 0x48 (ISO 9141) or 0x41 (J1850 PWM) look like a
    // response mode, so try the header layout first. The adapter validates
    // mode + PID afterwards, which catches the rare misread.
    if (b.length >= 5 && _isResponseMode(b[3])) {
      final ecu = b[2].toRadixString(16).padLeft(2, '0').toUpperCase();
      out.add(EcuMessage(ecu, b.sublist(3, b.length - 1)));
    } else if (_isResponseMode(b[0])) {
      out.add(EcuMessage(null, b)); // headers were off
    }
  }
  return out;
}

bool _isResponseMode(int b) => b >= 0x41 && b <= 0x4F;

bool _looksLikeCan(List<String> compact) {
  final first = compact.first;
  return first.length.isOdd || (first.startsWith('18DA') && first.length >= 10) || first.startsWith('7E');
}

/// Returns (header, frame bytes incl. PCI) or null when the line has no header.
(String, List<int>)? _canFrame(String line, int headerChars) {
  if (line.length <= headerChars) return null;
  if (headerChars == 3 && line.length.isEven) return null; // 11-bit header makes the line odd
  if (headerChars == 8 && !line.startsWith('18')) return null;
  final header = line.substring(0, headerChars);
  final bytes = _bytes(line.substring(headerChars));
  if (bytes == null || bytes.isEmpty) return null;
  final type = bytes[0] >> 4;
  if (type > 3) return null; // not a PCI byte: probably a header-less line
  return (header, bytes);
}

List<EcuMessage> _parseSegmented(List<String> compact) {
  int? total;
  final data = <int>[];
  for (final line in compact) {
    final m = _segment.firstMatch(line);
    if (m != null) {
      final b = _bytes(m.group(2)!);
      if (b != null) data.addAll(b);
    } else if (line.length <= 3 && _hexOnly.hasMatch(line)) {
      total = int.parse(line, radix: 16);
    }
  }
  if (data.isEmpty) return const [];
  final t = total;
  return [EcuMessage(null, t != null && t <= data.length ? data.sublist(0, t) : data)];
}
