import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/sensor_meta.dart';
import '../data/settings.dart';
import '../features/connection/connect_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/fault_codes/code_detail_screen.dart';
import '../features/fault_codes/codes_screen.dart';
import '../features/fault_codes/dtc_controller.dart';
import '../features/fault_codes/scan_history_screen.dart';
import '../features/history/history_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/trips/trip_detail_screen.dart';
import '../features/vehicle/car_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final onboarding = ValueNotifier(ref.read(settingsProvider).onboardingDone);
  ref.listen(settingsProvider.select((s) => s.onboardingDone), (_, v) => onboarding.value = v);
  ref.onDispose(onboarding.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: onboarding,
    redirect: (context, state) {
      final atOnboarding = state.matchedLocation == '/onboarding';
      if (!onboarding.value && !atOnboarding) return '/onboarding';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/connect', builder: (_, _) => const ConnectScreen()),
      GoRoute(
        path: '/settings',
        builder: (_, _) => const SettingsScreen(),
        routes: [GoRoute(path: 'log', builder: (_, _) => const AdapterLogScreen())],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _TabShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/history',
              builder: (_, _) => const HistoryScreen(),
              routes: [
                GoRoute(
                  path: 'trip/:id',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (_, s) => TripDetailScreen(id: s.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/codes',
              builder: (_, _) => const CodesScreen(),
              routes: [
                GoRoute(path: 'history', parentNavigatorKey: rootNavigatorKey, builder: (_, _) => const ScanHistoryScreen()),
                GoRoute(
                  path: ':code',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (_, s) => CodeDetailScreen(
                    code: s.pathParameters['code']!,
                    pending: s.uri.queryParameters['kind'] == 'pending',
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/car', builder: (_, _) => const CarScreen())]),
        ],
      ),
    ],
  );
});

class _TabShell extends ConsumerWidget {
  const _TabShell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final codes = ref.watch(dtcControllerProvider.select((s) => s.last?.codes.length ?? 0));
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.speed_outlined), selectedIcon: const Icon(Icons.speed_rounded), label: l.tabHome),
          NavigationDestination(icon: const Icon(Icons.insights_outlined), selectedIcon: const Icon(Icons.insights_rounded), label: l.tabHistory),
          NavigationDestination(
            icon: Badge(isLabelVisible: codes > 0, label: Text('$codes'), child: const Icon(Icons.fact_check_outlined)),
            selectedIcon: Badge(isLabelVisible: codes > 0, label: Text('$codes'), child: const Icon(Icons.fact_check_rounded)),
            label: l.tabCodes,
          ),
          NavigationDestination(
            icon: const Icon(Icons.directions_car_outlined),
            selectedIcon: const Icon(Icons.directions_car_rounded),
            label: l.tabCar,
          ),
        ],
      ),
    );
  }
}
