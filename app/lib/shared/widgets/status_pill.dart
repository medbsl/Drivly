import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tokens.dart';
import '../../core/sensor_meta.dart';
import '../../features/connection/connection_controller.dart';

/// Connection pill in the app bar: Connected · Connecting… · Not connected · DEMO.
class StatusPill extends ConsumerWidget {
  const StatusPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(connectionProvider);
    final c = context.colors;
    final l = context.l10n;
    final (label, color, pulsing) = switch (s.phase) {
      ConnPhase.ready => (s.isDemo ? l.pillDemo : l.pillConnected, s.isDemo ? c.accent : c.good, false),
      ConnPhase.connectingTransport || ConnPhase.initializingAdapter || ConnPhase.searchingCar => (l.pillConnecting, c.accent, true),
      ConnPhase.reconnecting => (l.pillReconnecting, c.warn, true),
      _ => (l.pillNotConnected, c.textSecondary, false),
    };
    final demoOutline = s.isDemo && s.isReady;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: s.isReady || s.isBusy ? null : () => context.push('/connect'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: demoOutline ? Colors.transparent : color.withValues(alpha: 0.14),
            border: demoOutline ? Border.all(color: c.accent, width: 1.5) : null,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Dot(color: color, pulsing: pulsing && !context.reduceMotion),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: demoOutline ? 1.2 : 0.1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.color, required this.pulsing});
  final Color color;
  final bool pulsing;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    if (widget.pulsing) _c.repeat();
  }

  @override
  void didUpdateWidget(_Dot old) {
    super.didUpdateWidget(old);
    if (widget.pulsing && !_c.isAnimating) _c.repeat();
    if (!widget.pulsing && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 10,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _DotPainter(widget.color, widget.pulsing ? _c.value : 0),
        ),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  _DotPainter(this.color, this.t);
  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    if (t > 0) {
      canvas.drawCircle(c, 4 + t * 6, Paint()..color = color.withValues(alpha: (1 - t) * 0.5));
    }
    canvas.drawCircle(c, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_DotPainter old) => old.t != t || old.color != color;
}
