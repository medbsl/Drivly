final _nonPrintable = RegExp(r'[^\x20-\x7E]');
final _lineBreaks = RegExp(r'[\r\n]+');
final _hexLine = RegExp(r'^([0-9A-F]{1,2}:)?[0-9A-F]+$');

/// Normalises a raw reply into clean, upper-case lines.
///
/// Drops the echo (when ATE0 was ignored), `SEARCHING...`, `BUS INIT: ...OK`,
/// NUL bytes and blank lines. Spaces inside lines are kept; parsers strip them.
List<String> sanitizeResponse(String raw, {String? command}) {
  final cmd = command?.replaceAll(' ', '').toUpperCase();
  final out = <String>[];
  for (var line in raw.toUpperCase().split(_lineBreaks)) {
    line = line.replaceAll(_nonPrintable, '').trim();
    if (line.isEmpty) continue;
    if (cmd != null && cmd.isNotEmpty && line.replaceAll(' ', '') == cmd) continue;
    if (line.startsWith('SEARCHING')) {
      // Some clones put data on the same line: "SEARCHING...41 00 ...".
      line = line.replaceFirst(RegExp(r'^SEARCHING\.*'), '').trim();
      if (line.isEmpty) continue;
    }
    if (line.startsWith('BUS INIT') && !line.contains('ERROR')) continue;
    out.add(line);
  }
  return out;
}

/// True when a sanitized line is hex data (optionally with a `N:` segment
/// prefix used by header-less multi-frame replies).
bool isHexDataLine(String line) => _hexLine.hasMatch(line.replaceAll(' ', ''));

/// Makes control characters visible for logs: CR as `\r`, LF as `\n`,
/// anything else below 0x20 as `\xNN`.
String showControlChars(String s) {
  final out = StringBuffer();
  for (final c in s.codeUnits) {
    if (c == 0x0D) {
      out.write(r'\r');
    } else if (c == 0x0A) {
      out.write(r'\n');
    } else if (c < 0x20) {
      out.write('\\x${c.toRadixString(16).padLeft(2, '0').toUpperCase()}');
    } else {
      out.writeCharCode(c);
    }
  }
  return out.toString();
}
