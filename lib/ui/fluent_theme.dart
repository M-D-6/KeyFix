import 'package:flutter/material.dart';

const String appFontFamily = 'Vazirmatn';

@immutable
class FluentColors {
  const FluentColors({
    required this.isDark,
    required this.background,
    required this.card,
    required this.raised,
    required this.raisedHover,
    required this.stroke,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.onAccentSoft,
    required this.scheme,
  });

  final bool isDark;
  final Color background;
  final Color card;
  final Color raised;
  final Color raisedHover;
  final Color stroke;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color onAccentSoft;
  final ColorScheme scheme;

  static FluentColors of({required bool dark, required Color accent}) {
    final Brightness brightness = dark ? Brightness.dark : Brightness.light;
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    );

    final Color neutralBackground =
        dark ? const Color(0xFF151718) : const Color(0xFFF3F4F5);
    final Color neutralCard =
        dark ? const Color(0xFF1F2224) : const Color(0xFFFFFFFF);
    final Color neutralRaised =
        dark ? const Color(0xFF2A2E31) : const Color(0xFFECEEEF);
    final Color neutralRaisedHover =
        dark ? const Color(0xFF33383B) : const Color(0xFFE3E6E8);

    return FluentColors(
      isDark: dark,
      background: Color.lerp(neutralBackground, accent, dark ? 0.025 : 0.018)!,
      card: Color.lerp(neutralCard, accent, dark ? 0.04 : 0.0)!,
      raised: Color.lerp(neutralRaised, accent, dark ? 0.055 : 0.03)!,
      raisedHover:
          Color.lerp(neutralRaisedHover, accent, dark ? 0.07 : 0.04)!,
      stroke: dark ? const Color(0x14FFFFFF) : const Color(0x14000000),
      textPrimary: dark ? const Color(0xFFF1F3F4) : const Color(0xFF1B1D1F),
      textSecondary: dark ? const Color(0xFFA9AFB3) : const Color(0xFF5E6569),
      accent: scheme.primary,
      onAccent: scheme.onPrimary,
      accentSoft: scheme.primaryContainer,
      onAccentSoft: scheme.onPrimaryContainer,
      scheme: scheme,
    );
  }
}

class FluentTheme extends InheritedWidget {
  const FluentTheme({super.key, required this.colors, required super.child});

  final FluentColors colors;

  static FluentColors of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FluentTheme>()!.colors;
  }

  @override
  bool updateShouldNotify(FluentTheme oldWidget) => colors != oldWidget.colors;
}

ThemeData buildMaterialTheme(FluentColors c) {
  return ThemeData(
    useMaterial3: true,
    brightness: c.isDark ? Brightness.dark : Brightness.light,
    colorScheme: c.scheme.copyWith(
      surface: c.card,
      surfaceTint: Colors.transparent,
    ),
    fontFamily: appFontFamily,
    fontFamilyFallback: const <String>[
      'Segoe UI',
      'SF Pro Text',
      'Roboto',
      'Noto Sans',
      'Tahoma',
    ],
    scaffoldBackgroundColor: c.background,
    canvasColor: c.background,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
  );
}
