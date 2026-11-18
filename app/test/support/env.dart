import 'package:drivly/app/providers.dart';
import 'package:drivly/data/database.dart';
import 'package:drivly/data/settings.dart';
import 'package:drivly/features/connection/connection_controller.dart';
import 'package:drivly/features/fault_codes/dtc_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:obd_core/obd_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A fresh in-memory database. Call `sqfliteFfiInit` in `setUpAll` first.
Future<AppDatabase> openTestDb() =>
    AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfiNoIsolate);

/// The app's providers over an in-memory database and mock preferences.
/// [transports] replaces Bluetooth (and the demo simulator) when given; the
/// adapter's timeouts are then shrunk 20× so failures show up quickly.
/// The container and the database are closed when the test ends.
Future<(ProviderContainer, AppDatabase)> testContainer({
  Map<String, Object> prefs = const {},
  ObdTransport Function(AdapterRef device)? transports,
  List<Override> overrides = const [],
}) async {
  final db = await openTestDb();
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(sp),
    databaseProvider.overrideWithValue(db),
    dtcDatabaseProvider.overrideWithValue(DtcDatabase(const {})),
    if (transports != null) ...[
      transportFactoryProvider.overrideWithValue(transports),
      adapterTimeoutScaleProvider.overrideWithValue(0.05),
    ],
    ...overrides,
  ]);
  addTearDown(() async {
    await container.read(connectionProvider.notifier).disconnect();
    container.dispose();
    await db.close();
  });
  return (container, db);
}

/// Waits (in real time) until [condition] holds, failing after [timeout].
Future<void> until(bool Function() condition, {Duration timeout = const Duration(seconds: 5), String? reason}) async {
  final end = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('timed out waiting${reason == null ? '' : ' for $reason'}');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
