import 'package:drivly/app/theme/app_theme.dart';
import 'package:drivly/features/connection/connection_controller.dart';
import 'package:drivly/features/connection/connection_errors.dart';
import 'package:drivly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/env.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  Future<void> show(WidgetTester tester, ConnState state) async {
    final (c, _) = (await tester.runAsync(testContainer))!;
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(body: SingleChildScrollView(child: ConnectionErrorView(state: state))),
      ),
      GoRoute(path: '/settings/log', builder: (_, _) => const Text('LOG SCREEN')),
      GoRoute(path: '/connect', builder: (_, _) => const Text('CONNECT SCREEN')),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(
        theme: buildTheme(Brightness.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
  }

  const device = AdapterRef(id: 'AA:BB', name: 'OBDII');

  testWidgets('car not answering: shows what the car replied and opens the log', (tester) async {
    await show(tester, const ConnState(phase: ConnPhase.carNotResponding, device: device, detail: 'UNABLE TO CONNECT'));
    expect(find.text("Your car isn't answering"), findsOneWidget);
    expect(find.text('Details: UNABLE TO CONNECT'), findsOneWidget);
    expect(find.text('Choose another adapter'), findsOneWidget);

    await tester.tap(find.text('Adapter log'));
    await tester.pumpAndSettle();
    expect(find.text('LOG SCREEN'), findsOneWidget);
  });

  testWidgets('adapter out of reach: details and log too', (tester) async {
    await show(
      tester,
      const ConnState(phase: ConnPhase.transportFailed, device: device, detail: 'TransportException: device not found'),
    );
    expect(find.text('Details: TransportException: device not found'), findsOneWidget);
    expect(find.text('Adapter log'), findsOneWidget);
  });

  testWidgets('adapter silent: the log link appears once', (tester) async {
    await show(tester, const ConnState(phase: ConnPhase.adapterNotResponding, device: device, detail: 'no reply to ATZ / ATE0'));
    expect(find.text('Details: no reply to ATZ / ATE0'), findsOneWidget);
    expect(find.text('Adapter log'), findsOneWidget);
  });

  testWidgets('no details known: no empty "Details" line', (tester) async {
    await show(tester, const ConnState(phase: ConnPhase.carNotResponding, device: device));
    expect(find.textContaining('Details'), findsNothing);
    expect(find.text('Adapter log'), findsOneWidget);
  });
}
