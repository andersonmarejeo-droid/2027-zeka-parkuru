import 'package:flutter/material.dart';

/// The shared light launcher language for the renewed Zekâ Parkuru catalog.
/// Gameplay can keep its own high-contrast board colors; menus use these
/// deliberately restrained studio tokens.
abstract final class StudioVisuals {
  static const Color canvas = Color(0xFFF6F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFEEF3F0);
  static const Color line = Color(0xFFD7E1DC);
  static const Color ink = Color(0xFF1E2B3C);
  static const Color muted = Color(0xFF586C73);
  static const Color teal = Color(0xFF238F81);
  static const Color tealSoft = Color(0xFFE5F4F1);
  static const Color amber = Color(0xFFD69A43);
  static const Color amberSoft = Color(0xFFFFF4DF);
  static const Color danger = Color(0xFFD96767);
  static const Color tealInk = Color(0xFF176D62);
  static const Color amberInk = Color(0xFF8B622C);
  static const Color dangerInk = Color(0xFFA84640);
  static const Color paper = Color(0xFFFAF8F2);
  static const Color wood = Color(0xFFAD784E);
  static const Color woodLight = Color(0xFFDCC09A);

  /// Shared layout rhythm for launcher, catalog, social, and utility screens.
  /// Gameplay boards may still use their own purpose-built geometry.
  static const double pageGutter = 20;
  static const double contentMaxWidth = 760;
  static const double cardGap = 12;
  static const double sectionGap = 22;
  static const double cardMinTapHeight = 96;
  static const EdgeInsets cardPadding = EdgeInsets.all(18);
  static const EdgeInsets compactCardPadding = EdgeInsets.all(14);

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(22));
  static const BorderRadius compactRadius = BorderRadius.all(
    Radius.circular(18),
  );

  static List<BoxShadow> get softShadow => const <BoxShadow>[
    BoxShadow(color: Color(0x100B1A2B), blurRadius: 24, offset: Offset(0, 7)),
  ];

  static BoxDecoration cardDecoration({
    Color? color,
    BorderRadius? radius,
    bool elevated = true,
  }) => BoxDecoration(
    color: color ?? surface,
    borderRadius: radius ?? cardRadius,
    border: Border.all(color: line),
    boxShadow: elevated ? softShadow : const <BoxShadow>[],
  );
}
