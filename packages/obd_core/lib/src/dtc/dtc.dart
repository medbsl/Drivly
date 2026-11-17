/// Kind of trouble code, by OBD mode.
enum DtcKind {
  /// Mode 03: confirmed, usually turns the engine light on.
  stored(0x03),

  /// Mode 07: detected once, not confirmed yet.
  pending(0x07),

  /// Mode 0A: can't be cleared with mode 04.
  permanent(0x0A);

  const DtcKind(this.mode);
  final int mode;
}

class Dtc {
  const Dtc(this.code, this.kind, {this.ecu});
  final String code;
  final DtcKind kind;
  final String? ecu;

  /// P, C, B or U.
  String get system => code[0];

  /// P1xxx / P3xxx and B/C/U 1xxx–2xxx are manufacturer-specific.
  bool get isManufacturerSpecific =>
      code[0] == 'P' ? (code[1] == '1' || code[1] == '3') : (code[1] == '1' || code[1] == '2');

  @override
  bool operator ==(Object other) => other is Dtc && other.code == code && other.kind == kind;

  @override
  int get hashCode => Object.hash(code, kind);

  @override
  String toString() => '$code(${kind.name})';
}

const _letters = ['P', 'C', 'B', 'U'];

/// Decodes the 2-byte encoding: `01 33` → P0133, `C1 23` → U0123.
String decodeDtc(int a, int b) {
  final letter = _letters[a >> 6];
  final d1 = (a >> 4) & 0x03;
  final d2 = (a & 0x0F).toRadixString(16).toUpperCase();
  final rest = b.toRadixString(16).padLeft(2, '0').toUpperCase();
  return '$letter$d1$d2$rest';
}

/// Parses a mode 03/07/0A payload (starting with 0x43/0x47/0x4A).
///
/// On CAN the byte after the mode is the code count; on legacy protocols it
/// isn't. `00 00` pairs are padding.
List<String> parseDtcPayload(List<int> payload, {required bool isCan}) {
  if (payload.isEmpty) return const [];
  var data = payload.sublist(1);
  if (isCan && data.length.isOdd) data = data.sublist(1);
  final out = <String>[];
  for (var i = 0; i + 1 < data.length; i += 2) {
    if (data[i] == 0 && data[i + 1] == 0) continue;
    out.add(decodeDtc(data[i], data[i + 1]));
  }
  return out;
}

/// Engine light + number of stored codes (mode 01 PID 01, byte A).
class MonitorStatus {
  const MonitorStatus({required this.milOn, required this.dtcCount, this.raw = const []});

  factory MonitorStatus.fromBytes(List<int> d) =>
      MonitorStatus(milOn: d[0] & 0x80 != 0, dtcCount: d[0] & 0x7F, raw: List.unmodifiable(d));

  final bool milOn;
  final int dtcCount;
  final List<int> raw;
}
