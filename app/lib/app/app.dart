import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/settings.dart';
import '../features/connection/connection_controller.dart';
import '../features/debug/debug_recorder.dart';
import '../l10n/app_localizations.dart';
import 'dev_tour.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class DrivlyApp extends ConsumerStatefulWidget {
  const DrivlyApp({super.key});

  @override
  ConsumerState<DrivlyApp> createState() => _DrivlyAppState();
}

class _DrivlyAppState extends ConsumerState<DrivlyApp> {
  @override
  void initState() {
    super.initState();
    // Saved adapter? Connect in the background; Home shows "Connecting…".
    Future.microtask(() {
      if (ref.read(settingsProvider).onboardingDone) {
        ref.read(connectionProvider.notifier).autoConnect();
      }
      if (devTour) startDevTour(ref);
    });
  }

  void _syncWakelock() {
    final on = ref.read(connectionProvider).isReady && ref.read(settingsProvider).keepScreenOn;
    WakelockPlus.toggle(enable: on).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    ref.listen(connectionProvider.select((s) => s.isReady), (_, _) => _syncWakelock());
    ref.listen(settingsProvider.select((s) => s.keepScreenOn), (_, _) => _syncWakelock());
    // Keeps the debug recorder running while Settings › Debug logging is on.
    ref.listen(debugRecorderProvider, (_, _) {});

    return MaterialApp.router(
      title: 'Drivly',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
