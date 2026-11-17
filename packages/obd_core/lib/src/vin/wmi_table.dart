/// Offline World Manufacturer Identifier lookup.
///
/// A curated subset of common passenger-car WMIs (public facts; NHTSA vPIC is
/// public-domain). Unknown WMIs fall back to a 2-letter prefix match, then to
/// the country only.
const Map<String, String> _wmiMakes = {
  // Germany
  'WVW': 'Volkswagen', 'WV1': 'Volkswagen', 'WV2': 'Volkswagen', 'WV3': 'Volkswagen',
  'WAU': 'Audi', 'WUA': 'Audi', 'TRU': 'Audi',
  'WBA': 'BMW', 'WBS': 'BMW M', 'WBY': 'BMW i', 'WBX': 'BMW', 'WMW': 'MINI',
  'WDB': 'Mercedes-Benz', 'WDD': 'Mercedes-Benz', 'WDC': 'Mercedes-Benz', 'WDF': 'Mercedes-Benz',
  'W1K': 'Mercedes-Benz', 'W1N': 'Mercedes-Benz', 'W1V': 'Mercedes-Benz', 'W1W': 'Mercedes-Benz',
  'WME': 'smart', 'WP0': 'Porsche', 'WP1': 'Porsche',
  'W0L': 'Opel', 'W0V': 'Opel', 'W0X': 'Opel', 'WF0': 'Ford', 'WF1': 'Ford',
  // France
  'VF1': 'Renault', 'VF2': 'Renault', 'VF3': 'Peugeot', 'VR3': 'Peugeot', 'VF7': 'Citroën',
  'VR7': 'Citroën', 'VR1': 'DS', 'VNK': 'Toyota', 'VF8': 'Matra', 'VNV': 'Nissan',
  'UU1': 'Dacia', 'UU2': 'Dacia', 'UU3': 'Dacia',
  // Spain, Czechia, Slovakia, Hungary, Portugal
  'VSS': 'SEAT', 'VSK': 'Nissan', 'VS6': 'Ford', 'VS7': 'Citroën', 'VWV': 'Volkswagen',
  'TMB': 'Škoda', 'TMA': 'Hyundai', 'TMP': 'Škoda', 'U5Y': 'Kia', 'U6Y': 'Kia', 'TSM': 'Suzuki',
  'TMT': 'Tatra', 'VSE': 'Suzuki',
  // Italy
  'ZFA': 'Fiat', 'ZFC': 'Fiat', 'ZAR': 'Alfa Romeo', 'ZLA': 'Lancia', 'ZFF': 'Ferrari',
  'ZAM': 'Maserati', 'ZHW': 'Lamborghini', 'ZAC': 'Jeep',
  // UK
  'SAJ': 'Jaguar', 'SAL': 'Land Rover', 'SAD': 'Jaguar', 'SCC': 'Lotus', 'SCF': 'Aston Martin',
  'SCB': 'Bentley', 'SCA': 'Rolls-Royce', 'SB1': 'Toyota', 'SJN': 'Nissan', 'SHH': 'Honda',
  'SHS': 'Honda', 'SFD': 'Alexander Dennis', 'SAR': 'Rover', 'SAX': 'Rover', 'SMT': 'Triumph',
  // Sweden / Netherlands / Belgium / Turkey / Russia
  'YV1': 'Volvo', 'YV4': 'Volvo', 'YV2': 'Volvo Trucks', 'YS3': 'Saab', 'XLR': 'DAF',
  'NM0': 'Ford', 'NMT': 'Toyota', 'NLH': 'Hyundai', 'NM4': 'Tofaş', 'XTA': 'Lada', 'X7L': 'Renault',
  'XW8': 'Volkswagen', 'Z94': 'Hyundai',
  // Japan
  'JHM': 'Honda', 'JHL': 'Honda', 'JH4': 'Acura', 'JT2': 'Toyota', 'JTD': 'Toyota', 'JTE': 'Toyota',
  'JTM': 'Toyota', 'JTN': 'Toyota', 'JT3': 'Toyota', 'JTK': 'Toyota', 'JTH': 'Lexus', 'JTJ': 'Lexus',
  'JN1': 'Nissan', 'JN8': 'Nissan', 'JNK': 'Infiniti', 'JM1': 'Mazda', 'JMZ': 'Mazda', 'JM3': 'Mazda',
  'JF1': 'Subaru', 'JF2': 'Subaru', 'JS1': 'Suzuki', 'JS2': 'Suzuki', 'JS3': 'Suzuki',
  'JSA': 'Suzuki', 'JA3': 'Mitsubishi', 'JA4': 'Mitsubishi', 'JMB': 'Mitsubishi', 'JMY': 'Mitsubishi',
  'JDA': 'Daihatsu', 'JAA': 'Isuzu',
  // Korea
  'KMH': 'Hyundai', 'KM8': 'Hyundai', 'KMF': 'Hyundai', 'KNA': 'Kia', 'KND': 'Kia', 'KNE': 'Kia',
  'KNM': 'Renault Samsung', 'KPT': 'SsangYong', 'KL1': 'Chevrolet', 'KLA': 'Daewoo',
  // USA / Canada / Mexico
  '1FA': 'Ford', '1FB': 'Ford', '1FC': 'Ford', '1FD': 'Ford', '1FM': 'Ford', '1FT': 'Ford',
  '1G1': 'Chevrolet', '1GC': 'Chevrolet', '1GN': 'Chevrolet', '1G6': 'Cadillac', '1GY': 'Cadillac',
  '1GT': 'GMC', '1GK': 'GMC', '1G4': 'Buick', '1HG': 'Honda', '1N4': 'Nissan', '1N6': 'Nissan',
  '1C3': 'Chrysler', '1C4': 'Jeep', '1C6': 'Ram', '1J4': 'Jeep', '1J8': 'Jeep', '1D7': 'Dodge',
  '1VW': 'Volkswagen', '1LN': 'Lincoln', '1ZV': 'Ford', '19X': 'Honda', '19U': 'Acura',
  '2C3': 'Chrysler', '2C4': 'Chrysler', '2G1': 'Chevrolet', '2HG': 'Honda', '2HK': 'Honda',
  '2T1': 'Toyota', '2T3': 'Toyota', '2FM': 'Ford', '2GN': 'Chevrolet',
  '3VW': 'Volkswagen', '3FA': 'Ford', '3N1': 'Nissan', '3G1': 'Chevrolet', '3C4': 'Chrysler',
  '3MZ': 'Mazda', '3HG': 'Honda', '3KP': 'Kia',
  '4T1': 'Toyota', '4T3': 'Toyota', '4T4': 'Toyota', '4S3': 'Subaru', '4S4': 'Subaru',
  '4JG': 'Mercedes-Benz', '4US': 'BMW', '5UX': 'BMW', '5YJ': 'Tesla', '7SA': 'Tesla',
  '5TD': 'Toyota', '5TF': 'Toyota', '5NP': 'Hyundai', '5NM': 'Hyundai', '5XY': 'Kia',
  '5FN': 'Honda', '5J6': 'Honda', '5N1': 'Nissan', '5LM': 'Lincoln', '5YF': 'Toyota',
  // China / India / Brazil / South Africa / Australia
  'LSV': 'Volkswagen', 'LFV': 'Volkswagen', 'LBV': 'BMW', 'LE4': 'Mercedes-Benz', 'LRW': 'Tesla',
  'LSG': 'Buick', 'LVS': 'Ford', 'LGX': 'BYD', 'LC0': 'BYD', 'L6T': 'Geely', 'LB3': 'Geely',
  'LYV': 'Volvo', 'LJ1': 'JAC', 'LDC': 'Dongfeng', 'LMG': 'GAC', 'LSJ': 'MG', 'LNB': 'BAIC',
  'MA1': 'Mahindra', 'MA3': 'Maruti Suzuki', 'MAL': 'Hyundai', 'MAT': 'Tata', 'MBH': 'Suzuki',
  'MAJ': 'Ford', 'MR0': 'Toyota', 'MMB': 'Mitsubishi', 'MHF': 'Toyota',
  '9BW': 'Volkswagen', '9BG': 'Chevrolet', '9BF': 'Ford', '9BD': 'Fiat', '93H': 'Honda',
  '9BR': 'Toyota', 'AAV': 'Volkswagen', 'AHT': 'Toyota', 'ADM': 'GM', '6T1': 'Toyota',
  '6FP': 'Ford', '6G1': 'Holden',
};

