import 'package:drivly/data/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(sp)]);
  addTearDown(c.dispose);
  return c;
}

/// A second app launch reading the same preferences.
ProviderContainer _relaunch(ProviderContainer c) {
  final next = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(c.read(sharedPrefsProvider))]);
  addTearDown(next.dispose);
  return next;
}

void main() {
  test('defaults on first launch', () async {
    final s = (await _container()).read(settingsProvider);
    expect(s.speedUnit, SpeedUnit.kmh);
    expect(s.tempUnit, TempUnit.celsius);
    expect(s.themeMode, ThemeMode.dark);
    expect(s.keepScreenOn, isTrue);
    expect(s.autoConnect, isTrue);
    expect(s.autoRecordTrips, isTrue);
    expect(s.onboardingDone, isFalse);
    expect(s.safetyNoticeSeen, isFalse);
    expect(s.savedAdapterId, isNull);
    expect(s.lastVehicleId, isNull);
  });

  test('every setting is saved and survives a relaunch', () async {
    final c = await _container();
    c.read(settingsProvider.notifier)
      ..setSpeedUnit(SpeedUnit.mph)
      ..setTempUnit(TempUnit.fahrenheit)
      ..setThemeMode(ThemeMode.light)
      ..setKeepScreenOn(false)
      ..setAutoConnect(false)
      ..setAutoRecordTrips(false)
      ..setOnboardingDone(true)
      ..setSafetyNoticeSeen()
      ..saveAdapter('AA:BB', 'OBDII')
      ..setLastVehicle('car-1');

    for (final s in [c.read(settingsProvider), _relaunch(c).read(settingsProvider)]) {
      expect(s.speedUnit, SpeedUnit.mph);
      expect(s.tempUnit, TempUnit.fahrenheit);
      expect(s.themeMode, ThemeMode.light);
      expect(s.keepScreenOn, isFalse);
      expect(s.autoConnect, isFalse);
      expect(s.autoRecordTrips, isFalse);
      expect(s.onboardingDone, isTrue);
      expect(s.safetyNoticeSeen, isTrue);
      expect(s.savedAdapterId, 'AA:BB');
      expect(s.savedAdapterName, 'OBDII');
      expect(s.lastVehicleId, 'car-1');
    }
  });

  test('forgetting the adapter clears it everywhere and keeps the rest', () async {
    final c = await _container({'savedAdapterId': 'AA:BB', 'savedAdapterName': 'OBDII', 'speedUnit': 1});
    c.read(settingsProvider.notifier).forgetAdapter();
    for (final s in [c.read(settingsProvider), _relaunch(c).read(settingsProvider)]) {
      expect(s.savedAdapterId, isNull);
      expect(s.savedAdapterName, isNull);
      expect(s.speedUnit, SpeedUnit.mph);
    }
  });

  test('copyWith keeps unspecified values', () {
    const a = AppSettings(savedAdapterId: 'x', savedAdapterName: 'n', lastVehicleId: 'v');
    final b = a.copyWith(speedUnit: SpeedUnit.mph);
    expect(b.speedUnit, SpeedUnit.mph);
    expect(b.savedAdapterId, 'x');
    expect(b.lastVehicleId, 'v');
    final cleared = a.copyWith(clearAdapter: true);
    expect(cleared.savedAdapterId, isNull);
    expect(cleared.savedAdapterName, isNull);
    expect(cleared.lastVehicleId, 'v');
  });
}
