import 'package:drivly/app/app.dart';
import 'package:drivly/app/providers.dart';
import 'package:drivly/data/database.dart';
import 'package:drivly/data/settings.dart';
import 'package:drivly/features/connection/connection_controller.dart';
import 'package:drivly/features/fault_codes/dtc_database.dart';
import 'package:drivly/features/live/live_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obd_core/obd_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  testWidgets('demo: connect → live gauges and tiles → every reading saved', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    final db = (await tester.runAsync(
      () => AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfiNoIsolate),
    ))!;
    SharedPreferences.setMockInitialValues({'onboardingDone': true, 'safetyNoticeSeen': true});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        dtcDatabaseProvider.overrideWithValue(DtcDatabase(const {})),
      ],
      child: const DrivlyApp(),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Connect your adapter to see live data'), findsOneWidget);

    await tester.tap(find.text('Try demo'));
    final container = ProviderScope.containerOf(tester.element(find.byType(DrivlyApp)));
    for (var i = 0; i < 80 && !container.read(connectionProvider).isReady; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(container.read(connectionProvider).isReady, isTrue);

    // Let the poller run for a few (real) seconds.
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    final live = container.read(liveDataProvider);
    expect(live.value(Sensors.rpm), isNotNull);
    expect(live.value(Sensors.coolant), isNotNull);
    expect(live.polled.length, greaterThan(25), reason: 'all supported values are polled');
    expect(find.text('km/h'), findsWidgets);
    expect(find.text('Engine temperature'), findsOneWidget);
    expect(find.text('DEMO'), findsOneWidget);

    // Disconnect: the poller's timers live in the fake-async zone, so pump
    // frames while the teardown completes.
    var done = false;
    container.read(connectionProvider.notifier).disconnect().then((_) => done = true);
    for (var i = 0; i < 100 && !done; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(done, isTrue);
    final stats = (await tester.runAsync(() => container.read(historyRepoProvider).stats()))!;
    expect(stats.readings, greaterThan(50), reason: 'every reading is saved');
    expect(stats.sessions, greaterThanOrEqualTo(1));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  });
}