String? lookupMake(String wmi) {
  final w = wmi.toUpperCase();
  return _wmiMakes[w];
}

/// Country of manufacture from the first two VIN characters (ISO 3780 ranges).
String? lookupCountry(String wmi) {
  if (wmi.length < 2) return null;
  final a = wmi[0].toUpperCase();
  final b = wmi[1].toUpperCase();
  bool inRange(String from, String to) => _rank(b) >= _rank(from) && _rank(b) <= _rank(to);
  switch (a) {
    case '1' || '4' || '5':
      return 'United States';
    case '2':
      return 'Canada';
    case '3':
      return 'Mexico';
    case '6':
      return 'Australia';
    case '7':
      return 'New Zealand';
    case '8':
      return 'Argentina';
    case '9':
      return 'Brazil';
    case 'A':
      return 'South Africa';
    case 'J':
      return 'Japan';
    case 'K':
      return inRange('L', 'R') ? 'South Korea' : null;
    case 'L':
      return 'China';
    case 'M':
      if (inRange('A', 'E')) return 'India';
      if (inRange('F', 'K')) return 'Indonesia';
      if (inRange('L', 'R')) return 'Thailand';
      return null;
    case 'N':
      return inRange('L', 'R') ? 'Turkey' : null;
    case 'S':
      if (inRange('A', 'M')) return 'United Kingdom';
      if (inRange('N', 'T')) return 'Germany';
      return 'Poland';
    case 'T':
      if (inRange('A', 'H')) return 'Switzerland';
      if (inRange('J', 'P')) return 'Czech Republic';
      if (inRange('R', 'V')) return 'Hungary';
      return 'Portugal';
    case 'U':
      if (inRange('H', 'M')) return 'Denmark';
      if (inRange('N', 'T')) return 'Ireland';
      if (inRange('U', 'Z')) return 'Romania';
      return 'Slovakia';
    case 'V':
      if (inRange('A', 'E')) return 'Austria';
      if (inRange('F', 'R')) return 'France';
      if (inRange('S', 'W')) return 'Spain';
      return null;
    case 'W':
      return 'Germany';
    case 'X':
      if (inRange('L', 'R')) return 'Netherlands';
      return 'Russia';
    case 'Y':
      if (inRange('A', 'E')) return 'Belgium';
      if (inRange('F', 'K')) return 'Finland';
      if (inRange('S', 'W')) return 'Sweden';
      return null;
    case 'Z':
      if (inRange('A', 'R')) return 'Italy';
      return null;
  }
  return null;
}

/// ISO 3780 order: A–Z then 1–9, 0.
int _rank(String c) {
  const order = 'ABCDEFGHJKLMNPRSTUVWXYZ1234567890';
  final i = order.indexOf(c);
  return i < 0 ? 99 : i;
}
