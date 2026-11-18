import 'dart:convert';
import 'dart:io';

import 'package:drivly/features/fault_codes/dtc_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final db = DtcDatabase({
    'P0133': {
      'title': 'Front oxygen sensor is slow',
      'severity': 'medium',
      'meaning': 'The sensor reacts too slowly.',
      'symptoms': ['Higher fuel use'],
      'safeToDrive': 'Yes, for now.',
      'causes': ['Old sensor', 'Exhaust leak'],
      'action': 'Book a garage visit.',
      'technicalTitle': 'O2 Sensor Circuit Slow Response (Bank 1 Sensor 1)',
    },
    'P0301': {'title': 'Cylinder 1 misfire'},
  });

  test('a known code gets its full explanation', () {
    final i = db.lookup('P0133');
    expect(i.title, 'Front oxygen sensor is slow');
    expect(i.severity, Severity.medium);
    expect(i.meaning, 'The sensor reacts too slowly.');
    expect(i.symptoms, ['Higher fuel use']);
    expect(i.safeToDrive, 'Yes, for now.');
    expect(i.causes, ['Old sensor', 'Exhaust leak']);
    expect(i.action, 'Book a garage visit.');
    expect(i.technicalTitle, startsWith('O2 Sensor'));
    expect(i.fromCategory, isFalse);
  });

  test('a known code without a severity takes it from its category', () {
    final i = db.lookup('P0301');
    expect(i.title, 'Cylinder 1 misfire');
    expect(i.severity, Severity.high, reason: 'P03xx is ignition / misfire');
    expect(i.symptoms, isEmpty);
  });

  test('unknown generic codes fall back to the category from their number', () {
    final cases = {
      'P0171': ('Fuel and air mixture problem', Severity.medium),
      'P0300': ('Ignition or misfire problem', Severity.high),
      'P0455': ('Emissions control problem', Severity.minor),
      'P0505': ('Speed, idle or cruise control problem', Severity.medium),
      'P0606': ('Engine computer or wiring problem', Severity.medium),
      'P0700': ('Transmission problem', Severity.medium),
      'P0A80': ('Hybrid system problem', Severity.medium),
      'B0001': ('Body electronics problem', Severity.minor),
      'C0035': ('Chassis problem (brakes, steering, suspension)', Severity.high),
      'U0100': ('Communication problem between car computers', Severity.medium),
    };
    cases.forEach((code, expected) {
      final i = db.lookup(code);
      expect((i.title, i.severity), expected, reason: code);
      expect(i.fromCategory, isTrue, reason: code);
      expect(i.manufacturerSpecific, isFalse, reason: code);
      expect(i.meaning, contains(expected.$1.toLowerCase()), reason: code);
      expect(i.action, 'Ask a garage to check it.');
    });
  });

  test('manufacturer-specific codes say so', () {
    for (final code in ['P1234', 'P3000', 'B1001', 'C2100', 'U1000']) {
      final i = db.lookup(code);
      expect(i.manufacturerSpecific, isTrue, reason: code);
      expect(i.title, 'Manufacturer-specific code', reason: code);
      expect(i.meaning, 'Your car maker defines this code.');
    }
  });

  test('a malformed code never throws', () {
    expect(db.lookup('').title, 'Unknown problem');
    expect(db.lookup('P0').title, 'Unknown problem');
    expect(db.lookup('X0123').title, 'Unknown problem');
  });

  test('fallback texts come from the language file when present', () {
    final de = DtcDatabase(const {}, {
      'ignition': 'Zündungs- oder Aussetzerproblem',
      'categoryMeaning': 'Laut Nummer gehört er zu: {category}.',
      'fallbackAction': 'Lass ihn in einer Werkstatt prüfen.',
      'manufacturer': 'Herstellerspezifischer Code',
    });
    final i = de.lookup('P0300');
    expect(i.title, 'Zündungs- oder Aussetzerproblem');
    expect(i.meaning, 'Laut Nummer gehört er zu: zündungs- oder aussetzerproblem.');
    expect(i.action, 'Lass ihn in einer Werkstatt prüfen.');
    expect(de.lookup('P1000').title, 'Herstellerspezifischer Code');
  });

  test('the bundled English database is valid and every entry loads', () {
    final json = jsonDecode(File('assets/dtc/en.json').readAsStringSync()) as Map<String, dynamic>;
    final codes = (json['codes'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v as Map<String, dynamic>));
    final strings = (json['strings'] as Map<String, dynamic>? ?? const {}).map((k, v) => MapEntry(k, v as String));
    final bundled = DtcDatabase(codes, strings);
    expect(bundled.size, greaterThan(0));
    final pattern = RegExp(r'^[PBCU][0-3][0-9A-F]{3}$');
    for (final code in codes.keys) {
      expect(code, matches(pattern));
      final i = bundled.lookup(code);
      expect(i.title, isNotEmpty, reason: code);
      expect(i.fromCategory, isFalse, reason: code);
    }
  });
}
