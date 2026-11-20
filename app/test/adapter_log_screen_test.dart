import 'package:drivly/app/theme/app_theme.dart';
import 'package:drivly/features/connection/connection_controller.dart';
import 'package:drivly/features/settings/settings_screen.dart';
import 'package:drivly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obd_core/obd_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/env.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  testWidgets('after "car not answering" the log shows what was sent and received', (tester) async {
    final car = SimulatedCar()..ignitionOn = false;
    final (c, _) = (await tester.runAsync(
      () => testContainer(transports: (_) => Elm327Simulator(realtime: false, car: car)),
    ))!;
    await tester.runAsync(() => c.read(connectionProvider.notifier).connectBle('AA:BB', 'OBDII'));
    expect(c.read(connectionProvider).phase, ConnPhase.carNotResponding);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: buildTheme(Brightness.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AdapterLogScreen(),
      ),
    ));
    await tester.pump();

    expect(find.text('Nothing logged yet.'), findsNothing);
    expect(find.textContaining('>> ATZ'), findsOneWidget);
    expect(find.textContaining('>> 0100'), findsOneWidget);
  });
}
