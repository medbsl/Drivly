import 'dart:convert';

import 'package:obd_core/obd_core.dart';
import 'package:test/test.dart';

void main() {
  group('ResponseFramer', () {
    test('reassembles a reply split across chunks', () {
      final f = ResponseFramer();
      expect(f.add(latin1.encode('41 0C ')), isEmpty);
      expect(f.add(latin1.encode('1A F8\r\r')), isEmpty);
      expect(f.add(latin1.encode('>')), ['41 0C 1A F8\r\r']);
    });

    test('splits two replies in one chunk and drops NUL bytes', () {
      final f = ResponseFramer();
      final out = f.add([...latin1.encode('OK\r\r>'), 0, ...latin1.encode('41 0D 32\r\r>')]);
      expect(out, ['OK\r\r', '41 0D 32\r\r']);
    });

    test('bounds the buffer when no prompt ever arrives', () {
      final f = ResponseFramer(maxBuffer: 10);
      f.add(latin1.encode('A' * 50));
      expect(f.pending.length, lessThanOrEqualTo(10));
    });
  });

  group('sanitizeResponse', () {
    test('drops echo, SEARCHING and blank lines, uppercases', () {
      expect(
        sanitizeResponse('010c\r\rsearching...\r41 0c 1a f8\r\r', command: '010C'),
        ['41 0C 1A F8'],
      );
    });

    test('drops the progress dots a clone leaves before the reply (VW Golf 5, K-line)', () {
      // Exact reply logged from Mohamed's adapter on 2026-11-20.
      expect(sanitizeResponse('SEARCHING...\r..86F1104100BE3EE811BD\r\r', command: '0100'), ['86F1104100BE3EE811BD']);
      expect(sanitizeResponse('SEARCHING...\r..UNABLE TO CONNECT\r\r', command: '0100'), ['UNABLE TO CONNECT']);
    });

    test('keeps data that follows SEARCHING on the same line', () {
      expect(sanitizeResponse('SEARCHING...41 00 BE 1F B8 10\r'), ['41 00 BE 1F B8 10']);
    });

    test('drops BUS INIT ok but keeps BUS INIT error', () {
      expect(sanitizeResponse('BUS INIT: ...OK\r41 05 7B'), ['41 05 7B']);
      expect(sanitizeResponse('BUS INIT: ...ERROR'), ['BUS INIT: ...ERROR']);
    });
  });

  group('classifyReply', () {
    test('maps error texts', () {
      expect(classifyReply(['NO DATA']), ElmError.noData);
      expect(classifyReply(['UNABLE TO CONNECT']), ElmError.unableToConnect);
      expect(classifyReply(['BUS INIT: ...ERROR']), ElmError.busInitError);
      expect(classifyReply(['CAN ERROR']), ElmError.canError);
      expect(classifyReply(['BUFFER FULL']), ElmError.bufferFull);
      expect(classifyReply(['?']), ElmError.unknownCommand);
      expect(classifyReply(['STOPPED']), ElmError.stopped);
      expect(classifyReply(['LV RESET']), ElmError.adapterReset);
      expect(classifyReply(['ELM327 v1.5']), ElmError.adapterReset);
    });

    test('data wins over noise; AT replies are not errors', () {
      expect(classifyReply(['41 0D 32']), isNull);
      expect(classifyReply(['ELM327 v1.5'], isAtCommand: true), isNull);
      expect(classifyReply(['OK'], isAtCommand: true), isNull);
    });
  });

  group('parseReply', () {
    test('CAN 11-bit with headers, padded single frame', () {
      final m = parseReply(['7E8 04 41 0C 1A F8 00 00 00'], protocol: ObdProtocol.can11x500);
      expect(m.single.ecu, '7E8');
      expect(m.single.payload, [0x41, 0x0C, 0x1A, 0xF8]);
    });

    test('CAN 11-bit unspaced (ATS0 honoured)', () {
      final m = parseReply(['7E803410D32'], protocol: ObdProtocol.can11x500);
      expect(m.single.payload, [0x41, 0x0D, 0x32]);
    });

    test('ISO-TP multi-frame VIN with headers', () {
      final m = parseReply([
        '7E8 10 14 49 02 01 57 56 57',
        '7E8 21 5A 5A 5A 41 55 5A 47',
        '7E8 22 57 31 32 33 34 35 36',
      ], protocol: ObdProtocol.can11x500);
      expect(parseVinMessages([m.single.payload]), 'WVWZZZAUZGW123456');
    });

    test('interleaved ECUs are reassembled separately', () {
      final m = parseReply([
        '7E8 10 0A 41 00 BE 1F B8 10',
        '7E9 06 41 00 98 18 00 01 00',
        '7E8 21 0C 1A F8 00 00 00 00',
      ], protocol: ObdProtocol.can11x500);
      expect(m, hasLength(2));
      final e8 = m.firstWhere((e) => e.ecu == '7E8');
      expect(e8.payload, [0x41, 0x00, 0xBE, 0x1F, 0xB8, 0x10, 0x0C, 0x1A, 0xF8, 0x00]);
    });

    test('CAN 29-bit headers', () {
      final m = parseReply(['18DAF110 03 41 0D 32'], protocol: ObdProtocol.can29x500);
      expect(m.single.ecu, '18DAF110');
      expect(m.single.payload, [0x41, 0x0D, 0x32]);
    });

    test('headers ignored by clone (ATH1 not honoured)', () {
      final m = parseReply(['41 0C 1A F8'], protocol: ObdProtocol.can11x500);
      expect(m.single.payload, [0x41, 0x0C, 0x1A, 0xF8]);
    });

    test('header-less multi-frame segments', () {
      final m = parseReply(['014', '0: 49 02 01 57 56 57', '1: 5A 5A 5A 41 55 5A 47', '2: 57 31 32 33 34 35 36']);
      expect(m.single.payload.length, 0x14);
      expect(parseVinMessages([m.single.payload]), 'WVWZZZAUZGW123456');
    });

    test('legacy ISO 9141 with header and checksum', () {
      final m = parseReply(['48 6B 10 41 0D 32 F3'], protocol: ObdProtocol.iso9141);
      expect(m.single.payload, [0x41, 0x0D, 0x32]);
    });

    test('unknown protocol: header-less reply', () {
      expect(parseReply(['410D32']).single.payload, [0x41, 0x0D, 0x32]);
    });

    test('garbage yields nothing instead of throwing', () {
      expect(parseReply(['ZZ#!', '7E8 GG'], protocol: ObdProtocol.can11x500), isEmpty);
      expect(parseReply(['7E8 10 14 49 02'], protocol: ObdProtocol.can11x500), isEmpty); // incomplete
    });
  });

  group('ObdProtocol.fromDpn', () {
    test('parses auto and fixed', () {
      expect(ObdProtocol.fromDpn('A6'), ObdProtocol.can11x500);
      expect(ObdProtocol.fromDpn('3'), ObdProtocol.iso9141);
      expect(ObdProtocol.fromDpn(''), isNull);
    });
  });
}
