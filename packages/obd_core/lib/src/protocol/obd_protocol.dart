/// OBD2 bus protocols as numbered by the ELM327 (`ATDPN`).
enum ObdProtocol {
  j1850Pwm(1, 'SAE J1850 PWM'),
  j1850Vpw(2, 'SAE J1850 VPW'),
  iso9141(3, 'ISO 9141-2'),
  kwp5Baud(4, 'ISO 14230-4 KWP (5 baud)'),
  kwpFast(5, 'ISO 14230-4 KWP (fast)'),
  can11x500(6, 'ISO 15765-4 CAN 11/500'),
  can29x500(7, 'ISO 15765-4 CAN 29/500'),
  can11x250(8, 'ISO 15765-4 CAN 11/250'),
  can29x250(9, 'ISO 15765-4 CAN 29/250'),
  j1939(10, 'SAE J1939 CAN 29/250'),
  user1(11, 'User CAN 11/125'),
  user2(12, 'User CAN 11/50');

  const ObdProtocol(this.number, this.technicalName);
  final int number;
  final String technicalName;

  bool get isCan => number >= 6;
  bool get isCan29 => this == can29x500 || this == can29x250 || this == j1939;

  /// Header length in hex characters when headers are on.
  int get headerChars => isCan ? (isCan29 ? 8 : 3) : 6;

  /// Parses an `ATDPN` reply such as `A6` (auto, found 6) or `6`.
  static ObdProtocol? fromDpn(String reply) {
    final s = reply.trim().toUpperCase();
    if (s.isEmpty) return null;
    final n = int.tryParse(s[s.length - 1], radix: 16);
    if (n == null) return null;
    for (final p in values) {
      if (p.number == n) return p;
    }
    return null;
  }
}
