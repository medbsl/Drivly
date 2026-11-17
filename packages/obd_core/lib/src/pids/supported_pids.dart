/// Decodes a supported-PIDs bitmask reply (`41 00 BE 1F B8 10`).
///
/// The 32 bits map MSB → PID base+1 … LSB → PID base+0x20. The LSB set means
/// "ask base+0x20 next".
Set<int> decodeSupportedMask(int base, List<int> mask) {
  final out = <int>{};
  if (mask.length < 4) return out;
  for (var byte = 0; byte < 4; byte++) {
    for (var bit = 0; bit < 8; bit++) {
      if (mask[byte] & (0x80 >> bit) != 0) {
        out.add(base + byte * 8 + bit + 1);
      }
    }
  }
  return out;
}

/// Encodes PIDs back into a 4-byte mask (used by the simulator).
List<int> encodeSupportedMask(int base, Set<int> pids) {
  final out = [0, 0, 0, 0];
  for (final pid in pids) {
    final offset = pid - base - 1;
    if (offset < 0 || offset >= 32) continue;
    out[offset ~/ 8] |= 0x80 >> (offset % 8);
  }
  return out;
}
