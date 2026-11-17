import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

const tabular = [FontFeature.tabularFigures()];

/// System fonts only (SF Pro / Roboto): nothing to bundle, nothing fetched at
/// runtime. Live numbers use tabular figures so digits don't jitter.
ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? DrivlyColors.dark : DrivlyColors.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: c.accent,
    brightness: brightness,
  ).copyWith(
    primary: c.accent,
    onPrimary: c.onAccent,
    surface: c.surface,
    onSurface: c.textPrimary,
    onSurfaceVariant: c.textSecondary,
    outline: c.outline,
    outlineVariant: c.outline,
    error: c.danger,
    surfaceContainerHighest: c.surfaceRaised,
    surfaceContainerHigh: c.surfaceRaised,
    surfaceContainer: c.surface,
    surfaceContainerLow: c.surface,
  );

  final base = ThemeData(useMaterial3: true, brightness: brightness, colorScheme: scheme);
  final t = base.textTheme.apply(bodyColor: c.textPrimary, displayColor: c.textPrimary);
  final text = t.copyWith(
    displayLarge: t.displayLarge?.copyWith(fontSize: 56, fontWeight: FontWeight.w600, letterSpacing: -1.5, height: 1, fontFeatures: tabular),
    displayMedium: t.displayMedium?.copyWith(fontSize: 40, fontWeight: FontWeight.w600, letterSpacing: -1, height: 1.05, fontFeatures: tabular),
    displaySmall: t.displaySmall?.copyWith(fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.6, height: 1.1, fontFeatures: tabular),
    headlineSmall: t.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4),
    titleLarge: t.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.2),
    titleMedium: t.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
    titleSmall: t.titleSmall?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
    bodyLarge: t.bodyLarge?.copyWith(fontSize: 16, height: 1.45),
    bodyMedium: t.bodyMedium?.copyWith(fontSize: 16, height: 1.4, color: c.textSecondary),
    bodySmall: t.bodySmall?.copyWith(fontSize: 13, color: c.textSecondary),
    labelLarge: t.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
    labelMedium: t.labelMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: c.textSecondary),
    labelSmall: t.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: c.textSecondary),
  );

  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Space.buttonRadius));
  return base.copyWith(
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    textTheme: text,
    extensions: [c],
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: c.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
      systemOverlayStyle: brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: c.accent.withValues(alpha: 0.16),
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: s.contains(WidgetState.selected) ? c.textPrimary : c.textSecondary,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? c.accent : c.textSecondary),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(Space.touch),
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        textStyle: text.labelLarge,
        shape: shape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(Space.touch),
        foregroundColor: c.textPrimary,
        side: BorderSide(color: c.outline),
        textStyle: text.labelLarge,
        shape: shape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: c.accent,
        textStyle: text.labelLarge,
        shape: shape,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surfaceRaised,
      selectedColor: c.accent.withValues(alpha: 0.18),
      side: BorderSide(color: c.outline),
      labelStyle: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
      shape: const StadiumBorder(),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: c.surface,
        selectedBackgroundColor: c.accent.withValues(alpha: 0.18),
        selectedForegroundColor: c.textPrimary,
        foregroundColor: c.textSecondary,
        side: BorderSide(color: c.outline),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: c.outline,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogThemeData(backgroundColor: c.surface, surfaceTintColor: Colors.transparent),
    dividerTheme: DividerThemeData(color: c.outline, thickness: 1, space: 1),
    listTileTheme: ListTileThemeData(
      iconColor: c.textSecondary,
      textColor: c.textPrimary,
      minTileHeight: Space.touch,
      contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: Space.l),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.onAccent : c.textSecondary),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.accent : c.surfaceRaised),
      trackOutlineColor: WidgetStateProperty.all(c.outline),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.surfaceRaised,
      contentTextStyle: TextStyle(color: c.textPrimary, fontSize: 15),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceRaised,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent),
  );
}
