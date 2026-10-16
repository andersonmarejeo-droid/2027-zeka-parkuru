import 'package:flutter/material.dart';

import '../theme/studio_visuals.dart';

/// Keeps tablet layouts editorially calm without narrowing phone layouts.
class StudioPageFrame extends StatelessWidget {
  const StudioPageFrame({required this.child, super.key, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? StudioVisuals.contentMaxWidth,
        ),
        child: child,
      ),
    );
  }
}

/// A shared, responsive surface for information and launch cards.
///
/// It keeps the app's menus visually related while leaving game-board cells
/// and interactive puzzle pieces in control of their own rendering.
class StudioCard extends StatelessWidget {
  const StudioCard({
    required this.child,
    super.key,
    this.onTap,
    this.semanticLabel,
    this.padding = StudioVisuals.cardPadding,
    this.minHeight = StudioVisuals.cardMinTapHeight,
    this.color = StudioVisuals.surface,
    this.borderRadius = StudioVisuals.cardRadius,
    this.elevated = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;
  final double minHeight;
  final Color color;
  final BorderRadius borderRadius;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final Widget surface = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Ink(
        padding: padding,
        decoration: StudioVisuals.cardDecoration(
          color: color,
          radius: borderRadius,
          elevated: elevated,
        ),
        child: child,
      ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: Semantics(
        button: onTap != null,
        label: semanticLabel,
        child: onTap == null
            ? surface
            : InkWell(onTap: onTap, borderRadius: borderRadius, child: surface),
      ),
    );
  }
}
