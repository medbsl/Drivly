import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tokens.dart';
import '../../core/sensor_meta.dart';
import '../../data/settings.dart';
import '../../shared/widgets/states.dart';
import '../connection/connection_controller.dart';

/// Welcome → plug in → ignition → connect. Under 2 minutes to live data.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  void _finish(String route) {
    ref.read(settingsProvider.notifier).setOnboardingDone(true);
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final pages = [
      _Page(icon: Icons.speed_rounded, title: l.onbWelcomeTitle, body: l.onbWelcomeBody, hero: true),
      _Page(
        icon: Icons.settings_input_component_rounded,
        title: l.onbPlugTitle,
        body: l.onbPlugBody,
        extra: Column(children: [
          TextButton(onPressed: () => _info(context, l.whereIsPort, l.whereIsPortBody), child: Text(l.whereIsPort)),
          TextButton(onPressed: () => _info(context, l.whichAdapter, l.whichAdapterBody), child: Text(l.whichAdapter)),
        ]),
      ),
      _Page(icon: Icons.key_rounded, title: l.onbIgnitionTitle, body: l.onbIgnitionBody),
      _Page(icon: Icons.bluetooth_searching_rounded, title: l.onbConnectTitle, body: l.onbConnectBody),
    ];
    final last = _index == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.s),
              child: Row(children: [
                if (_index > 0)
                  IconButton(
                    tooltip: l.back,
                    icon: const BackButtonIcon(),
                    onPressed: () => _page.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ref.read(connectionProvider.notifier).connectDemo();
                    _finish('/dashboard');
                  },
                  child: Text(l.tryDemo),
                ),
              ]),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                onPageChanged: (i) => setState(() => _index = i),
                children: pages,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index ? c.accent : c.outline,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(Space.l),
              child: FilledButton(
                onPressed: () {
                  if (last) {
                    _finish('/connect');
                  } else {
                    _page.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
                  }
                },
                child: Text(_index == 0 ? l.getStarted : (last ? l.connect : l.next)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _info(BuildContext context, String title, String body) {
    showAppSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: ctx.text.titleLarge),
            const SizedBox(height: Space.m),
            Text(body, style: ctx.text.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.icon, required this.title, required this.body, this.extra, this.hero = false});
  final IconData icon;
  final String title;
  final String body;
  final Widget? extra;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Space.xl),
      child: Column(
        children: [
          const SizedBox(height: Space.xxl),
          Container(
            width: hero ? 168 : 136,
            height: hero ? 168 : 136,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [c.accent.withValues(alpha: 0.35), c.accentGlow.withValues(alpha: 0.05)]),
              border: Border.all(color: c.accent.withValues(alpha: 0.4)),
              boxShadow: [BoxShadow(color: c.accent.withValues(alpha: 0.25), blurRadius: 60)],
            ),
            child: Icon(icon, size: hero ? 84 : 64, color: c.textPrimary),
          ),
          const SizedBox(height: Space.xxl),
          Text(title, textAlign: TextAlign.center, style: context.text.headlineSmall),
          const SizedBox(height: Space.m),
          Text(body, textAlign: TextAlign.center, style: context.text.bodyLarge?.copyWith(color: c.textSecondary)),
          if (extra != null) ...[const SizedBox(height: Space.l), extra!],
        ],
      ),
    );
  }
}
