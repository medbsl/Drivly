import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// Rounded surface card with a hairline border and an optional status tint.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Space.l),
    this.tint,
    this.glow = false,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// Status color; the card gets a ~10% tinted background and border.
  final Color? tint;

  /// A faint accent glow along the top edge (hero cards).
  final bool glow;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(Space.cardRadius);
    final bg = tint == null ? c.surface : Color.alphaBlend(tint!.withValues(alpha: 0.10), c.surface);
    final border = tint == null ? c.outline : tint!.withValues(alpha: 0.35);
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            border: Border.all(color: border),
            gradient: glow
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color.alphaBlend(c.accent.withValues(alpha: 0.10), bg), bg],
                    stops: const [0, 0.6],
                  )
                : null,
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.padding});
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsetsDirectional.fromSTEB(4, Space.xl, 4, Space.s),
      child: Row(
        children: [
          Expanded(
            child: Text(title.toUpperCase(), style: context.text.labelSmall),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Small pill: tinted background, colored icon + word. Never color alone.
class ToneChip extends StatelessWidget {
  const ToneChip({super.key, required this.label, required this.color, this.icon, this.dense = false});
  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 13 : 15, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: dense ? 12 : 13, fontWeight: FontWeight.w700, letterSpacing: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}
