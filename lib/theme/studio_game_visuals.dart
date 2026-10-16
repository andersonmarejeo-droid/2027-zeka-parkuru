import 'package:flutter/material.dart';

import 'studio_visuals.dart';

/// Visual rules that belong to game catalog and gameplay surfaces only.
///
/// The launcher intentionally keeps its existing studio cards. These tokens
/// give sub-category lists and game routes a shared, more dimensional visual
/// language without changing puzzle rules, content, or the home screen.
abstract final class StudioGameVisuals {
  static Color cardSurface(Color accent) =>
      Color.lerp(StudioVisuals.surface, accent, .025)!;

  static Color artworkSurface(Color accent) =>
      Color.lerp(StudioVisuals.surfaceSoft, accent, .18)!;

  static BoxDecoration cardDecoration({
    required Color accent,
    bool disabled = false,
    BorderRadius? radius,
  }) {
    final Color visibleAccent = disabled
        ? StudioVisuals.muted
        : accent;
    return BoxDecoration(
      color: disabled
          ? StudioVisuals.surfaceSoft.withValues(alpha: .72)
          : cardSurface(accent),
      borderRadius: radius ?? StudioVisuals.cardRadius,
      border: Border.all(color: StudioVisuals.line.withValues(alpha: .82)),
      boxShadow: disabled
          ? const <BoxShadow>[]
          : <BoxShadow>[
              BoxShadow(
                color: visibleAccent.withValues(alpha: .08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              const BoxShadow(
                color: Color(0x0D0B1A2B),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
    );
  }

  static BoxDecoration artworkDecoration({
    required Color accent,
    bool disabled = false,
  }) {
    final Color tint = disabled ? StudioVisuals.muted : accent;
    final Color deep = Color.lerp(tint, const Color(0xFF0E1B22), .66)!;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: disabled
            ? <Color>[artworkSurface(tint), StudioVisuals.surfaceSoft]
            : <Color>[Color.lerp(tint, Colors.white, .10)!, deep],
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: disabled
          ? const <BoxShadow>[]
          : <BoxShadow>[
              BoxShadow(
                color: tint.withValues(alpha: .16),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }
}

/// A game-only card surface. Keeping this separate from [StudioCard] prevents
/// the launcher/home page from inheriting gameplay catalogue styling changes.
class StudioGameCard extends StatelessWidget {
  const StudioGameCard({
    required this.child,
    required this.accent,
    super.key,
    this.onTap,
    this.semanticLabel,
    this.padding = const EdgeInsets.all(10),
    this.minHeight = 112,
    this.disabled = false,
    this.borderRadius = StudioVisuals.cardRadius,
  });

  final Widget child;
  final Color accent;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;
  final double minHeight;
  final bool disabled;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final Widget surface = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Ink(
        padding: padding,
        decoration: StudioGameVisuals.cardDecoration(
          accent: accent,
          disabled: disabled,
          radius: borderRadius,
        ),
        child: child,
      ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: onTap != null,
        enabled: !disabled,
        label: semanticLabel,
        child: onTap == null
            ? surface
            : InkWell(onTap: onTap, borderRadius: borderRadius, child: surface),
      ),
    );
  }
}
