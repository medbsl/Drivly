import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'data/database.dart';
import 'data/settings.dart';
import 'features/fault_codes/dtc_database.dart';

Future<void> main() async {
  // Crashes are logged locally only: no crash-reporting SDKs (privacy).
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('flutter error: ${details.exceptionAsString()}');
  };
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Browser: SQLite compiled to WebAssembly, stored in IndexedDB.
    if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;
    final results = await Future.wait([
      SharedPreferences.getInstance(),
      AppDatabase.open(),
      DtcDatabase.load(),
    ]);
    final prefs = results[0] as SharedPreferences;
    // Dev/screenshot convenience: --dart-define=DRIVLY_DEMO=true boots
    // straight into demo mode.
    if (const bool.fromEnvironment('DRIVLY_DEMO')) {
      await prefs.setBool('onboardingDone', true);
      await prefs.setBool('safetyNoticeSeen', true);
      await prefs.setString('savedAdapterId', 'demo');
      await prefs.setString('savedAdapterName', 'Drivly Demo');
    }
    runApp(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(results[1] as AppDatabase),
        dtcDatabaseProvider.overrideWithValue(results[2] as DtcDatabase),
      ],
      child: const DrivlyApp(),
    ));
  }, (error, stack) {
    debugPrint('uncaught: $error\n$stack');
  });
}
