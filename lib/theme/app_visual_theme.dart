import 'package:flutter/material.dart';

enum AppVisualTheme {
  classicNeon('classic_neon'),
  pinkNeon('pink_neon');

  const AppVisualTheme(this.storageValue);

  final String storageValue;

  static AppVisualTheme fromStorage(String? value) {
    for (final AppVisualTheme theme in values) {
      if (theme.storageValue == value) return theme;
    }
    return AppVisualTheme.classicNeon;
  }
}

@immutable
class ZpVisualPalette extends ThemeExtension<ZpVisualPalette> {
  const ZpVisualPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlternative,
    required this.primary,
    required this.secondary,
    required this.onboardingBackground,
    required this.onboardingSurface,
    required this.onboardingAccent,
    required this.headerGradientEnd,
    required this.homeHeaderGradientEnd,
    required this.arenaGradientEnd,
    required this.gamePanelGradientEnd,
  });

  static const ZpVisualPalette classic = ZpVisualPalette(
    background: Color(0xFF07162E),
    surface: Color(0xFF10274B),
    surfaceAlternative: Color(0xFF0B1A31),
    primary: Color(0xFF6C4DFF),
    secondary: Color(0xFF00D9FF),
    onboardingBackground: Color(0xFF000322),
    onboardingSurface: Color(0xFF0D1941),
    onboardingAccent: Color(0xFFFF7200),
    headerGradientEnd: Color(0xFF34236F),
    homeHeaderGradientEnd: Color(0xFF172F61),
    arenaGradientEnd: Color(0xFF008DB2),
    gamePanelGradientEnd: Color(0xFF0D3353),
  );

  static const ZpVisualPalette pink = ZpVisualPalette(
    background: Color(0xFF250C22),
    surface: Color(0xFF431A3A),
    surfaceAlternative: Color(0xFF32132D),
    primary: Color(0xFFFF4FA3),
    secondary: Color(0xFFFF91C8),
    onboardingBackground: Color(0xFF1B0619),
    onboardingSurface: Color(0xFF35102F),
    onboardingAccent: Color(0xFFFF4FA3),
    headerGradientEnd: Color(0xFF6B1D53),
    homeHeaderGradientEnd: Color(0xFF641B55),
    arenaGradientEnd: Color(0xFFC92C79),
    gamePanelGradientEnd: Color(0xFF5C1B48),
  );

  static ZpVisualPalette forTheme(AppVisualTheme theme) {
    return switch (theme) {
      AppVisualTheme.classicNeon => classic,
      AppVisualTheme.pinkNeon => pink,
    };
  }

  static ZpVisualPalette of(BuildContext context) {
    return Theme.of(context).extension<ZpVisualPalette>() ?? classic;
  }

  final Color background;
  final Color surface;
  final Color surfaceAlternative;
  final Color primary;
  final Color secondary;
  final Color onboardingBackground;
  final Color onboardingSurface;
  final Color onboardingAccent;
  final Color headerGradientEnd;
  final Color homeHeaderGradientEnd;
  final Color arenaGradientEnd;
  final Color gamePanelGradientEnd;

  @override
  ZpVisualPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlternative,
    Color? primary,
    Color? secondary,
    Color? onboardingBackground,
    Color? onboardingSurface,
    Color? onboardingAccent,
    Color? headerGradientEnd,
    Color? homeHeaderGradientEnd,
    Color? arenaGradientEnd,
    Color? gamePanelGradientEnd,
  }) {
    return ZpVisualPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlternative: surfaceAlternative ?? this.surfaceAlternative,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      onboardingBackground: onboardingBackground ?? this.onboardingBackground,
      onboardingSurface: onboardingSurface ?? this.onboardingSurface,
      onboardingAccent: onboardingAccent ?? this.onboardingAccent,
      headerGradientEnd: headerGradientEnd ?? this.headerGradientEnd,
      homeHeaderGradientEnd:
          homeHeaderGradientEnd ?? this.homeHeaderGradientEnd,
      arenaGradientEnd: arenaGradientEnd ?? this.arenaGradientEnd,
      gamePanelGradientEnd: gamePanelGradientEnd ?? this.gamePanelGradientEnd,
    );
  }

  @override
  ZpVisualPalette lerp(covariant ZpVisualPalette? other, double t) {
    if (other == null) return this;
    return ZpVisualPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlternative: Color.lerp(
        surfaceAlternative,
        other.surfaceAlternative,
        t,
      )!,
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onboardingBackground: Color.lerp(
        onboardingBackground,
        other.onboardingBackground,
        t,
      )!,
      onboardingSurface: Color.lerp(
        onboardingSurface,
        other.onboardingSurface,
        t,
      )!,
      onboardingAccent: Color.lerp(
        onboardingAccent,
        other.onboardingAccent,
        t,
      )!,
      headerGradientEnd: Color.lerp(
        headerGradientEnd,
        other.headerGradientEnd,
        t,
      )!,
      homeHeaderGradientEnd: Color.lerp(
        homeHeaderGradientEnd,
        other.homeHeaderGradientEnd,
        t,
      )!,
      arenaGradientEnd: Color.lerp(
        arenaGradientEnd,
        other.arenaGradientEnd,
        t,
      )!,
      gamePanelGradientEnd: Color.lerp(
        gamePanelGradientEnd,
        other.gamePanelGradientEnd,
        t,
      )!,
    );
  }
}
