import 'package:drivly/features/connection/ble_scanner.dart';
import 'package:drivly/features/connection/ble_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ble/universal_ble.dart';

BleCharacteristic _c(String uuid, List<CharacteristicProperty> props) => BleCharacteristic(uuid, props, const []);

const _notify = CharacteristicProperty.notify;
const _indicate = CharacteristicProperty.indicate;
const _write = CharacteristicProperty.write;
const _writeNr = CharacteristicProperty.writeWithoutResponse;
const _read = CharacteristicProperty.read;

String _full(String short) => BleUuidParser.string(short).toLowerCase();

void main() {
  group('pickSerialLayout', () {
    test('most clones: FFF0 with FFF1 notify and FFF2 write', () {
      final l = pickSerialLayout([
        BleService('1800', [_c('2a00', [_read])]),
        BleService('fff0', [_c('fff1', [_notify]), _c('fff2', [_write, _writeNr])]),
      ])!;
      expect(l.service, _full('fff0'));
      expect(l.notify, _full('fff1'));
      expect(l.write, _full('fff2'));
      expect(l.withoutResponse, isTrue, reason: 'faster when supported');
    });

    test('HM-10 style: one characteristic for both directions', () {
      final l = pickSerialLayout([
        BleService('FFE0', [_c('FFE1', [_notify, _write])]),
      ])!;
      expect(l.service, _full('ffe0'));
      expect(l.notify, l.write);
      expect(l.withoutResponse, isFalse);
    });

    test('full 128-bit UUIDs match their short form', () {
      final l = pickSerialLayout([
        BleService('000018f0-0000-1000-8000-00805f9b34fb', [
          _c('00002af0-0000-1000-8000-00805f9b34fb', [_notify]),
          _c('00002af1-0000-1000-8000-00805f9b34fb', [_write]),
        ]),
      ])!;
      expect(l.service, _full('18f0'));
      expect(l.write, _full('2af1'));
    });

    test('Vgate iCar Pro BLE layout', () {
      const svc = 'E7810A71-73AE-499D-8C15-FAA9AEF0C3F2';
      const ch = 'BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F';
      final l = pickSerialLayout([
        BleService(svc, [_c(ch, [_notify, _writeNr])]),
      ])!;
      expect(l.service, svc.toLowerCase());
      expect(l.notify, ch.toLowerCase());
    });

    test('a known layout wins over an unknown service listed first', () {
      final l = pickSerialLayout([
        BleService('abcd', [_c('ab01', [_notify]), _c('ab02', [_write])]),
        BleService('fff0', [_c('fff1', [_notify]), _c('fff2', [_write])]),
      ])!;
      expect(l.service, _full('fff0'));
    });

    test('unknown adapters: first service with notify/indicate and write', () {
      final l = pickSerialLayout([
        BleService('180a', [_c('2a29', [_read, _notify, _write])]), // device info: ignored
        BleService('abcd', [_c('ab01', [_read]), _c('ab02', [_indicate]), _c('ab03', [_writeNr])]),
      ])!;
      expect(l.service, _full('abcd'));
      expect(l.notify, _full('ab02'));
      expect(l.write, _full('ab03'));
      expect(l.withoutResponse, isTrue);
    });

    test('a known service missing its characteristics falls through to the heuristic', () {
      final l = pickSerialLayout([
        BleService('fff0', [_c('fff9', [_notify, _write])]),
      ])!;
      expect(l.notify, _full('fff9'));
    });

    test('no serial channel → null', () {
      expect(pickSerialLayout(const []), isNull);
      expect(
        pickSerialLayout([
          BleService('1800', [_c('2a00', [_read, _notify, _write])]),
          BleService('abcd', [_c('ab01', [_notify])]), // notify but no write
        ]),
        isNull,
      );
    });
  });

  group('FoundDevice', () {
    test('likely OBD adapters are recognised by name', () {
      for (final name in ['OBDII', 'obd2', 'ELM327 v1.5', 'V-LINK', 'Vgate iCar Pro', 'VEEPEAK', 'OBDLink CX', 'KONNWEI']) {
        expect(FoundDevice(id: name, name: name, rssi: -50).likely, isTrue, reason: name);
      }
      for (final name in ['AirPods Pro', 'Galaxy Watch', 'JBL Flip 5']) {
        expect(FoundDevice(id: name, name: name, rssi: -50).likely, isFalse, reason: name);
      }
    });

    test('signal bars from RSSI', () {
      int bars(int rssi) => FoundDevice(id: 'x', name: 'x', rssi: rssi).bars;
      expect(bars(-40), 3);
      expect(bars(-60), 3);
      expect(bars(-61), 2);
      expect(bars(-75), 2);
      expect(bars(-76), 1);
      expect(bars(-90), 1);
      expect(bars(-91), 0);
    });
  });

  test('ScanState.copyWith', () {
    const s = ScanState(scanning: true, problem: ScanProblem.bluetoothOff);
    expect(s.copyWith(finished: true).problem, ScanProblem.bluetoothOff);
    expect(s.copyWith(clearProblem: true).problem, isNull);
    expect(s.copyWith(scanning: false).scanning, isFalse);
  });

  test('the browser is told about every known adapter service', () {
    expect(knownObdServices, containsAll([_full('fff0'), _full('ffe0'), _full('18f0')]));
  });
}
