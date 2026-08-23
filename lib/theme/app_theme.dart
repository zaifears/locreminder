import 'package:flutter/material.dart';

/// The app's colour system: Material 3 tonal *surfaces*, but hand-pinned
/// *accents*.
///
/// `ColorScheme.fromSeed` is still what generates every neutral, because
/// getting light and dark surfaces to agree is exactly what it is good at.
/// What it is not good at is keeping a brand colour recognisable: it treats
/// the seed as a hue to harmonise, not a colour to reproduce, so
/// `#2563EB` came back as a muted slate blue and the accent on screen never
/// actually matched the launcher icon. The accent roles below are therefore
/// set from the icon's own palette, so the blue the user sees in their app
/// drawer is the blue they see inside the app.
class AppTheme {
  AppTheme._();

  // ------------------------------------------------------------ Signal Blue
  //
  // One hue, sampled from the launcher icon and stepped light to dark. Light
  // mode leans on the mid and pale steps, dark mode on the lighter ones —
  // #2563EB is too dense to carry text on a dark surface, so dark mode's
  // accent is the same blue two steps up rather than a different colour.

  static const _blue100 = Color(0xFFDBEAFE);
  static const _blue200 = Color(0xFFBFDBFE);
  static const _blue300 = Color(0xFF93C5FD);
  static const _blue400 = Color(0xFF60A5FA);
  static const _blue800 = Color(0xFF1E40AF);
  static const _blue900 = Color(0xFF1E3A8A);
  static const _blue950 = Color(0xFF172554);

  /// Signal Blue, straight off the launcher icon. The app's only accent.
  static const seed = Color(0xFF2563EB);

  // Quiet blue-grey for the informational callouts that must read as an aside
  // rather than an action. Material's generated tertiary lands in the pinks
  // for this seed, which is a second hue the design system does not want.
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate400 = Color(0xFF94A3B8);
  static const _slate600 = Color(0xFF475569);
  static const _slate700 = Color(0xFF334155);
  static const _slate800 = Color(0xFF1E293B);
  static const _slate900 = Color(0xFF0F172A);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  /// Replaces the generated accent roles with the icon's blue, leaving every
  /// surface, outline and error role exactly as `fromSeed` produced it.
  static ColorScheme _accented(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return scheme.copyWith(
      primary: isDark ? _blue400 : seed,
      onPrimary: isDark ? _blue950 : Colors.white,
      primaryContainer: isDark ? _blue800 : _blue200,
      onPrimaryContainer: isDark ? _blue100 : _blue900,
      secondary: isDark ? _blue300 : _blue800,
      onSecondary: isDark ? _blue950 : Colors.white,
      secondaryContainer: isDark ? _blue900 : _blue100,
      onSecondaryContainer: isDark ? _blue100 : _blue900,
      tertiary: isDark ? _slate400 : _slate600,
      onTertiary: isDark ? _slate900 : Colors.white,
      tertiaryContainer: isDark ? _slate700 : _slate200,
      onTertiaryContainer: isDark ? _slate200 : _slate800,
      surfaceTint: isDark ? _blue400 : seed,
    );
  }

  static ThemeData _build(Brightness brightness) {
    final scheme = _accented(
      ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        foregroundColor: scheme.onSurface,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          // An outlined button is the secondary action, but it is still an
          // action: tinting the label and icon keeps the accent doing the
          // "this is tappable" work instead of leaving a grey ghost button.
          // The edge stays neutral — Material resolves this to its disabled
          // colour on its own, and onboarding leans on that to show a
          // permission as already granted.
          foregroundColor: scheme.primary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.all(16),
      ),
      // Signal Blue with a white glyph, which is what makes "Add alarm" read
      // as the one primary action on the map. The two small utility buttons
      // above it deliberately invert that — see `_buildMapControls`.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      // On is Signal Blue carrying a white thumb; off is a neutral track with
      // an outline, so "off" reads as a switch at rest rather than as a
      // disabled control. These are Material 3's own roles, pinned rather
      // than inherited: this switch is what arms and disarms an alarm, and it
      // is the one control in the app whose colour is load-bearing, so it
      // should not be free to drift with a future Material default.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            if (states.contains(WidgetState.selected)) return scheme.surface;
            return scheme.onSurface.withValues(alpha: 0.38);
          }
          if (states.contains(WidgetState.selected)) return scheme.onPrimary;
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return scheme.outline;
        }),
      ),
      // The theme picker is the one segmented control in the app, and it is
      // itself a preview of the choice being made — so the selected segment
      // is the accent at full strength rather than a pale container.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return scheme.primary;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return scheme.onPrimary;
            return scheme.onSurfaceVariant;
          }),
          iconColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return scheme.onPrimary;
            return scheme.onSurfaceVariant;
          }),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
  }
}
