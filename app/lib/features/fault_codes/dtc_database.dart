import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Severity { high, medium, minor }

/// Plain-language explanation of one fault code.
class DtcInfo {
  const DtcInfo({
    required this.code,
    required this.title,
    required this.severity,
    this.meaning,
    this.symptoms = const [],
    this.safeToDrive,
    this.causes = const [],
    this.action,
    this.technicalTitle,
    this.fromCategory = false,
    this.manufacturerSpecific = false,
  });

  final String code;
  final String title;
  final Severity severity;
  final String? meaning;
  final List<String> symptoms;
  final String? safeToDrive;
  final List<String> causes;
  final String? action;
  final String? technicalTitle;

  /// True when the code isn't in the database and we fell back to what its
  /// structure tells us.
  final bool fromCategory;
  final bool manufacturerSpecific;
}

/// Bundled, offline DTC explanations (DESIGN.md §5.6).
///
/// Fallback chain: exact code → category worked out from the code's
/// structure → "manufacturer-specific code".
class DtcDatabase {
  DtcDatabase(this._entries, [this._strings = const {}]);

  final Map<String, Map<String, dynamic>> _entries;

  /// Category and fallback texts, from the same per-language file.
  final Map<String, String> _strings;

  String _s(String key, String fallback) => _strings[key] ?? fallback;

  static Future<DtcDatabase> load({String locale = 'en'}) async {
    try {
      final raw = await rootBundle.loadString('assets/dtc/$locale.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final codes = (json['codes'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v as Map<String, dynamic>));
      final strings = (json['strings'] as Map<String, dynamic>? ?? const {}).map((k, v) => MapEntry(k, v as String));
      return DtcDatabase(codes, strings);
    } catch (_) {
      return DtcDatabase(const {});
    }
  }

  int get size => _entries.length;

  DtcInfo lookup(String code) {
    final e = _entries[code];
    if (e != null) {
      return DtcInfo(
        code: code,
        title: e['title'] as String,
        severity: Severity.values.byName(e['severity'] as String? ?? _category(code).$2.name),
        meaning: e['meaning'] as String?,
        symptoms: [...(e['symptoms'] as List<dynamic>? ?? const []).cast<String>()],
        safeToDrive: e['safeToDrive'] as String?,
        causes: [...(e['causes'] as List<dynamic>? ?? const []).cast<String>()],
        action: e['action'] as String?,
        technicalTitle: e['technicalTitle'] as String?,
      );
    }
    final manufacturer = _isManufacturer(code);
    final (title, severity) = _category(code);
    return DtcInfo(
      code: code,
      title: manufacturer ? _s('manufacturer', 'Manufacturer-specific code') : title,
      severity: severity,
      meaning: manufacturer
          ? _s('manufacturerMeaning', 'Your car maker defines this code.')
          : _s('categoryMeaning', 'From its number, it belongs to: {category}.').replaceAll('{category}', title.toLowerCase()),
      action: _s('fallbackAction', 'Ask a garage to check it.'),
      fromCategory: true,
      manufacturerSpecific: manufacturer,
    );
  }

  static bool _isManufacturer(String code) {
    if (code.length < 2) return false;
    return code[0] == 'P' ? (code[1] == '1' || code[1] == '3') : (code[1] == '1' || code[1] == '2');
  }

  (String, Severity) _category(String code) {
    if (code.length < 3) return (_s('unknown', 'Unknown problem'), Severity.medium);
    final system = code[0];
    final group = code[2];
    if (system == 'P') {
      return switch (group) {
        '0' || '1' || '2' => (_s('fuelAir', 'Fuel and air mixture problem'), Severity.medium),
        '3' => (_s('ignition', 'Ignition or misfire problem'), Severity.high),
        '4' => (_s('emissions', 'Emissions control problem'), Severity.minor),
        '5' => (_s('idle', 'Speed, idle or cruise control problem'), Severity.medium),
        '6' => (_s('computer', 'Engine computer or wiring problem'), Severity.medium),
        '7' || '8' || '9' => (_s('transmission', 'Transmission problem'), Severity.medium),
        'A' || 'B' || 'C' => (_s('hybrid', 'Hybrid system problem'), Severity.medium),
        _ => (_s('engine', 'Engine problem'), Severity.medium),
      };
    }
    return switch (system) {
      'B' => (_s('body', 'Body electronics problem'), Severity.minor),
      'C' => (_s('chassis', 'Chassis problem (brakes, steering, suspension)'), Severity.high),
      'U' => (_s('network', 'Communication problem between car computers'), Severity.medium),
      _ => (_s('unknown', 'Unknown problem'), Severity.medium),
    };
  }
}

/// Overridden in main() after loading the asset.
final dtcDatabaseProvider = Provider<DtcDatabase>((ref) => DtcDatabase(const {}));
