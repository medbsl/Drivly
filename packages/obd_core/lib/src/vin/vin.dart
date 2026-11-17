import 'wmi_table.dart';

final _vinChars = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');

/// 17 characters, no I, O or Q. The check digit is not enforced (EU VINs
/// don't use it).
bool isValidVin(String vin) => _vinChars.hasMatch(vin);

/// Extracts the VIN from assembled mode 09 PID 02 messages.
///
/// CAN: one message `49 02 01` + 17 ASCII bytes. Legacy: five messages
/// `49 02 0N` + 4 bytes each.
String? parseVinMessages(List<List<int>> payloads) {
  final chars = StringBuffer();
  for (final p in payloads) {
    if (p.length < 3 || p[0] != 0x49 || p[1] != 0x02) continue;
    for (final b in p.sublist(3)) {
      if ((b >= 0x30 && b <= 0x39) || (b >= 0x41 && b <= 0x5A)) chars.writeCharCode(b);
    }
  }
  final s = chars.toString();
  if (s.length < 17) return null;
  final vin = s.substring(s.length - 17);
  return isValidVin(vin) ? vin : null;
}

class ModelYear {
  const ModelYear(this.year, {required this.certain});
  final int year;

  /// False when the 30-year cycle leaves room for doubt ("2016 (likely)").
  final bool certain;
}

const _yearCodes = 'ABCDEFGHJKLMNPRSTVWXY123456789'; // A = 1980 / 2010

/// Decodes the model year from VIN position 10.
ModelYear? decodeModelYear(String vin, {int? currentYear}) {
  if (vin.length != 17) return null;
  final idx = _yearCodes.indexOf(vin[9]);
  if (idx < 0) return null;
  final now = currentYear ?? DateTime.now().year;
  final base = 1980 + idx;

  // North America: position 7 letter → 2010–2039 cycle, digit → 1980–2009.
  if ('12345'.contains(vin[0])) {
    final isLetter = RegExp(r'[A-Z]').hasMatch(vin[6]);
    final year = isLetter ? base + 30 : base;
    if (year <= now + 1) return ModelYear(year, certain: true);
  }

  // OBD2 started in 1996: pick the most recent candidate ≤ next year.
  int? best;
  for (final y in [base, base + 30, base + 60]) {
    if (y >= 1996 && y <= now + 1) best = y;
  }
  return best == null ? null : ModelYear(best, certain: false);
}

class VinInfo {
  const VinInfo({required this.vin, this.make, this.country, this.modelYear});
  final String vin;
  final String? make;
  final String? country;
  final ModelYear? modelYear;
}

/// Decodes make, country and likely year offline.
VinInfo decodeVin(String vin, {int? currentYear}) {
  final wmi = vin.length >= 3 ? vin.substring(0, 3) : vin;
  return VinInfo(
    vin: vin,
    make: lookupMake(wmi),
    country: lookupCountry(wmi),
    modelYear: decodeModelYear(vin, currentYear: currentYear),
  );
}
