import 'package:obd_core/obd_core.dart';
import 'package:test/test.dart';

void main() {
  group('PID decoders', () {
    test('known vectors', () {
      expect(Sensors.rpm.decodeChecked([0x1A, 0xF8]), 1726);
      expect(Sensors.speed.decodeChecked([0x32]), 50);
      expect(Sensors.coolant.decodeChecked([0x7B]), 83);
      expect(Sensors.load.decodeChecked([0xFF]), 100);
      expect(Sensors.timing.decodeChecked([0x80]), 0);
      expect(Sensors.maf.decodeChecked([0x01, 0x2C]), 3);
      expect(Sensors.stft1.decodeChecked([0x80]), 0);
      expect(Sensors.moduleVoltage.decodeChecked([0x37, 0x14]), closeTo(14.1, 0.01));
      expect(Sensors.fuelRate.decodeChecked([0x00, 0x14]), 1);
      expect(Sensors.odometer.decodeChecked([0x00, 0x0C, 0xD9, 0xAD]), closeTo(84215.7, 0.01));
    });

    test('too few bytes yields null', () {
      expect(Sensors.rpm.decodeChecked([0x1A]), isNull);
    });

    test('every PID sensor has a decoder and a byte length', () {
      for (final s in Sensors.all.where((s) => s.isPid)) {
        expect(s.decode, isNotNull, reason: s.key);
        expect(s.bytes, greaterThan(0), reason: s.key);
        expect(Sensors.dataLength(s.pid!), s.bytes, reason: s.key);
      }
      expect(Sensors.all.map((s) => s.id).toSet().length, Sensors.all.length, reason: 'ids are unique');
    });
  });

  group('supported PID bitmask', () {
    test('BE1FB810 → PIDs from the spec example', () {
      final s = decodeSupportedMask(0x00, [0xBE, 0x1F, 0xB8, 0x10]);
      expect(s, containsAll([0x01, 0x03, 0x04, 0x05, 0x06, 0x07, 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x13, 0x15, 0x1C]));
      expect(s.contains(0x02), isFalse);
      expect(s.contains(0x20), isFalse);
    });

    test('round-trips through encode', () {
      final pids = {0x21, 0x2F, 0x31, 0x40};
      expect(decodeSupportedMask(0x20, encodeSupportedMask(0x20, pids)), pids);
    });
  });

  group('DTC', () {
    test('decodes letters and digits', () {
      expect(decodeDtc(0x01, 0x33), 'P0133');
      expect(decodeDtc(0xC1, 0x23), 'U0123');
      expect(decodeDtc(0x41, 0x23), 'C0123');
      expect(decodeDtc(0x92, 0x34), 'B1234');
      expect(decodeDtc(0x03, 0x01), 'P0301');
    });

    test('CAN payload with count byte and padding', () {
      expect(parseDtcPayload([0x43, 0x02, 0x01, 0x33, 0x03, 0x01], isCan: true), ['P0133', 'P0301']);
      expect(parseDtcPayload([0x43, 0x00], isCan: true), isEmpty);
    });

    test('legacy payload without count byte', () {
      expect(parseDtcPayload([0x43, 0x01, 0x33, 0x00, 0x00, 0x00, 0x00], isCan: false), ['P0133']);
    });

    test('manufacturer-specific detection', () {
      expect(const Dtc('P1234', DtcKind.stored).isManufacturerSpecific, isTrue);
      expect(const Dtc('P0301', DtcKind.stored).isManufacturerSpecific, isFalse);
      expect(const Dtc('U0100', DtcKind.stored).isManufacturerSpecific, isFalse);
    });

    test('monitor status: engine light + count', () {
      final s = MonitorStatus.fromBytes([0x83, 0x07, 0x65, 0x00]);
      expect(s.milOn, isTrue);
      expect(s.dtcCount, 3);
    });
  });

  group('VIN', () {
    test('validates characters', () {
      expect(isValidVin('WVWZZZAUZGW123456'), isTrue);
      expect(isValidVin('WVWZZZAUZGW12345O'), isFalse); // O not allowed
      expect(isValidVin('SHORT'), isFalse);
    });

    test('legacy five-message VIN', () {
      final vin = 'WVWZZZAUZGW123456'.codeUnits;
      final msgs = [
        [0x49, 0x02, 0x01, 0x00, 0x00, 0x00, vin[0]],
        [0x49, 0x02, 0x02, ...vin.sublist(1, 5)],
        [0x49, 0x02, 0x03, ...vin.sublist(5, 9)],
        [0x49, 0x02, 0x04, ...vin.sublist(9, 13)],
        [0x49, 0x02, 0x05, ...vin.sublist(13, 17)],
      ];
      expect(parseVinMessages(msgs), 'WVWZZZAUZGW123456');
    });

    test('model year: EU is "likely", NA uses position 7', () {
      final eu = decodeModelYear('WVWZZZAUZGW123456', currentYear: 2026)!;
      expect(eu.year, 2016);
      expect(eu.certain, isFalse);

      final na = decodeModelYear('1HGCM82633A004352', currentYear: 2026)!;
      expect(na.year, 2003);
      expect(na.certain, isTrue);

      final naNew = decodeModelYear('5YJ3E1EA7KF317000', currentYear: 2026)!;
      expect(naNew.year, 2019);
    });

    test('year codes beyond next year roll back a cycle', () {
      // 'Y' = 2000 or 2030; in 2026 it must be 2000.
      expect(decodeModelYear('WVWZZZ1JZYW000001', currentYear: 2026)!.year, 2000);
    });

    test('make and country offline', () {
      final info = decodeVin('WVWZZZAUZGW123456', currentYear: 2026);
      expect(info.make, 'Volkswagen');
      expect(info.country, 'Germany');
      expect(lookupCountry('VF1'), 'France');
      expect(lookupCountry('JHM'), 'Japan');
      expect(lookupCountry('SAL'), 'United Kingdom');
      expect(lookupCountry('ZFA'), 'Italy');
      expect(lookupCountry('TMB'), 'Czech Republic');
    });
  });

  group('AdapterLog', () {
    test('redacts VINs on export by default', () {
      final log = AdapterLog()..add(LogDirection.rx, 'VIN WVWZZZAUZGW123456');
      expect(log.export(), isNot(contains('WVWZZZAUZGW123456')));
      expect(log.export(includeVin: true), contains('WVWZZZAUZGW123456'));
    });
  });
}
