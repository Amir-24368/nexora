import 'package:flutter/material.dart';

/// ThemeMode notifier shared app-wide (set once, every screen rebuilds).
final ValueNotifier<ThemeMode> nxThemeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

/// In-app label for the current mode (used by dashboards' toggle buttons).
String nxThemeLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'Light';
    case ThemeMode.dark:
      return 'Dark';
    case ThemeMode.system:
      return 'System';
  }
}

ThemeMode nxNextTheme(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return ThemeMode.dark;
    case ThemeMode.dark:
      return ThemeMode.system;
    case ThemeMode.system:
      return ThemeMode.light;
  }
}

/// ── Nexora design tokens ──────────────────────────────────────────────────
///
/// Every visual decision (color, radius, spacing, shadow) lives here so the
/// whole app changes look in one file. `nxOf(context)` returns the palette
/// for the current brightness.
class NxTheme {
  const NxTheme({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.textOnAccent,
    required this.primary,
    required this.primarySoft,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.shadowColor,
  });

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color textOnAccent;
  final Color primary;
  final Color primarySoft;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color shadowColor;

  static const NxTheme light = NxTheme(
    brightness: Brightness.light,
    background: Color(0xFFF4F6FB),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF1F3F9),
    border: Color(0xFFE4E7EF),
    textPrimary: Color(0xFF171C2E),
    textMuted: Color(0xFF68718A),
    textOnAccent: Color(0xFFFFFFFF),
    primary: Color(0xFF4F5DFF),
    primarySoft: Color(0xFFEDEFFF),
    success: Color(0xFF0EAF7B),
    warning: Color(0xFFE8A13B),
    danger: Color(0xFFE5484D),
    info: Color(0xFF3B9DDB),
    shadowColor: Color(0x14222B45),
  );

  static const NxTheme dark = NxTheme(
    brightness: Brightness.dark,
    background: Color(0xFF0B0E17),
    surface: Color(0xFF141829),
    surfaceAlt: Color(0xFF1C2137),
    border: Color(0xFF272E4A),
    textPrimary: Color(0xFFEEF1FA),
    textMuted: Color(0xFF8C95B2),
    textOnAccent: Color(0xFFFFFFFF),
    primary: Color(0xFF8193FF),
    primarySoft: Color(0xFF23284F),
    success: Color(0xFF3DDC97),
    warning: Color(0xFFF5BE5C),
    danger: Color(0xFFFF6B70),
    info: Color(0xFF6BC1F2),
    shadowColor: Color(0x6602050B),
  );

  /// Palette for [context]'s current brightness.
  static NxTheme of(BuildContext context) {
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return dark ? NxTheme.dark : NxTheme.light;
  }

  bool get isDark => brightness == Brightness.dark;
}

/// Brand gradient used for hero headers and the primary button.
const List<Color> nxHeroGradient = [Color(0xFF4F46E5), Color(0xFF7C3AED)];

/// Resolve the [NxTheme] matching the resolved effective theme (NOT the
/// platform one) — safe inside Material widgets that already know their
/// parent ThemeData brightness.
NxTheme nxOf(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return dark ? NxTheme.dark : NxTheme.light;
}
