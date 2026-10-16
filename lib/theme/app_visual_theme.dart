import 'package:flutter/material.dart';

enum AppVisualTheme {
  studioGarden('studio_garden');

  const AppVisualTheme(this.storageValue);

  final String storageValue;

  static AppVisualTheme fromStorage(String? value) =>
      AppVisualTheme.studioGarden;
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

  static const ZpVisualPalette garden = ZpVisualPalette(
    background: Color(0xFFF6F8F6),
    surface: Color(0xFFFFFFFF),
    surfaceAlternative: Color(0xFFF0F5F2),
    primary: Color(0xFF238F81),
    secondary: Color(0xFFD69A43),
    onboardingBackground: Color(0xFFF6F8F6),
    onboardingSurface: Color(0xFFFFFFFF),
    onboardingAccent: Color(0xFF238F81),
    headerGradientEnd: Color(0xFFE5F4F1),
    homeHeaderGradientEnd: Color(0xFFEDF5F1),
    arenaGradientEnd: Color(0xFFC5E7DE),
    gamePanelGradientEnd: Color(0xFFE7F0EC),
  );

  static const ZpVisualPalette highContrast = ZpVisualPalette(
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

  static ZpVisualPalette forTheme(AppVisualTheme theme) => garden;

  static ZpVisualPalette of(BuildContext context) {
    return Theme.of(context).extension<ZpVisualPalette>() ?? garden;
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
