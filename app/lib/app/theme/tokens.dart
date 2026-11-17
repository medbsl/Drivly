import 'package:flutter/material.dart';

/// Design tokens (DESIGN.md §3.2). Dark is the default: the app lives in cars.
/// One accent (electric blue). Green / orange / red are for status only and
/// always ship with an icon and a word.
@immutable
class DrivlyColors extends ThemeExtension<DrivlyColors> {
  const DrivlyColors({
    required this.bg,
    required this.surface,
    required this.surfaceRaised,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentGlow,
    required this.onAccent,
    required this.good,
    required this.warn,
    required this.danger,
    required this.chartGrid,
  });

  final Color bg;
  final Color surface;
  final Color surfaceRaised;
  final Color outline;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;

  /// Second stop of the accent gradient (gauge arcs, chart fills).
  final Color accentGlow;
  final Color onAccent;
  final Color good;
  final Color warn;
  final Color danger;
  final Color chartGrid;

  static const dark = DrivlyColors(
    bg: Color(0xFF0F1115),
    surface: Color(0xFF171A1F),
    surfaceRaised: Color(0xFF1F232A),
    outline: Color(0xFF2C313A),
    textPrimary: Color(0xFFF2F4F7),
    textSecondary: Color(0xFFA3AAB7),
    textMuted: Color(0xFF6B7280),
    accent: Color(0xFF3D9BFF),
    accentGlow: Color(0xFF5CE1E6),
    onAccent: Color(0xFF0F1115),
    good: Color(0xFF34D399),
    warn: Color(0xFFFFA94D),
    danger: Color(0xFFFF5A5F),
    chartGrid: Color(0xFF242932),
  );

  static const light = DrivlyColors(
    bg: Color(0xFFF4F5F7),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFEEF0F3),
    outline: Color(0xFFD9DDE3),
    textPrimary: Color(0xFF12151A),
    textSecondary: Color(0xFF5A6270),
    textMuted: Color(0xFF8A919C),
    accent: Color(0xFF0B6BDB),
    accentGlow: Color(0xFF0FA3B1),
    onAccent: Color(0xFFFFFFFF),
    good: Color(0xFF128A4B),
    warn: Color(0xFFB95E00),
    danger: Color(0xFFD92D20),
    chartGrid: Color(0xFFE6E9EE),
  );

  @override
  DrivlyColors copyWith() => this;

  @override
  DrivlyColors lerp(DrivlyColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return DrivlyColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      outline: l(outline, other.outline),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      accent: l(accent, other.accent),
      accentGlow: l(accentGlow, other.accentGlow),
      onAccent: l(onAccent, other.onAccent),
      good: l(good, other.good),
      warn: l(warn, other.warn),
      danger: l(danger, other.danger),
      chartGrid: l(chartGrid, other.chartGrid),
    );
  }
}

/// Spacing, radius and touch sizes (8-pt grid, §3.4).
abstract final class Space {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const cardRadius = 20.0;
  static const buttonRadius = 16.0;
  static const touch = 56.0;
}

extension DrivlyThemeX on BuildContext {
  DrivlyColors get colors => Theme.of(this).extension<DrivlyColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
  bool get reduceMotion => MediaQuery.of(this).disableAnimations;
}

enum StatusTone { good, warn, danger, neutral, accent }

extension StatusToneX on StatusTone {
  Color color(DrivlyColors c) => switch (this) {
        StatusTone.good => c.good,
        StatusTone.warn => c.warn,
        StatusTone.danger => c.danger,
        StatusTone.neutral => c.textSecondary,
        StatusTone.accent => c.accent,
      };
}
