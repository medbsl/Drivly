import 'package:drivly/app/theme/app_theme.dart';
import 'package:drivly/core/debug_log.dart';
import 'package:drivly/data/settings.dart';
import 'package:drivly/features/debug/debug_recorder.dart';
import 'package:drivly/features/settings/settings_screen.dart';
import 'package:drivly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/env.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  Future<ProviderContainer> show(WidgetTester tester, {DebugLog? log}) async {
    await tester.binding.setSurfaceSize(const Size(430, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final (c, _) = (await tester.runAsync(
      () => testContainer(overrides: [if (log != null) debugLogProvider.overrideWithValue(log)]),
    ))!;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: buildTheme(Brightness.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsScreen(),
      ),
    ));
    await tester.pump();
    return c;
  }

  testWidgets('the debug switch turns logging on and offers Share', (tester) async {
    final c = await show(tester);
    expect(find.text('Debug logging'), findsOneWidget);
    expect(find.text('Saves connection details to a file for bug reports'), findsOneWidget);
    expect(find.text('Share debug logs'), findsNothing, reason: 'nothing recorded yet');

    await tester.tap(find.text('Debug logging'));
    await tester.pump();
    expect(c.read(settingsProvider).debugLogging, isTrue);
    expect(find.text('Share debug logs'), findsOneWidget);
  });

  testWidgets('a log from an earlier run can still be shared with logging off', (tester) async {
    await show(tester, log: DebugLog(MemoryDebugLogStore(), hasContent: true));
    expect(find.text('Share debug logs'), findsOneWidget);
  });
}
