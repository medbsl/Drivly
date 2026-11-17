import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// "What happened, what to do, one primary action" (§4.10).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.tone = StatusTone.accent,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = tone.color(c);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.04)]),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: Space.xl),
          Text(title, textAlign: TextAlign.center, style: context.text.titleLarge),
          const SizedBox(height: Space.s),
          Text(body, textAlign: TextAlign.center, style: context.text.bodyMedium),
          if (primaryLabel != null) ...[
            const SizedBox(height: Space.xl),
            FilledButton(onPressed: onPrimary, child: Text(primaryLabel!)),
          ],
          if (secondaryLabel != null) ...[
            const SizedBox(height: Space.s),
            TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Shimmer-free skeleton block (respects reduce motion by not animating).
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.height = 120, this.radius = Space.cardRadius});
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          color: Color.lerp(c.surface, c.surfaceRaised, _c.value),
          border: Border.all(color: c.outline.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

/// Top banner (connection lost / reconnected / passenger view).
class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.text, required this.color, this.icon, this.action, this.onAction});
  final String text;
  final Color color;
  final IconData? icon;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsetsDirectional.fromSTEB(Space.l, 10, Space.s, 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.3))),
        ),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 18, color: color), const SizedBox(width: 10)],
            Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14))),
            if (action != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: color, minimumSize: const Size(48, 36)),
                child: Text(action!),
              ),
          ],
        ),
      ),
    );
  }
}

/// Modal bottom sheet with consistent padding.
Future<T?> showAppSheet<T>(BuildContext context, {required WidgetBuilder builder, bool scrollable = true}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: scrollable,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: builder(ctx),
    ),
  );
}
