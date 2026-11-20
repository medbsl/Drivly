import 'package:drivly/app/app.dart';
import 'package:drivly/app/providers.dart';
import 'package:drivly/core/debug_log.dart';
import 'package:drivly/features/fault_codes/dtc_database.dart';
import 'package:drivly/data/settings.dart';
import 'package:drivly/features/connection/connection_controller.dart';
import 'package:drivly/features/debug/debug_recorder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obd_core/obd_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/env.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  /// The app with debug logging [on], the car's ignition off, and the recorder
  /// running as DrivlyApp runs it.
  Future<(ProviderContainer, DebugLog)> app({required bool on}) async {
    final log = DebugLog(MemoryDebugLogStore());
    final car = SimulatedCar()..ignitionOn = false;
    final (c, _) = await testContainer(
      prefs: {'debugLogging': on, 'savedAdapterName': 'OBDII'},
      transports: (_) => Elm327Simulator(realtime: false, car: car),
      overrides: [debugLogProvider.overrideWithValue(log)],
    );
    final sub = c.listen(debugRecorderProvider, (_, _) {});
    addTearDown(sub.close);
    return (c, log);
  }

  Future<void> failToConnect(ProviderContainer c) async {
    await c.read(connectionProvider.notifier).connectBle('AA:BB', 'OBDII');
    expect(c.read(connectionProvider).phase, ConnPhase.carNotResponding);
  }

  test('off: nothing is recorded', () async {
    final (c, log) = await app(on: false);
    await failToConnect(c);
    expect(await log.export(), isEmpty);
    expect(c.read(adapterLogProvider).verbose, isFalse);
  });

  test('on: a failed connection is recorded in full', () async {
    final (c, log) = await app(on: true);
    await failToConnect(c);
    final text = await log.export();
    expect(text, contains('[app] debug logging on'));
    expect(text, contains('adapter OBDII'));
    expect(text, contains('[obd] >> ATZ'));
    expect(text, contains('[obd] >> 0100'));
    expect(text, contains('[obd] -- raw: '));
    expect(text, contains('UNABLE TO CONNECT'));
    expect(text, contains('[conn] connectingTransport'));
    expect(text, contains('[conn] carNotResponding · UNABLE TO CONNECT'));
  });

  test('verbose follows the setting', () async {
    final (c, _) = await app(on: true);
    expect(c.read(adapterLogProvider).verbose, isTrue);
    c.read(settingsProvider.notifier).setDebugLogging(false);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(adapterLogProvider).verbose, isFalse);
  });

  test('toggled off and on: old lines kept, a new header, nothing copied twice', () async {
    final (c, log) = await app(on: true);
    await failToConnect(c);
    final settings = c.read(settingsProvider.notifier);
    settings.setDebugLogging(false);
    await Future<void>.delayed(Duration.zero);
    await failToConnect(c); // not recorded
    settings.setDebugLogging(true);
    await Future<void>.delayed(Duration.zero);
    await failToConnect(c);
    final text = await log.export();
    expect('debug logging on'.allMatches(text), hasLength(2));
    expect('[obd] >> ATZ'.allMatches(text), hasLength(2), reason: 'one per recorded connection');
  });

  test('errors are recorded only while on', () async {
    final (c, log) = await app(on: false);
    await log.error('error', 'early');
    c.read(settingsProvider.notifier).setDebugLogging(true);
    await Future<void>.delayed(Duration.zero);
    await log.error('error', 'StateError: boom');
    final text = await log.export();
    expect(text, contains('[error] StateError: boom'));
    expect(text, isNot(contains('early')));
  });

  testWidgets('the running app records while debug logging is on', (tester) async {
    final db = (await tester.runAsync(openTestDb))!;
    addTearDown(() => tester.runAsync(db.close));
    SharedPreferences.setMockInitialValues({'onboardingDone': true, 'safetyNoticeSeen': true, 'debugLogging': true});
    final prefs = await SharedPreferences.getInstance();
    final log = DebugLog(MemoryDebugLogStore());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        dtcDatabaseProvider.overrideWithValue(DtcDatabase(const {})),
        debugLogProvider.overrideWithValue(log),
      ],
      child: const DrivlyApp(),
    ));
    await tester.pump();
    expect(log.enabled, isTrue);
    expect((await tester.runAsync(log.export))!, contains('debug logging on'));
  });
}
